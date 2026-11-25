import 'package:flutter/foundation.dart';

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

/// Reads one row so that a row that cannot be read does not discard the others.
///
/// A skipped row is easy to miss: it simply is not in the list. In debug builds
/// the skip is printed with [rowName] (say, `booking <id>`) and the error, so a
/// row that goes missing can be traced to its cause. [onFailure] still receives
/// every failure in every build.
Future<bool> readRowIndependently(
  Future<void> Function() read,
  void Function(Object, StackTrace) onFailure, {
  String? rowName,
}) async {
  try {
    await read();
    return true;
  } catch (error, stack) {
    if (kDebugMode) {
      final frames = stack.toString().split('\n').take(6).join('\n');
      debugPrint(
        'readRowIndependently skipped ${rowName ?? 'a row'}: '
        '${error.runtimeType}: $error\n$frames',
      );
    }
    onFailure(error, stack);
    return false;
  }
}
