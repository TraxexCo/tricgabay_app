/// A section failure preserves its previous value without discarding successful reads.
Future<T> refreshSection<T>(
  Future<T> Function() load,
  T previous,
  void Function(Object, StackTrace) onFailure,
) async {
  try {
    return await load();
  } catch (error, stack) {
    onFailure(error, stack);
    return previous;
  }
}

Future<bool> readRowIndependently(
  Future<void> Function() read,
  void Function(Object, StackTrace) onFailure,
) async {
  try {
    await read();
    return true;
  } catch (error, stack) {
    onFailure(error, stack);
    return false;
  }
}
