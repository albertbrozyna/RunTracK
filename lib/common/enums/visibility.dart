enum Visibility { me, friends, everyone }

Visibility? parseVisibility(String? str) {
  if (str == null) return null;
  switch (str) {
    case 'Visibility.me':
      return Visibility.me;
    case 'Visibility.friends':
      return Visibility.friends;
    case 'Visibility.everyone':
      return Visibility.everyone;
  }
  return null;
}
