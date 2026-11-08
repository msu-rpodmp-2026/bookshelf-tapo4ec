import 'dart:io';
import 'dart:convert';

typedef Book = Map<String, Object?>;
typedef BookPredicate = bool Function(Book book);

final List<Book> library = [
  {'title': 'Основы Dart', 'author': 'С. А. Чернышев', 'year': 2024, 'pages': 521, 'genre': 'учебник', 'read': true},
  {'title': 'Flutter на практике', 'author': 'Ф. Заметти', 'year': 2020, 'pages': 328, 'genre': 'учебник', 'read': false},
  {'title': 'Мастер и Маргарита', 'author': 'М. Булгаков', 'year': 1966, 'pages': 480, 'genre': 'роман', 'read': true},
  {'title': 'Война и мир', 'author': 'Л. Толстой', 'year': 1869, 'pages': 1274, 'genre': 'роман', 'read': false},
  {'title': 'Преступление и наказание', 'author': 'Ф. Достоевский', 'year': 1866, 'pages': 671, 'genre': 'роман', 'read': true},
  {'title': 'Дюна', 'author': 'Ф. Герберт', 'year': 1965, 'pages': 688, 'genre': 'фантастика', 'read': false},
  {'title': '451 градус по Фаренгейту', 'author': 'Р. Брэдбери', 'year': 1953, 'pages': 256, 'genre': 'фантастика', 'read': true},
  {'title': 'Чистый код', 'author': 'Р. Мартин', 'year': 2008, 'pages': 464, 'genre': 'программирование', 'read': false},
];

Function makeCounter() {
  int count = 0;
  return () => ++count;
}

final countCommand = makeCounter();

void main() {
  stdout.encoding = utf8;
  stderr.encoding = utf8;

  var running = true;
  while (running) {
    printMenu();
    stdout.write('> ');
    final command = stdin.readLineSync(encoding: utf8)?.trim() ?? '';
    countCommand();

    switch (command) {
      case '1':
        printAll(library);
      case '2':
        stdout.write('Введите автора (или его часть): ');
        final query = (stdin.readLineSync(encoding: utf8) ?? '').trim();
        printAll(searchByField(library, 'author', query));
      case '3':
        stdout.write('Введите название (или его часть): ');
        final query = (stdin.readLineSync(encoding: utf8) ?? '').trim();
        printAll(searchByField(library, 'title', query));
      case '4':
        stdout.write('Введите жанр: ');
        final genre = (stdin.readLineSync(encoding: utf8) ?? '').trim();
        printAll(filter(library, (b) => (b['genre'] as String).toLowerCase() == genre.toLowerCase()));
      case '5':
        stdout.write('Показать прочитанные (1) или непрочитанные (0)? ');
        final isRead = stdin.readLineSync(encoding: utf8)?.trim() == '1';
        printAll(filterByRead(library, isRead));
      case '6':
        stdout.write('Сортировать по (title/author/year/pages): ');
        final field = (stdin.readLineSync(encoding: utf8) ?? '').trim();
        stdout.write('По убыванию? (1 - да, 0 - нет): ');
        final desc = stdin.readLineSync(encoding: utf8)?.trim() == '1';
        printAll(sortBy(library, field, descending: desc));
      case '7':
        printStatistics(library);
      case '8':
        addBook(library);
      case '9':
        deleteBook(library);
      case '0':
        running = false;
        print('Работа завершена.');
      default:
        print('Неизвестная команда. Повторите ввод.');
    }
  }
}

void printMenu() {
  print('\n--- МЕНЮ КАТАЛОГА ---');
  print('1. Показать весь каталог');
  print('2. Поиск по автору');
  print('3. Поиск по названию');
  print('4. Фильтр по жанру');
  print('5. Фильтр по признаку «прочитана»');
  print('6. Сортировка');
  print('7. Статистика каталога');
  print('8. Добавить книгу');
  print('9. Удалить книгу по номеру');
  print('0. Выход');
}

void printAll(List<Book> books, {String emptyMessage = 'Ничего не найдено.'}) {
  if (books.isEmpty) {
    print(emptyMessage);
    return;
  }
  for (var i = 0; i < books.length; i++) {
    final b = books[i];
    final readMark = b['read'] == true ? '[x]' : '[ ]';
    print('${(i + 1).toString().padLeft(2)}. $readMark '
        '${(b['title'] as String).padRight(30)} | '
        '${(b['author'] as String).padRight(20)} | '
        '${b['year'].toString().padLeft(4)} | '
        '${b['pages'].toString().padLeft(4)} стр. | '
        '${b['genre']}');
  }
}

List<Book> searchByField(List<Book> books, String field, String query) {
  final cleanQuery = query.trim();
  if (cleanQuery.isEmpty) return [];

  final lowerQuery = cleanQuery.toLowerCase();
  final queryWords = lowerQuery.split(' ').where((w) => w.isNotEmpty).toList();

  return books.where((b) {
    final fieldValue = (b[field] as String? ?? '').toLowerCase();
    return queryWords.every((word) => fieldValue.contains(word));
  }).toList();
}

List<Book> filterByRead(List<Book> books, bool isRead) {
  return books.where((b) => b['read'] == isRead).toList();
}

List<Book> sortBy(List<Book> books, String field, {bool descending = false}) {
  final copy = [...books];
  copy.sort((a, b) {
    final valA = a[field];
    final valB = b[field];
    int comparison = 0;
    if (valA is int && valB is int) {
      comparison = valA.compareTo(valB);
    } else if (valA is String && valB is String) {
      comparison = valA.toLowerCase().compareTo(valB.toLowerCase());
    }
    return descending ? -comparison : comparison;
  });
  return copy;
}

void printStatistics(List<Book> books) {
  if (books.isEmpty) {
    print('Каталог пуст.');
    return;
  }
  final total = books.length;
  final readCount = books.where((b) => b['read'] == true).length;
  final totalPages = books.fold<int>(0, (sum, b) => sum + (b['pages'] as int));
  final avgPages = totalPages / total;
  final oldest = books.reduce((a, b) => (a['year'] as int) < (b['year'] as int) ? a : b);
  final newest = books.reduce((a, b) => (a['year'] as int) > (b['year'] as int) ? a : b);
  final largest = books.reduce((a, b) => (a['pages'] as int) > (b['pages'] as int) ? a : b);
  final genres = books.map((b) => b['genre'] as String).toSet().join(', ');
  
  final Map<String, int> genreCounts = {};
  for (var b in books) {
    final g = b['genre'] as String;
    genreCounts[g] = (genreCounts[g] ?? 0) + 1;
  }

  print('\n--- СТАТИСТИКА ---');
  print('Всего книг: $total (Прочитано: $readCount)');
  print('Всего страниц: $totalPages (В среднем: ${avgPages.toStringAsFixed(1)})');
  print('Самая старая: ${oldest['title']} (${oldest['year']})');
  print('Самая новая: ${newest['title']} (${newest['year']})');
  print('Самая объемная: ${largest['title']} (${largest['pages']} стр.)');
  print('Уникальные жанры: $genres');
  print('По жанрам: $genreCounts');
  print('Доля прочитанного: ${(readCount / total * 100).toStringAsFixed(1)}%');
}

int askInt(String prompt, {int min = 0, int? max}) {
  int? value;
  do {
    stdout.write('$prompt: ');
    value = int.tryParse(stdin.readLineSync(encoding: utf8) ?? '');
    if (value == null || value < min || (max != null && value > max)) {
      print('Некорректное значение. Ожидается целое число'
          '${max == null ? ' не меньше $min' : ' от $min до $max'}.');
      value = null;
    }
  } while (value == null);
  return value;
}

void addBook(List<Book> books) {
  stdout.write('Название: ');
  final title = stdin.readLineSync(encoding: utf8) ?? 'Без названия';
  stdout.write('Автор: ');
  final author = stdin.readLineSync(encoding: utf8) ?? 'Неизвестен';
  final year = askInt('Год издания', min: 1000, max: 2100);
  final pages = askInt('Количество страниц', min: 1);
  stdout.write('Жанр: ');
  final genre = stdin.readLineSync(encoding: utf8) ?? 'неизвестно';
  stdout.write('Прочитана? (1 - да, 0 - нет): ');
  final read = stdin.readLineSync(encoding: utf8) == '1';

  books.add({
    'title': title,
    'author': author,
    'year': year,
    'pages': pages,
    'genre': genre,
    'read': read,
  });
  print('Книга добавлена.');
}

void deleteBook(List<Book> books) {
  if (books.isEmpty) {
    print('Каталог пуст.');
    return;
  }
  printAll(books);
  final index = askInt('Введите номер книги для удаления', min: 1, max: books.length) - 1;
  stdout.write('Вы уверены, что хотите удалить "${books[index]['title']}"? (да/нет): ');
  final confirm = stdin.readLineSync(encoding: utf8)?.trim().toLowerCase();
  
  if (confirm == 'да' || confirm == 'yes' || confirm == 'y') {
    books.removeAt(index);
    print('Книга удалена.');
  } else {
    print('Удаление отменено.');
  }
}

List<Book> filter(List<Book> books, BookPredicate test) {
  return books.where(test).toList();
}