import 'book.dart';
import 'mixins.dart';

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
  String describe() =>
      '«$title» — бумажная книга, полка $shelf, ${isBorrowed ? "выдана" : "на месте"}';
}
