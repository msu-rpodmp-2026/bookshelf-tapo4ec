abstract interface class Searchable {
  bool matches(String query);
}

abstract interface class Exportable {
  Map<String, dynamic> toJson();
}
