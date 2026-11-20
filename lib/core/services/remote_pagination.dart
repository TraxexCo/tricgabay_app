/// Fetch only the requested window; metadata, rather than decoded row count,
/// decides whether another page exists.
Future<({List<T> items, bool hasMore})> readPageWindow<T>({
  required int throughPage,
  required Future<({List<T> items, bool hasMore})> Function(int) fetch,
}) async {
  final items = <T>[];
  var hasMore = false;
  for (var page = 0; page <= (throughPage < 0 ? 0 : throughPage); page++) {
    final result = await fetch(page);
    items.addAll(result.items);
    hasMore = result.hasMore;
    if (!hasMore) break;
  }
  return (items: items, hasMore: hasMore);
}
