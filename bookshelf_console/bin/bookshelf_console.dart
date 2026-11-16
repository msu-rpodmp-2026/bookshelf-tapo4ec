import 'dart:io';
import 'dart:convert';

import 'package:book_shelf/models/audio_book.dart';
import 'package:book_shelf/models/book.dart';
import 'package:book_shelf/models/ebook.dart';
import 'package:book_shelf/models/library.dart';
import 'package:book_shelf/models/paper_book.dart';
import 'package:book_shelf/models/reading_status.dart';

// Конвертация CP866 -> UTF-8 для Windows
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

String? _readLine(String prompt) {
  stdout.write(prompt);
  final bytes = <int>[];
  int b;
  while ((b = stdin.readByteSync()) != 10 && b != -1) {
    if (b != 13) bytes.add(b);
  }

  // Если поток закрыт (Ctrl+D / Ctrl+Z) и мы ничего не прочитали
  if (b == -1 && bytes.isEmpty) return null;

  try {
    return utf8.decode(bytes).trim();
  } catch (_) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      if (byte < 0x80)
        buffer.writeCharCode(byte);
      else
        buffer.write(_cp866ToUnicode[byte] ?? '?');
    }
    return buffer.toString().trim();
  }
}

void main() {
  final lib = Library<Book>();

  // Базовая инициализация демо-данными (без сложного вывода в консоль при старте)
  lib
    ..add(Book(
        title: 'Мастер и Маргарита',
        author: 'Булгаков',
        year: 1967,
        genres: {'роман'}))
    ..add(PaperBook(
        title: 'Дюна',
        author: 'Герберт',
        shelf: 'B-3',
        year: 1965,
        genres: {'фантастика'}))
    ..add(EBook(
        title: 'Clean Code',
        author: 'Martin',
        format: 'pdf',
        year: 2008,
        genres: {'программирование'},
        status: ReadingStatus.reading))
    ..add(AudioBook(
        title: 'Гарри Поттер',
        author: 'Роулинг',
        duration: const Duration(hours: 9),
        narrator: 'Клюквин',
        genres: {'фэнтези'},
        status: ReadingStatus.finished));

  while (true) {
    print('\n=== BookShelf ===');
    print('1. Список книг');
    print('2. Добавить книгу');
    print('3. Найти по названию');
    print('4. Поиск (по всем полям)');
    print('5. Удалить книгу');
    print('6. Показать только прочитанные/непрочитанные');
    print('7. Сортировать по названию/году');
    print('8. Выход');

    final line = _readLine('> ');

    // Обработка End Of File (Ctrl+D / Ctrl+Z)
    if (line == null) {
      print('\n[Завершение ввода. Выход из программы.]');
      break;
    }

    switch (line) {
      case '1':
        if (lib.count == 0)
          print('(библиотека пуста)');
        else
          for (final b in lib.items)
            print('${b.title} — ${b.author} (${b.year}) [${b.status.label}]');
        break;

      case '2':
        final t = _readLine('Название: ');
        if (t == null) break; // Защита от Ctrl+D при вводе названия
        if (t.isEmpty) {
          print('Название не может быть пустым.');
          break;
        }
        final a = _readLine('Автор: ');
        if (a == null) break;
        lib.add(Book(title: t, author: a));
        print('Добавлено. Всего книг: ${lib.count}');
        break;

      case '3':
        final t = _readLine('Название: ');
        if (t == null) break;
        final f = lib.findByTitle(t);
        print(f == null ? 'Не найдено' : f.describe());
        break;

      case '4':
        final q = _readLine('Запрос: ');
        if (q == null) break;
        final res = lib.search(q).toList();
        if (res.isEmpty)
          print('Ничего не найдено.');
        else
          for (final b in res) print(b.describe());
        break;

      case '5':
        final t = _readLine('Название для удаления: ');
        if (t == null) break;
        final b = lib.findByTitle(t);
        if (b != null) {
          lib.remove(b);
          print('Книга «${b.title}» удалена.');
        } else {
          print('Книга не найдена.');
        }
        break;

      case '6':
        print('1. Прочитанные');
        print('2. Непрочитанные (в планах / читаю)');
        final mode = _readLine('> ');
        if (mode == null) break;

        final filtered =
            lib.where((b) => mode == '1' ? b.status.isDone : !b.status.isDone);
        if (filtered.isEmpty)
          print('Нет книг по заданному фильтру.');
        else
          for (final b in filtered) print('${b.title} [${b.status.label}]');
        break;

      case '7':
        print('1. По названию (А-Я)');
        print('2. По году (сначала новые)');
        final sortMode = _readLine('> ');
        if (sortMode == null) break;

        final sortedList = [...lib.items]; // копия
        if (sortMode == '1')
          sortedList.sort(); // использует compareTo
        else if (sortMode == '2')
          sortedList.sort((a, b) => b.year.compareTo(a.year));

        for (final b in sortedList) print('${b.title} (${b.year})');
        break;

      case '8':
        return;

      default:
        print('Неизвестная команда');
    }
  }
}
