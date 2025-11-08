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

// Activity type
String? validateActivity(String? value) {
  if (value == null || value
      .trim()
      .isEmpty) {
    return 'Please select an activity';
  }
  return null;
}

// Start date
String? validateStartDate(String? value) {
  if (value == null || value
      .trim()
      .isEmpty) {
    return 'Please pick a start date of competition';
  }
  if (DateTime.tryParse(value.trim()) == null) {
    return 'Invalid start date';
  }
  if (DateTime.now().isAfter(DateTime.parse(value.trim()))) {
    return 'Start date must be in the future';
  }

  return null;
}

// End date
String? validateEndDate(String? value, String? startDateValue) {
  if (value == null || value
      .trim()
      .isEmpty) {
    return 'Please pick an end date';
  }
  DateTime? start = DateTime.tryParse(startDateValue ?? '');
  DateTime? end = DateTime.tryParse(value.trim());
  if (end == null) {
    return 'Invalid end date';
  }
  if (start == null) {
    return 'Invalid start date';
  }
  if (end.isBefore(start)) {
    return 'End date must be after start date';
  }
  if (start.add(Duration(hours: 2)).isAfter(end)) {
    return 'Competition cannot be shorter that 2 hours';
  }

  return null;
}

// Registration deadline
String? validateRegistrationDeadline(String? startDateValue, String? endDateValue, String? value) {
  if (startDateValue == null || startDateValue
      .trim()
      .isEmpty) {
    return 'Please select a start date before registration deadline';
  }
  if (endDateValue == null || endDateValue
      .trim()
      .isEmpty) {
    return 'Please select an end date before registration deadline';
  }
  DateTime? start = DateTime.tryParse(startDateValue);
  DateTime? end = DateTime.tryParse(endDateValue);
  if (start == null) {
    return 'Invalid end date';
  }
  if (end == null) {
    return 'Invalid end date';
  }

  if (value == null || value
      .trim()
      .isEmpty) {
    return 'Please pick a registration deadline';
  }
  DateTime? registrationDeadline = DateTime.tryParse(value.trim());
  if (registrationDeadline == null) {
    return 'Invalid date';
  }
  if (start.isBefore(registrationDeadline)) {
    return 'Registration deadline must be before start date';
  }
  if (end.isBefore(registrationDeadline)) {
    return 'Registration deadline must be before end date';
  }
  if (DateTime.now().isAfter(registrationDeadline)) {
    return 'Registration deadline must be in the future';
  }
  if (registrationDeadline.isBefore(DateTime.now().add(Duration(hours: 1)))) {
    return 'Registration deadline must be at least 1 hour from now';
  }
  return null;
}

// Max time to complete activity hours
String? validateGoal(String? value) {
  if (value == null || value
      .trim()
      .isEmpty) {
    return 'Please enter distance in km';
  }
  if (double.tryParse(value.trim()) == null) {
    return 'Enter a valid number';
  }
  if (double.tryParse(value.trim())! <= 0) {
    return 'Distance must be positive and greater than 0';
  }
  return null;
}

// Max time to complete activity hours
String? validateHours(String? value) {
  if (value != null && value
      .trim()
      .isNotEmpty) {
    if (int.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }
    if (int.tryParse(value.trim()) == 0) {
      return 'There must be at least one hour to complete activity';
    }
  }
  return null;
}

// Max time to complete activity minutes
String? validateMinutes(String? value) {
  if (value != null && value
      .trim()
      .isNotEmpty) {
    if (int.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }
    int minutes = int.parse(value.trim());
    if (minutes < 0 || minutes > 59) {
      return 'Minutes must be between 0 and 59';
    }
  }

  return null;
}