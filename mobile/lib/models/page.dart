/// Mirrors the backend's generic `Page` schema (see app/schemas/common.py).
class Page<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  Page({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < total;

  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) => Page(
    items: (json['items'] as List)
        .map((e) => itemParser(e as Map<String, dynamic>))
        .toList(),
    total: json['total'] as int,
    page: json['page'] as int,
    pageSize: json['page_size'] as int,
  );
}
