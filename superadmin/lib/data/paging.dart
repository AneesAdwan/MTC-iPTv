// Server-side paging contract (plan §6 2.1: paging and filtering on the server; nothing large is
// downloaded). Every table in the program reads through a PagedDataSource.
import 'package:flutter/foundation.dart';

@immutable
class PageRequest {
  final int offset, limit;
  final String query;
  final Map<String, String> filters;
  final String? sort;
  final bool descending;
  const PageRequest({this.offset = 0, this.limit = 50, this.query = '', this.filters = const {}, this.sort, this.descending = false});

  PageRequest copyWith({int? offset, int? limit, String? query, Map<String, String>? filters, String? sort, bool? descending}) => PageRequest(
    offset: offset ?? this.offset,
    limit: limit ?? this.limit,
    query: query ?? this.query,
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
    descending: descending ?? this.descending,
  );

  /// Same filter (ignores paging): selections and "all matching" are tied to this.
  bool sameFilter(PageRequest o) => o.query == query && mapEquals(o.filters, filters);

  @override
  bool operator ==(Object other) =>
      other is PageRequest && other.offset == offset && other.limit == limit && sameFilter(other) && other.sort == sort && other.descending == descending;
  @override
  int get hashCode => Object.hash(offset, limit, query, Object.hashAllUnordered(filters.entries.map((e) => '${e.key}=${e.value}')), sort, descending);
}

@immutable
class PageResult<T> {
  final List<T> items;

  /// Total rows matching the filter on the server (not just this page).
  final int total;
  const PageResult(this.items, this.total);
}

abstract class PagedDataSource<T> {
  Future<PageResult<T>> fetch(PageRequest request);
  String idOf(T row);
}

/// In-memory implementation for stubs and tests. Filtering/sorting mimic what the server will do.
class ListDataSource<T> extends PagedDataSource<T> {
  final List<T> Function() rows;
  final String Function(T) id;
  final bool Function(T row, String query)? matches;
  final bool Function(T row, String key, String value)? filter;
  final Comparable<Object?> Function(T row, String sortKey)? sortValue;
  final Duration latency;

  ListDataSource({required this.rows, required this.id, this.matches, this.filter, this.sortValue, this.latency = const Duration(milliseconds: 120)});

  @override
  String idOf(T row) => id(row);

  @override
  Future<PageResult<T>> fetch(PageRequest r) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    var list = rows();
    if (r.query.trim().isNotEmpty && matches != null) list = list.where((x) => matches!(x, r.query.trim())).toList();
    if (filter != null) {
      for (final e in r.filters.entries) {
        if (e.value.isEmpty) continue;
        list = list.where((x) => filter!(x, e.key, e.value)).toList();
      }
    }
    if (r.sort != null && sortValue != null) {
      list = [...list]
        ..sort((a, b) {
          final c = sortValue!(a, r.sort!).compareTo(sortValue!(b, r.sort!));
          return r.descending ? -c : c;
        });
    }
    final start = r.offset.clamp(0, list.length);
    final end = (r.offset + r.limit).clamp(0, list.length);
    return PageResult(list.sublist(start, end), list.length);
  }
}
