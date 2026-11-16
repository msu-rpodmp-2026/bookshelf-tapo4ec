import 'book.dart';
import 'library_item.dart';

class Library<T extends LibraryItem> {
  final List<T> _items = [];

  // List.from, чтобы можно было делать копии и сортировать без ошибок
  List<T> get items => List<T>.from(_items);
  int get count => _items.length;

  void add(T item) {
    if (_items.contains(item)) return;
    _items.add(item);
  }

  bool remove(T item) => _items.remove(item);

  T? findByTitle(String title) {
    final needle = title.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final it in _items) {
      if (it.title.trim().toLowerCase() == needle) return it;
    }
    for (final it in _items) {
      if (it.title.toLowerCase().contains(needle)) return it;
    }
    return null;
  }

  Iterable<T> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const Iterable.empty();
    return _items.where((it) {
      if (it is Book) return it.matches(q);
      return it.title.toLowerCase().contains(q);
    });
  }

  Iterable<T> where(bool Function(T) test) => _items.where(test);

  // ВОЗВРАЩЕННЫЙ МЕТОД ИЗ ЗАДАНИЯ 7
  Map<String, int> countByGenre() {
    final res = <String, int>{};
    for (final it in _items) {
      if (it is Book) {
        for (final g in it.genres) {
          res[g] = (res[g] ?? 0) + 1;
        }
      }
    }
    return res;
  }
}
