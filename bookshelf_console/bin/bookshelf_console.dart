import 'dart:io';
import 'dart:convert';

void main() {
  stdout.encoding = utf8;
  stderr.encoding = utf8;
  stdout.write('название: ');
  final String title = stdin.readLineSync(encoding: utf8) ?? '';

  stdout.write('автор: ');
  final String author = stdin.readLineSync(encoding: utf8) ?? 'неизвестен';

  stdout.write('год издания: ');
  final int year = int.tryParse(stdin.readLineSync(encoding: utf8) ?? '') ?? 0;

  stdout.write('количество страниц:');
  final int pages = int.tryParse(stdin.readLineSync() ?? '') ?? 0;

  final String category = pages < 150
      ? 'брошюра'
      : pages < 400
      ? 'книга'
      : 'том';

  final double readingHour = pages / 50;

  final int currentYear = DateTime.now().year;
  final int age = currentYear - year;

  final String initials = author
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}.')
      .join(' ');

  print('');
  print('=' * 44);
  print('$title');
  print('автор: $author');
  print('инициалы: $initials');
  print('год: $year');
  print('=' * 44);
  print('страниц: $pages ($category)');
  print('время чтения: $readingHour ч');
  print('возраст издания: $age ');

  print('');
  print('=' * 44);
  print('РАБОТА СО СПИСКОМ КНИГ');
  print('=' * 44);

  List<String> shelf = [
    'Война и мир',
    'Преступление и наказание',
    'Мастер и Маргарита',
    'Тихий Дон',
    'Отцы и дети',
  ];

  print('Список книг: $shelf');
  print('Длина списка: ${shelf.length}');
  print('Первый элемент: ${shelf.first}');
  print('Последний элемент: ${shelf.last}');

  shelf.insert(0, 'Анна Каренина');
  print('');
  print('После добавления в начало: $shelf');

  shelf.add('Евгений Онегин');
  print('После добавления в конец: $shelf');

  shelf.remove('Тихий Дон');
  print('После удаления "Тихий Дон": $shelf');

  print('Длина списка после изменений: ${shelf.length}');

  print('');
  print('=' * 44);
  print('РАБОТА С МНОЖЕСТВОМ ЖАНРОВ');
  print('=' * 44);

  stdout.write('Введите жанры через запятую: ');
  final String genresInput = stdin.readLineSync(encoding: utf8) ?? '';

  final List<String> genresList = genresInput
      .split(',')
      .map((genre) => genre.trim())
      .where((genre) => genre.isNotEmpty)
      .toList();

  print('');
  print('Введённые жанры (список): $genresList');
  print('Количество введённых жанров: ${genresList.length}');

  Set<String> genres = genresList.toSet();

  print('');
  print('Множество жанров (Set): $genres');
  print('Количество уникальных жанров: ${genres.length}');
  print('Дубликаты отброшены: ${genresList.length - genres.length} шт.');

  print('');
  print('Проверка отбрасывания дубликатов:');
  final String firstGenre = genres.isNotEmpty ? genres.first : 'фантастика';
  print('Пробуем добавить "$firstGenre" повторно...');
  genres.add(firstGenre);
  print('Множество после попытки добавить дубликат: $genres');
  print('Размер множества не изменился: ${genres.length}');

  if (genres.isNotEmpty) {
    print('');
    print(
      'Содержит ли множество "$firstGenre"? ${genres.contains(firstGenre)}',
    );
  }

  print('');
  print('=' * 44);
  print('РАБОТА С КАРТОЙ КНИГ');
  print('=' * 44);

  Map<String, int> pagesByBook = {
    'Война и мир': 1274,
    'Преступление и наказание': 671,
    'Мастер и Маргарита': 480,
    'Тихий Дон': 1600,
    'Отцы и дети': 288,
  };

  print('Все пары (название — количество страниц):');
  pagesByBook.forEach((book, pageCount) {
    print('  $book — $pageCount стр.');
  });

  String maxBook = '';
  int maxPages = 0;
  pagesByBook.forEach((book, pageCount) {
    if (pageCount > maxPages) {
      maxPages = pageCount;
      maxBook = book;
    }
  });

  print('');
  print('Книга с максимальным числом страниц: $maxBook ($maxPages стр.)');

  int totalPages = 0;
  pagesByBook.forEach((book, pageCount) {
    totalPages += pageCount;
  });

  final double averagePages = totalPages / pagesByBook.length;

  print('');
  print('Суммарное количество страниц: $totalPages');
  print('Среднее количество страниц: ${averagePages.toStringAsFixed(1)}');

  print('');
  print('=' * 44);
  print('ПОСТРОЕНИЕ СПИСКА ALL');
  print('=' * 44);

  final List<String> favorites = ['Мастер и Маргарита', 'Отцы и дети'];
  final bool includeGenres = genres.isNotEmpty;

  final List<String> all = [
    ...shelf,
    ...favorites,
    if (includeGenres) ...genres,
    if (pages > 0) 'Текущая книга: $title',
    for (final book in shelf) 'На полке: $book',
    for (int i = 0; i < 3; i++) 'Элемент №${i + 1}',
  ];

  print('Итоговый список all:');
  for (final item in all) {
    print('  - $item');
  }
  print('');
  print('Длина списка all: ${all.length}');
  // / - деление с плавающей точкой (ВОЗВРАЩАЕТ DOUBLE)
  // ~/ деление нацело(возвращает int, остаток отбрасывается)
  // % остаток от деления
  print(7 / 2); //3.5 (double)
  print(7 ~/ 2); //3 (int)
  print(7 % 2); //1 (остаток)
  // ленивое вычисление операторов && и ||
  // правый операнд вычисляется только если результат ещё не опредедлён
  // для && если левый false - правый не вычисляется
  // для || если левый true - правый не вычисляется
  bool sideEffect() {
    print('->sideEffect() вызвана');
    return true;
  }

  print('--&&--');
  print(false && sideEffect()); //sideEffect() не вызывается, результат false

  print('--||--');
  print(true || sideEffect()); //sideEffect() не вызывается, результат true

  print('--оба вычисляются--');
  print(true && sideEffect()); //sideEffect() вызывается
  print(false || sideEffect()); //sideEffect() вызывается

  //операторы ?., ??, ??=
  String? maybeNull; //null
  String? notNull = 'Dart'; //не Null

  //?. - безопасны доступ: если объект Null, вернёт Null, а не бросит исключение
  print(maybeNull?.length); //nell
  print(notNull?.length); //4

  //?? - если Null, то взять альтернативу
  print(maybeNull ?? 'default'); //default
  print(notNull ?? 'default'); //Dart

  //??= - присвоить значение только если переменная Null
  maybeNull ??= 'assigned';
  print(maybeNull);
  notNull ??= 'ignored'; // не сработает т.к. notNull != null
  print(notNull);
  //Различие final и const на примере списка
  // final  — переменная инициализируется один раз (во время выполнения), но СОДЕРЖИМОЕ объекта можно менять.
  // const  — константа времени компиляции, объект глубоко неизменяем.

  final finalList = [1, 2, 3];
  finalList.add(4); // OK: содержимое можно менять
  // finalList = [5, 6];      // Ошибка: переприсвоить нельзя
  print(finalList); // [1, 2, 3, 4]

  const constList = [1, 2, 3];
  // constList.add(4);        // Ошибка: содержимое const-списка неизменяемо
  // constList = [5];         // Ошибка: переприсвоить нельзя
  print(constList); // [1, 2, 3]
  //Каскадный оператор .. с StringBuffer
  // .. позволяет вызывать несколько методов на одном объекте, не переписывая имя объекта каждый раз.
  // Выражение возвращает сам объект (а не результат последнего метода).

  final buffer = StringBuffer()
    ..write('Hello')
    ..write(', ')
    ..write('world')
    ..writeln('!');

  print(buffer.toString()); // Hello, world!\n

  // Эквивалент без каскада:
  // buffer.write('Hello');
  // buffer.write(', ');
}
