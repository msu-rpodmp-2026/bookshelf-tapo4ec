import 'dart:io';
import 'dart:convert';

import 'package:book_shelf/models/book.dart';
import 'package:book_shelf/models/library.dart';
import 'package:book_shelf/models/library_storage.dart';
import 'package:book_shelf/models/reading_status.dart';

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
  if (b == -1 && bytes.isEmpty) return null;

  try {
    return utf8.decode(bytes).trim();
  } catch (_) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      if (byte < 0x80) {
        buffer.writeCharCode(byte);
      } else {
        buffer.write(_cp866ToUnicode[byte] ?? '?');
      }
    }
    return buffer.toString().trim();
  }
}

class LibraryFormatException implements Exception {
  final String message;
  final int line;
  LibraryFormatException(this.message, this.line);
  @override
  String toString() => 'Ошибка в строке $line: $message';
}

void main(List<String> args) async {
  String dataDir = 'data';
  bool exportCsvFlag = false;
  bool importCsvFlag = false;
  bool statsFlag = false;
  bool helpFlag = false;

  for (final arg in args) {
    if (arg == '--export-csv') {
      exportCsvFlag = true;
    } else if (arg == '--import-csv') {
      importCsvFlag = true;
    } else if (arg == '--stats') {
      statsFlag = true;
    } else if (arg == '--help') {
      helpFlag = true;
    } else if (!arg.startsWith('--')) {
      dataDir = arg;
    }
  }

  if (helpFlag) {
    print('Использование: dart run bin/bookshelf_console.dart [путь] [флаги]');
    print('Флаги: --export-csv, --import-csv, --stats, --help');
    return;
  }

  final storage = LibraryStorage(dataDir);
  final lib = Library<Book>();

  try {
    print('Загрузка каталога из $dataDir...');
    final loadedBooks = await storage.load();
    for (final b in loadedBooks) {
      lib.add(b);
    }
    print('Загружено книг: ${lib.count}');
  } on PathNotFoundException {
    print('Файл каталога не найден — создан новый пустой каталог.');
  } on FormatException catch (e) {
    print('Файл повреждён: ${e.message}');
  } on FileSystemException catch (e) {
    print('Ошибка файловой системы: ${e.message} код(${e.osError?.errorCode})');
    rethrow;
  } finally {
    print('Загрузка завершена.\n');
  }

  if (exportCsvFlag) {
    await storage.exportCsv(lib.items);
    print('Экспорт в CSV завершен.');
    return;
  }

  if (importCsvFlag) {
    try {
      final imported = await storage.importCsv();
      for (final b in imported) {
        lib.add(b);
      }
      await storage.save(lib.items);
      print('Импортировано книг: ${imported.length}');
    } on FileSystemException catch (e) {
      print('Ошибка чтения CSV: ${e.message}');
    }
    return;
  }

  if (statsFlag) {
    print('Всего книг: ${lib.count}');
    print('Жанры: ${lib.countByGenre()}');
    return;
  }

  while (true) {
    print('\n=== BookShelf ===');
    print('1. Список книг');
    print('2. Добавить книгу');
    print('3. Найти по названию');
    print('4. Поиск (по всем полям)');
    print('5. Удалить книгу');
    print('6. Показать прочитанные/непрочитанные');
    print('7. Сортировать книги');
    print('8. Экспорт в CSV');
    print('9. Импорт из CSV');
    print('10. Резервная копия');
    print('11. Выход');

    final line = _readLine('> ');

    if (line == null) {
      print('\n[Завершение ввода. Сохранение и выход.]');
      await storage.save(lib.items);
      break;
    }

    switch (line) {
      case '1':
        if (lib.count == 0) {
          print('(библиотека пуста)');
        } else {
          for (final b in lib.items) {
            print('${b.title} — ${b.author} (${b.year}) [${b.status.label}]');
          }
        }
        break;

      case '2':
        final t = _readLine('Название: ');
        if (t == null) {
          print('\n[Ввод прерван. Добавление отменено.]');
          return;
        }
        if (t.isEmpty) {
          print('Ошибка: Название не может быть пустым.');
          break;
        }

        final a = _readLine('Автор: ');
        if (a == null) {
          print('\n[Ввод прерван. Добавление отменено.]');
          return;
        }
        if (a.isEmpty) {
          print('Ошибка: Автор не может быть пустым.');
          break;
        }

        int year;
        while (true) {
          final yStr = _readLine('Год: ');
          if (yStr == null) {
            print('\n[Ввод прерван. Добавление отменено.]');
            return;
          }
          if (yStr.isEmpty) {
            print('Ошибка: поле Год не может быть пустым. Введите значение.');
            continue;
          }
          final parsedYear = int.tryParse(yStr);
          if (parsedYear == null) {
            print('Ошибка: введите корректный год (число).');
            continue;
          }
          year = parsedYear;
          break;
        }

        int pages;
        while (true) {
          final pStr = _readLine('Страницы: ');
          if (pStr == null) {
            print('\n[Ввод прерван. Добавление отменено.]');
            return;
          }
          if (pStr.isEmpty) {
            print(
                'Ошибка: поле Страницы не может быть пустым. Введите значение.');
            continue;
          }
          final parsedPages = int.tryParse(pStr);
          if (parsedPages == null || parsedPages <= 0) {
            print('Ошибка: введите положительное число страниц.');
            continue;
          }
          pages = parsedPages;
          break;
        }

        String genre = '';
        while (true) {
          final gStr = _readLine('Жанр: ');
          if (gStr == null) {
            print('\n[Ввод прерван. Добавление отменено.]');
            return;
          }
          if (gStr.isEmpty) {
            print('Ошибка: поле Жанр не может быть пустым. Введите значение.');
            continue;
          }
          genre = gStr;
          break;
        }

        ReadingStatus status = ReadingStatus.planned;
        while (true) {
          print('Статус: 0-Запланирована, 1-Читаю, 2-Прочитана, 3-Брошена');
          final sStr = _readLine('> ');

          if (sStr == null) {
            print('\n[Ввод прерван. Добавление отменено.]');
            return;
          }
          if (sStr.isEmpty) {
            print(
                'Ошибка: поле Статус не может быть пустым. Введите число от 0 до 3.');
            continue;
          }
          final sInt = int.tryParse(sStr);
          if (sInt == null || sInt < 0 || sInt > 3) {
            print('Ошибка: введите число от 0 до 3.');
            continue;
          }
          status = ReadingStatus.values[sInt];
          break;
        }

        lib.add(Book(
            title: t,
            author: a,
            year: year,
            pages: pages,
            genres: {genre},
            status: status));
        await storage.save(lib.items);
        print('Добавлено и сохранено. Всего книг: ${lib.count}');
        break;

      case '3':
        final t = _readLine('Название: ');
        if (t == null) return;
        final f = lib.findByTitle(t);
        print(f == null ? 'Не найдено' : f.describe());
        break;

      case '4':
        final q = _readLine('Запрос: ');
        if (q == null) return;
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
        final t = _readLine('Название для удаления: ');
        if (t == null) return;
        final b = lib.findByTitle(t);
        if (b != null) {
          lib.remove(b);
          await storage.save(lib.items);
          print('Книга «${b.title}» удалена и каталог сохранен.');
        } else {
          print('Книга не найдена.');
        }
        break;

      case '6':
        print('1. Прочитанные');
        print('2. Непрочитанные (в планах / читаю)');
        final mode = _readLine('> ');
        if (mode == null) return;

        final filtered =
            lib.where((b) => mode == '1' ? b.status.isDone : !b.status.isDone);
        if (filtered.isEmpty) {
          print('Нет книг по заданному фильтру.');
        } else {
          for (final b in filtered) {
            print('${b.title} [${b.status.label}]');
          }
        }
        break;

      case '7':
        print('1. По названию (А-Я)');
        print('2. По году (сначала новые)');
        print('3. По автору (А-Я)');
        print('4. По объему страниц (сначала толстые)');
        final sortMode = _readLine('> ');
        if (sortMode == null) return;

        final sortedList = [...lib.items];
        if (sortMode == '1') {
          sortedList.sort();
        } else if (sortMode == '2') {
          sortedList.sort((a, b) => b.year.compareTo(a.year));
        } else if (sortMode == '3') {
          sortedList.sort((a, b) =>
              a.author.toLowerCase().compareTo(b.author.toLowerCase()));
        } else if (sortMode == '4') {
          sortedList.sort((a, b) => b.pages.compareTo(a.pages));
        }

        for (final b in sortedList) {
          print('${b.title} — ${b.author} (${b.year}), ${b.pages} с.');
        }
        break;

      case '8':
        await storage.exportCsv(lib.items);
        print('Экспорт в CSV выполнен (library.csv).');
        break;

      case '9':
        final imported = await storage.importCsv();
        for (final b in imported) {
          lib.add(b);
        }
        await storage.save(lib.items);
        print('Импортировано книг: ${imported.length}');
        break;

      case '10':
        final success = await storage.backup();
        print(success
            ? 'Резервная копия создана.'
            : 'Нет данных для копирования.');
        break;

      case '11':
        await storage.save(lib.items);
        print('Сохранено записей: ${lib.count}');
        return;

      default:
        print('Неизвестная команда');
    }
  }
}
