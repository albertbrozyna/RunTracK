String? validateName(String? value) {
  if (value == null || value
      .trim()
      .isEmpty) {
    return 'Please enter a name';
  }
  if (value
      .trim()
      .length < 5) {
    return 'Name must be at least 5 characters';
  }
  return null;
}

// Description
String? validateDescription(String? value) {
  if (value == null || value
      .trim()
      .isEmpty) {
    return 'Please enter a description';
  }
  if (value
      .trim()
      .length < 10) {
    return 'Description must be at least 10 characters';
  }
  return null;
}


