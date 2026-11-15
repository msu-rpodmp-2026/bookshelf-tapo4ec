import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

// ============================================================
// ЗАДАНИЕ 1. Расширенное перечисление
// ============================================================
enum ReadingStatus {
  planned('Запланирована', 0),
  reading('Читаю', 1),
  finished('Прочитана', 2),
  abandoned('Брошена', 3);

  final String label;
  final int order;

  const ReadingStatus(this.label, this.order);

  bool get isDone => this == ReadingStatus.finished;

  static ReadingStatus fromName(String name) => values.firstWhere(
        (s) => s.name == name,
        orElse: () => planned,
      );
}

// ============================================================
// ЗАДАНИЕ 4. Интерфейсы
// ============================================================
abstract interface class Searchable {
  bool matches(String query);
}

abstract interface class Exportable {
  Map<String, dynamic> toJson();
}

// ============================================================
// ЗАДАНИЕ 2. Абстрактный базовый класс
// ============================================================
abstract class LibraryItem {
  String get title;

  String describe();

  void printCard() {
    print('--- Карточка ---');
    print(describe());
    print('----------------');
  }
}

// ============================================================
// ЗАДАНИЕ 5. Миксины
// ============================================================
mixin Rateable {
  double _sum = 0;
  int _votes = 0;

  double get averageRating => _votes == 0 ? 0 : _sum / _votes;
  int get votesCount => _votes;

  void vote(double value) {
    if (value < 0 || value > 5) {
      throw ArgumentError('Оценка должна быть в диапазоне 0..5');
    }
    _sum += value;
    _votes++;
  }
}

mixin Loggable {
  void log(String message) {
    final ts = DateTime.now().toIso8601String();
    print('[$ts] $message');
  }
}

mixin Borrowable on LibraryItem {
  DateTime? _dueDate;

  bool get isBorrowed => _dueDate != null;
  DateTime? get dueDate => _dueDate;

  void borrow(int days) {
    _dueDate = DateTime.now().add(Duration(days: days));
    print('«$title» выдана до ${_dueDate!.toIso8601String().substring(0, 10)}');
  }

  void giveBack() {
    if (!isBorrowed) {
      print('«$title» не была выдана.');
      return;
    }
    _dueDate = null;
    print('«$title» возвращена.');
  }
}

// ============================================================
// ЗАДАНИЯ 2, 4, 6. Класс Book
// ============================================================
class Book extends LibraryItem
    implements Searchable, Exportable, Comparable<Book> {
  @override
  final String title;
  final String author;
  final int year;
  final int pages;
  final Set<String> genres;
  final ReadingStatus status;
  double? _rating;

  Book({
    required this.title,
    required this.author,
    this.year = 0,
    this.pages = 0,
    Set<String>? genres,
    this.status = ReadingStatus.planned,
    double? rating,
  })  : genres = genres ?? <String>{},
        _rating = rating {
    if (rating != null) _checkRating(rating);
  }

  String get shortTitle =>
      title.length <= 20 ? title : '${title.substring(0, 20)}…';

  double get readingHours => pages / 50;

  int get age {
    if (year == 0) return 0;
    return DateTime.now().year - year;
  }

  bool get isRated => _rating != null;

  double? get rating => _rating;

  set rating(double? value) {
    if (value != null) _checkRating(value);
    _rating = value;
  }

  void _checkRating(double v) {
    if (v < 0 || v > 5) {
      throw ArgumentError.value(v, 'rating', 'Допустимо 0..5');
    }
  }

  @override
  String describe() =>
      '«$title» — $author, $year г., $pages с., статус: ${status.label}';

  @override
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    return title.toLowerCase().contains(q) ||
        author.toLowerCase().contains(q) ||
        genres.any((g) => g.toLowerCase().contains(q));
  }

  @override
  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'year': year,
        'pages': pages,
        'genres': genres.toList(),
        'status': status.name,
        if (_rating != null) 'rating': _rating,
      };

  @override
  String toString() => 'Book($title, $author, $year)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          other.title == title &&
          other.author == author &&
          other.year == year;

  @override
  int get hashCode => Object.hash(title, author, year);

  @override
  int compareTo(Book other) =>
      title.toLowerCase().compareTo(other.title.toLowerCase());

  Book copyWith({
    String? title,
    String? author,
    int? year,
    int? pages,
    Set<String>? genres,
    ReadingStatus? status,
    double? rating,
  }) {
    return Book(
      title: title ?? this.title,
      author: author ?? this.author,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      genres: genres ?? this.genres,
      status: status ?? this.status,
      rating: rating ?? _rating,
    );
  }
}

// ============================================================
// ЗАДАНИЕ 3. Иерархия наследников
// ============================================================
class PaperBook extends Book with Rateable, Loggable, Borrowable {
  final String shelf;

  PaperBook({
    required super.title,
    required super.author,
    this.shelf = 'A-1',
    super.year,
    super.pages,
    super.genres,
    super.status,
    super.rating,
  });

  @override
  String describe() => '«$title» — бумажная книга, полка $shelf, '
      '${isBorrowed ? "выдана" : "на месте"}';
}

class EBook extends Book {
  final String format;
  final double sizeMb;

  EBook({
    required super.title,
    required super.author,
    this.format = 'epub',
    this.sizeMb = 0,
    super.year,
    super.pages,
    super.genres,
    super.status,
    super.rating,
  });

  @override
  String describe() => '«$title» — электронная книга ($format, '
      '${sizeMb.toStringAsFixed(1)} МБ)';
}

class AudioBook extends Book {
  final Duration duration;
  final String narrator;

  AudioBook({
    required super.title,
    required super.author,
    required this.duration,
    required this.narrator,
    super.year,
    super.pages,
    super.genres,
    super.status,
    super.rating,
  });

  @override
  double get readingHours => duration.inMinutes / 60;

  @override
  String describe() =>
      '«$title» — аудиокнига, читает $narrator, ${duration.inMinutes} мин.';
}

// ============================================================
// ЗАДАНИЕ 7. Обобщённый класс Library
// ============================================================
class Library<T extends LibraryItem> {
  final List<T> _items = [];

  List<T> get items => List.unmodifiable(_items);

  int get count => _items.length;

  void add(T item) {
    if (_items.contains(item)) return; // защита от дубликатов
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

// ============================================================
// ИСПРАВЛЕНИЕ КОДИРОВКИ ВВОДА
// ============================================================

// Таблица перекодировки CP866 -> Unicode для русских букв и символов
const Map<int, String> _cp866ToUnicode = {
  0x80: 'А',
  0x81: 'Б',
  0x82: 'В',
  0x83: 'Г',
  0x84: 'Д',
  0x85: 'Е',
  0x86: 'Ж',
  0x87: 'З',
  0x88: 'И',
  0x89: 'Й',
  0x8A: 'К',
  0x8B: 'Л',
  0x8C: 'М',
  0x8D: 'Н',
  0x8E: 'О',
  0x8F: 'П',
  0x90: 'Р',
  0x91: 'С',
  0x92: 'Т',
  0x93: 'У',
  0x94: 'Ф',
  0x95: 'Х',
  0x96: 'Ц',
  0x97: 'Ч',
  0x98: 'Ш',
  0x99: 'Щ',
  0x9A: 'Ъ',
  0x9B: 'Ы',
  0x9C: 'Ь',
  0x9D: 'Э',
  0x9E: 'Ю',
  0x9F: 'Я',
  0xA0: 'а',
  0xA1: 'б',
  0xA2: 'в',
  0xA3: 'г',
  0xA4: 'д',
  0xA5: 'е',
  0xA6: 'ж',
  0xA7: 'з',
  0xA8: 'и',
  0xA9: 'й',
  0xAA: 'к',
  0xAB: 'л',
  0xAC: 'м',
  0xAD: 'н',
  0xAE: 'о',
  0xAF: 'п',
  0xE0: 'р',
  0xE1: 'с',
  0xE2: 'т',
  0xE3: 'у',
  0xE4: 'ф',
  0xE5: 'х',
  0xE6: 'ц',
  0xE7: 'ч',
  0xE8: 'ш',
  0xE9: 'щ',
  0xEA: 'ъ',
  0xEB: 'ы',
  0xEC: 'ь',
  0xED: 'э',
  0xEE: 'ю',
  0xEF: 'я',
  0xF0: 'Ё',
  0xF1: 'ё'
};

String _decodeWindowsBytes(List<int> bytes) {
  // Пытаемся декодировать как UTF-8
  try {
    return utf8.decode(bytes).trim();
  } catch (_) {
    // Если не получилось (значит пришла CP866), перекодируем вручную
    final buffer = StringBuffer();
    for (final b in bytes) {
      if (b < 0x80) {
        buffer.writeCharCode(b); // ASCII символы (цифры, латиница)
      } else {
        buffer.write(_cp866ToUnicode[b] ?? '?'); // Кириллица
      }
    }
    return buffer.toString().trim();
  }
}

/// Чтение строки с обрезкой пробелов и \r (актуально для Windows).
String _readLine(String prompt) {
  stdout.write(prompt);
  final bytes = <int>[];
  int b;
  // Читаем байты до символа новой строки (\n)
  while ((b = stdin.readByteSync()) != 10 && b != -1) {
    if (b != 13) {
      // \r пропускаем
      bytes.add(b);
    }
  }
  return _decodeWindowsBytes(bytes);
}

// ============================================================
// ДЕМОНСТРАЦИЯ + МЕНЮ
// ============================================================
void main() {
  final lib = Library<Book>();

  final b1 = Book(
    title: 'Мастер и Маргарита',
    author: 'Булгаков',
    year: 1967,
    pages: 480,
    genres: {'роман', 'мистика'},
    status: ReadingStatus.reading,
  );
  final b2 = Book(
    title: 'Мастер и Маргарита',
    author: 'Булгаков',
    year: 1967,
    pages: 480,
    genres: {'роман', 'мистика'},
  );
  final paper = PaperBook(
    title: 'Дюна',
    author: 'Герберт',
    shelf: 'B-3',
    year: 1965,
    pages: 600,
    genres: {'фантастика'},
  )..vote(4.5);

  final ebook = EBook(
    title: 'Clean Code',
    author: 'Martin',
    format: 'pdf',
    sizeMb: 12.4,
    year: 2008,
    pages: 464,
    genres: {'программирование'},
  );

  final audio = AudioBook(
    title: 'Гарри Поттер',
    author: 'Роулинг',
    duration: const Duration(hours: 9, minutes: 30),
    narrator: 'Клюквин',
    year: 1997,
    pages: 300,
    genres: {'фэнтези'},
  );

  lib
    ..add(b1)
    ..add(b2)
    ..add(paper)
    ..add(ebook)
    ..add(audio);

  print('== Книги ==');
  for (final it in lib.items) {
    it.printCard();
    final b = it as Book;
    print('shortTitle: ${b.shortTitle}, age: ${b.age}, '
        'hours: ${b.readingHours.toStringAsFixed(1)}');
  }

  print('\n== Проверка ==/hashCode/Set ==');
  print('b1 == b2: ${b1 == b2}');
  print('hash: ${b1.hashCode} / ${b2.hashCode}');
  final set = {b1, b2};
  print('Размер Set: ${set.length} (ожидается 1)');

  print('\n== Сортировка (Comparable) ==');
  final sorted = [...lib.items]..sort();
  print(sorted.map((e) => e.title).toList());

  print('\n== Поиск ==');
  print(lib.search('булг').map((e) => e.title).toList());

  print('\n== countByGenre ==');
  print(lib.countByGenre());

  print('\n== copyWith ==');
  final modified = b1.copyWith(status: ReadingStatus.finished);
  print(modified.describe());

  print('\n== toJson ==');
  print(ebook.toJson());

  print('\n== Миксин Borrowable ==');
  paper.borrow(14);
  paper.log('Книга выдана');
  paper.giveBack();

  _menu(lib);
}

void _menu(Library<Book> lib) {
  while (true) {
    print('\n=== BookShelf ===');
    print('1. Список книг');
    print('2. Добавить книгу');
    print('3. Найти по названию');
    print('4. Поиск');
    print('5. Жанры');
    print('6. Выход');
    stdout.write('> ');

    // Читаем номер команды напрямую (там только ASCII цифры, проблем с кодировкой нет)
    final line = (stdin.readLineSync() ?? '').trim();

    switch (line) {
      case '1':
        if (lib.count == 0) {
          print('(библиотека пуста)');
        } else {
          for (final b in lib.items) {
            print('${b.title} — ${b.author} (${b.year})');
          }
        }
        break;

      case '2':
        final t = _readLine('Название: ');
        if (t.isEmpty) {
          print('Название не может быть пустым.');
          break;
        }
        final a = _readLine('Автор: ');
        lib.add(Book(title: t, author: a));
        print('Добавлено. Всего книг: ${lib.count}');
        break;

      case '3':
        final t = _readLine('Название: ');
        final f = lib.findByTitle(t);
        print(f == null ? 'Не найдено' : f.describe());
        break;

      case '4':
        final q = _readLine('Запрос: ');
        final res = lib.search(q).toList();
        if (res.isEmpty) {
          print('Ничего не найдено.');
        } else {
          for (final b in res) {
            print(b.describe());
          }
        }
        break;

      case '5':
        final map = lib.countByGenre();
        if (map.isEmpty) {
          print('(жанров нет)');
        } else {
          map.forEach((g, c) => print('$g: $c'));
        }
        break;

      case '6':
        return;

      default:
        print('Неизвестная команда');
    }
  }
}
