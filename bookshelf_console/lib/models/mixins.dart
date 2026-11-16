import 'library_item.dart';

mixin Rateable {
  double _sum = 0;
  int _votes = 0;
  double get averageRating => _votes == 0 ? 0 : _sum / _votes;
  int get votesCount => _votes;

  void vote(double value) {
    if (value < 0 || value > 5) {
      throw ArgumentError('Оценка должна быть в диапазоне 0..5');
    }
    _sum += value;
    _votes++;
  }
}

mixin Loggable {
  void log(String message) {
    final ts = DateTime.now().toIso8601String();
    print('[$ts] $message');
  }
}

mixin Borrowable on LibraryItem {
  DateTime? _dueDate;
  bool get isBorrowed => _dueDate != null;
  DateTime? get dueDate => _dueDate;

  void borrow(int days) {
    _dueDate = DateTime.now().add(Duration(days: days));
    print('«$title» выдана до ${_dueDate!.toIso8601String().substring(0, 10)}');
  }

  void giveBack() {
    if (!isBorrowed) {
      print('«$title» не была выдана.');
      return;
    }
    _dueDate = null;
    print('«$title» возвращена.');
  }
}
