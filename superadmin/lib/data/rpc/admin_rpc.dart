// The ONLY way SuperAdmin changes data: one server function per operation (plan §4 rule 4, §9).
//
//   admin_<name>(p_… params, p_reason text, p_preview boolean)
//     → { done int, failed int, conflicts int, failures [{item, reason}], undo_token text|null, preview {...}|null }
//
// The server checks (admin + aal2 + live, non-revoked session + recent TOTP for dangerous ops), runs all
// or nothing, writes the audit log (who + why) and returns the result. RLS rejects direct table writes,
// and this program contains none (enforced by test/no_direct_writes_test.dart).
import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';

import '../../auth/admin_auth.dart';
import '../../core/errors.dart';
import '../../core/tr.dart';

/// How an operation can be reversed (plan §9.4). Shown in every preview dialog.
enum UndoClass {
  /// أ. Full undo: the server stores "before" for every row; `admin_undo` restores it (row_version checked).
  full,

  /// ب. Snapshot restore: snapshot of the affected rows before running; restore goes through conflict checks.
  snapshot,

  /// ج. Compensating action: no time travel; a clear inverse operation is recorded as a new operation.
  compensating,

  /// د. Irreversible: confirmation before running (typed + recent TOTP for the dangerous ones). No undo button.
  irreversible,
}

/// One server function, as the program knows it.
@immutable
class RpcSpec {
  final String name;
  final UndoClass undoClass;

  /// Needs a TOTP verification younger than 15 minutes (plan §9.1).
  final bool needsRecentMfa;
  final Tr purpose;
  const RpcSpec(this.name, this.undoClass, this.purpose, {this.needsRecentMfa = false});
}

@immutable
class OpFailure {
  final String item;
  final String reason;
  const OpFailure(this.item, this.reason);
}

/// Result of a write, rendered by the result bar ("done n · failed m (details) · undo").
@immutable
class OpResult {
  final String rpc;
  final int done, failed, conflicts;
  final List<OpFailure> failures;
  final String? undoToken;
  final UndoClass undoClass;

  /// True when the server function does not exist yet (Phase 2) and nothing was executed.
  final bool stub;
  const OpResult({
    required this.rpc,
    required this.undoClass,
    this.done = 0,
    this.failed = 0,
    this.conflicts = 0,
    this.failures = const [],
    this.undoToken,
    this.stub = false,
  });

  bool get canUndo => undoToken != null && (undoClass == UndoClass.full || undoClass == UndoClass.snapshot);

  factory OpResult.fromJson(RpcSpec spec, Object? json) {
    final m = json is Map ? json : const {};
    int i(Object? v) => v is num ? v.toInt() : 0;
    return OpResult(
      rpc: spec.name,
      undoClass: spec.undoClass,
      done: i(m['done']),
      failed: i(m['failed']),
      conflicts: i(m['conflicts']),
      failures: [
        for (final f in (m['failures'] is List ? m['failures'] as List : const []))
          if (f is Map) OpFailure('${f['item'] ?? ''}', '${f['reason'] ?? ''}'),
      ],
      undoToken: m['undo_token'] as String?,
    );
  }
}

abstract interface class AdminRpc {
  /// Executes [spec] on the server. [affected] is the number of items the caller expects to touch
  /// (used for honest reporting by the stub).
  Future<OpResult> call(RpcSpec spec, Map<String, Object?> params, {required String reason, int affected = 1});

  /// Same function with p_preview = true: nothing is written; returns the server's preview payload.
  Future<Map<String, Object?>> preview(RpcSpec spec, Map<String, Object?> params);
}

/// Real implementation (enabled once Phase 2 ships the functions: --dart-define=MTC_SERVER_FUNCTIONS=true).
class SupabaseAdminRpc implements AdminRpc {
  final SupabaseClient client;
  final VoidCallback onAuthRejected;
  SupabaseAdminRpc(this.client, {required this.onAuthRejected});

  @override
  Future<OpResult> call(RpcSpec spec, Map<String, Object?> params, {required String reason, int affected = 1}) async {
    try {
      final r = await client.rpc<Object?>(spec.name, params: {...params, 'p_reason': reason, 'p_preview': false});
      return OpResult.fromJson(spec, r);
    } catch (e, st) {
      if (isAuthRejection(e)) onAuthRejected();
      final err = describeError(e, st);
      return OpResult(rpc: spec.name, undoClass: spec.undoClass, failed: affected, failures: [OpFailure('*', '${err.message.ar}\n${err.details}')]);
    }
  }

  @override
  Future<Map<String, Object?>> preview(RpcSpec spec, Map<String, Object?> params) async {
    try {
      final r = await client.rpc<Object?>(spec.name, params: {...params, 'p_reason': '', 'p_preview': true});
      final m = r is Map ? r['preview'] : null;
      return m is Map<String, Object?> ? m : const {};
    } catch (e) {
      if (isAuthRejection(e)) onAuthRejected();
      rethrow;
    }
  }
}

/// Until Phase 2: records the intended call and executes NOTHING. The result says so plainly, so a
/// stubbed write can never look like a success (no silent failure).
class StubAdminRpc implements AdminRpc {
  final List<({RpcSpec spec, Map<String, Object?> params, String reason})> calls = [];

  @override
  Future<OpResult> call(RpcSpec spec, Map<String, Object?> params, {required String reason, int affected = 1}) async {
    calls.add((spec: spec, params: params, reason: reason));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return OpResult(
      rpc: spec.name,
      undoClass: spec.undoClass,
      failed: affected,
      stub: true,
      failures: [OpFailure('*', 'الدالة ${spec.name} لسا ما انبنت على الخادم (المرحلة 2). ما تنفّذ شي.')],
    );
  }

  @override
  Future<Map<String, Object?>> preview(RpcSpec spec, Map<String, Object?> params) async => const {};
}
