abstract class LibraryItem {
  String get title;
  String describe();
  void printCard() {
    print('--- Карточка ---');
    print(describe());
    print('----------------');
  }
}
