import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'book.dart';
import 'reading_status.dart';

class LibraryFormatException implements Exception {
  final String message;
  final int line;
  LibraryFormatException(this.message, this.line);

  @override
  String toString() => 'Ошибка в строке $line: $message';
}

class LibraryStorage {
  final String directory;
  const LibraryStorage(this.directory);

  String get _jsonPath => p.join(directory, 'library.json');
  String get _csvPath => p.join(directory, 'library.csv');

  Future<List<Book>> load() async {
    final file = File(_jsonPath);
    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final dynamic decoded = jsonDecode(content);

      if (decoded is! List) {
        throw const FormatException(
            'Корневой элемент JSON должен быть массивом ([]), а не объектом ({})');
      }

      final books = <Book>[];
      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is! Map<String, dynamic>) {
          throw FormatException('Элемент под индексом $i не является объектом');
        }

        if (item['year'] != null && item['year'] is! num) {
          throw FormatException('Поле year под индексом $i должно быть числом');
        }
        if (item['pages'] != null && item['pages'] is! num) {
          throw FormatException(
              'Поле pages под индексом $i должно быть числом');
        }

        books.add(Book.fromJson(item));
      }
      return books;
    } catch (e) {
      final bakFile = File('$_jsonPath.bak');
      await file.copy(bakFile.path);
      await file.delete();
      stderr.writeln(
          'Файл поврежден или имеет неверную структуру: $e. Сохранен как ${bakFile.path}');
      return [];
    }
  }

  Future<void> save(List<Book> books) async {
    await Directory(directory).create(recursive: true);
    final file = File(_jsonPath);
    final tempFile = File('$_jsonPath.tmp');

    final encoder = const JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(books.map((b) => b.toJson()).toList());

    await tempFile.writeAsString(jsonString);
    await tempFile.rename(file.path);
  }

  Future<void> exportCsv(List<Book> books) async {
    await Directory(directory).create(recursive: true);
    final file = File(_csvPath);

    final buffer = StringBuffer();
    buffer.writeln('title;author;year;pages;genres;status;rating');

    for (final b in books) {
      final title = _escapeCsv(b.title);
      final author = _escapeCsv(b.author);
      final genresStr = _escapeCsv(b.genres.join(','));
      final ratingStr = b.rating?.toString() ?? '';

      buffer.writeln(
          '$title;$author;${b.year};${b.pages};$genresStr;${b.status.name};$ratingStr');
    }

    await file.writeAsString(buffer.toString());
  }

  String _escapeCsv(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<List<Book>> importCsv() async {
    final file = File(_csvPath);
    if (!await file.exists()) return [];

    final lines = await file.readAsLines();
    final books = <Book>[];
    int skipped = 0;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final parts = _parseCsvLine(line);

        if (parts.length < 6) {
          throw LibraryFormatException(
              'Неверное число полей (ожидалось минимум 6, получено ${parts.length})',
              i + 1);
        }

        final genres =
            parts[4].isEmpty ? <String>{} : parts[4].split(',').toSet();
        books.add(Book(
          title: parts[0],
          author: parts[1],
          year: int.tryParse(parts[2]) ?? 0,
          pages: int.tryParse(parts[3]) ?? 0,
          genres: genres,
          status: ReadingStatus.fromName(parts[5]),
          rating: double.tryParse(parts[6]),
        ));
      } on LibraryFormatException catch (e) {
        print('Пропущена строка: $e');
        skipped++;
      } catch (e) {
        print('Ошибка парсинга строки ${i + 1}: $e');
        skipped++;
      }
    }

    if (skipped > 0) {
      print('Всего пропущено строк при импорте: $skipped');
    }
    return books;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ';' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());

    return result;
  }

  Future<bool> backup() async {
    final file = File(_jsonPath);
    if (!await file.exists()) return false;

    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final backupPath = p.join(directory, 'library_backup_$timestamp.json');
    await file.copy(backupPath);
    return true;
  }
}
