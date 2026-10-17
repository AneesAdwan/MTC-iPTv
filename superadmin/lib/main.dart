// MTC-iPTv SuperAdmin — the admin program (Windows only). Plan: mtc_iptv/docs/plans/admin-rebuild-2026-10.md
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';

import 'app/app.dart';
import 'auth/admin_auth.dart';
import 'auth/auth_controller.dart';
import 'core/env.dart';
import 'core/prefs.dart';
import 'data/providers.dart';
import 'data/rpc/admin_rpc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Pure-Dart client: the session lives in memory only (no token on disk); auto-refresh keeps it
  // alive while the program runs. Closing the program = signing out.
  final client = Env.hasBackend ? SupabaseClient(Env.supabaseUrl, Env.supabaseAnonKey, authOptions: const AuthClientOptions(autoRefreshToken: true)) : null;
  final gateway = client == null ? NoBackendGateway() : SupabaseAdminAuthGateway(client);
  final auth = AuthController(gateway, heartbeat: const Duration(minutes: 1));
  unawaited(auth.start());

  final AdminRpc rpc = (client != null && Env.serverFunctionsReady) ? SupabaseAdminRpc(client, onAuthRejected: auth.reportAuthRejection) : StubAdminRpc();

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(PrefsController(FilePrefsStore.standard())),
        authControllerProvider.overrideWithValue(auth),
        adminRpcProvider.overrideWithValue(rpc),
      ],
      child: const SuperAdminApp(),
    ),
  );
}
