import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'book.dart';
import 'reading_status.dart';

class LibraryStorage {
  final String directory;
  const LibraryStorage(this.directory);

  String get _jsonPath => p.join(directory, 'library.json');
  String get _csvPath => p.join(directory, 'library.csv');

  // Загрузка из JSON
  Future<List<Book>> load() async {
    final file = File(_jsonPath);
    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList
          .map((j) => Book.fromJson(j as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) {
      final bakFile = File('$_jsonPath.bak');
      await file.rename(bakFile.path);
      stderr.writeln(
          'Файл поврежден: ${e.message}. Переименован в ${bakFile.path}');
      return [];
    }
  }

  // Сохранение в JSON (через временный файл)
  Future<void> save(List<Book> books) async {
    await Directory(directory).create(recursive: true);
    final file = File(_jsonPath);
    final tempFile = File('$_jsonPath.tmp');

    final encoder = const JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(books.map((b) => b.toJson()).toList());

    await tempFile.writeAsString(jsonString);
    await tempFile.rename(file.path);
  }

  // Экспорт в CSV
  Future<void> exportCsv(List<Book> books) async {
    await Directory(directory).create(recursive: true);
    final file = File(_csvPath);

    final buffer = StringBuffer();
    buffer.writeln('title;author;year;pages;genres;status;rating');

    for (final b in books) {
      final genresStr = b.genres.join(',');
      final title = b.title.contains(';') ? '"${b.title}"' : b.title;
      final author = b.author.contains(';') ? '"${b.author}"' : b.author;
      final ratingStr = b.rating?.toString() ?? '';

      buffer.writeln(
          '$title;$author;${b.year};${b.pages};$genresStr;${b.status.name};$ratingStr');
    }

    await file.writeAsString(buffer.toString());
  }

  // Импорт из CSV
  Future<List<Book>> importCsv() async {
    final file = File(_csvPath);
    if (!await file.exists()) return [];

    final lines = await file.readAsLines();
    final books = <Book>[];
    int skipped = 0;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(';');
      if (parts.length < 6) {
        skipped++;
        continue;
      }

      try {
        final genres =
            parts[4].isEmpty ? <String>{} : parts[4].split(',').toSet();
        books.add(Book(
          title: parts[0].replaceAll('"', ''),
          author: parts[1].replaceAll('"', ''),
          year: int.tryParse(parts[2]) ?? 0,
          pages: int.tryParse(parts[3]) ?? 0,
          genres: genres,
          status: ReadingStatus.fromName(parts[5]),
          rating: double.tryParse(parts[6]),
        ));
      } catch (e) {
        skipped++;
      }
    }

    if (skipped > 0) {
      print('Пропущено строк при импорте: $skipped');
    }
    return books;
  }

  // Резервная копия
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
