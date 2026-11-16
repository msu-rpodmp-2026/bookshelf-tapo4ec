enum ReadingStatus {
  planned('Запланирована', 0),
  reading('Читаю', 1),
  finished('Прочитана', 2),
  abandoned('Брошена', 3);

  final String label;
  final int order;
  const ReadingStatus(this.label, this.order);
  bool get isDone => this == ReadingStatus.finished;

  static ReadingStatus fromName(String name) => values.firstWhere(
        (s) => s.name == name,
        orElse: () => planned,
      );
}
