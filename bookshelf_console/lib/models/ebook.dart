import 'book.dart';

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
  String describe() =>
      '«$title» — электронная книга ($format, ${sizeMb.toStringAsFixed(1)} МБ)';
}
