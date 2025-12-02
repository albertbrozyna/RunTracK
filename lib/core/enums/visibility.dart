enum ComVisibility {
  me,
  friends,
  everyone;

  String toDbString() {
    return name;
  }

  static ComVisibility fromDbString(String? value) {
    return ComVisibility.values.firstWhere(
          (e) => e.name == value,
      orElse: () => ComVisibility.me,
    );
  }
}