import 'book.dart';

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
