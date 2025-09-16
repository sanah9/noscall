extension ListEx<T> on List<T> {
  /// Inserts an element into the list at every N-th position.
  ///
  /// This method takes an integer `n` and an element `element`, and inserts `element`
  /// into the list at every N-th position. Note that this method does not insert
  /// the element after the last element of the list.
  ///
  /// ```dart
  /// List<int> originalList = [1, 2, 3, 4, 5, 6];
  /// List<int> modifiedList = originalList.insertEveryN(2, 99);
  /// // modifiedList: [1, 2, 99, 3, 4, 99, 5, 6]
  /// ```
  ///
  /// Parameters:
  /// - [n]: An integer representing the interval at which to insert [element].
  /// - [element]: The element to be inserted.
  ///
  /// Returns:
  /// - A new list with the elements inserted at every N-th position.
  List<T> insertEveryN(int n, T element) {
    List<T> result = [];
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
      if ((i + 1) % n == 0 && i != length - 1) {
        result.add(element);
      }
    }
    return result;
  }

  List<List<T>> toChunks(int size) {
    final arr = [...this];
    List<List<T>> chunks = [];
    for (int i = 0; i < arr.length; i += size) {
      int end = i + size < arr.length ? i + size : arr.length;
      chunks.add(arr.sublist(i, end));
    }
    return chunks;
  }

  Map<Key, List<T>> groupBy<Key>(Key Function(T item) keyBuilder) {
    return fold(<Key, List<T>>{}, (map, element) {
      final key = keyBuilder(element);
      map.putIfAbsent(key, () => []).add(element);
      return map;
    });
  }
}