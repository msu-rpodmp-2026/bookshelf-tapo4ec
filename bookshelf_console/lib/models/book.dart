import 'interfaces.dart';
import 'library_item.dart';
import 'reading_status.dart';

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
  int get age => year == 0 ? 0 : DateTime.now().year - year;
  bool get isRated => _rating != null;
  double? get rating => _rating;

  set rating(double? value) {
    if (value != null) _checkRating(value);
    _rating = value;
  }

  void _checkRating(double v) {
    if (v < 0 || v > 5)
      throw ArgumentError.value(v, 'rating', 'Допустимо 0..5');
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

  // === Задание 2: Сериализация ===
  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'year': year,
        'pages': pages,
        'genres': genres.toList(),
        'status': status.name,
        if (_rating != null) 'rating': _rating,
      };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        title: j['title'] as String? ?? 'Без названия',
        author: j['author'] as String? ?? 'Автор неизвестен',
        year: (j['year'] as num?)?.toInt() ?? 0,
        pages: (j['pages'] as num?)?.toInt() ?? 0,
        genres: (j['genres'] as List?)?.cast<String>().toSet() ?? <String>{},
        status: ReadingStatus.fromName(j['status'] as String? ?? ''),
        rating: (j['rating'] as num?)?.toDouble(),
      );

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
