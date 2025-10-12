enum Visibility { me, friends, everyone }

Visibility? parseVisibility(String? str) {
  if (str == null) return null;
  switch (str) {
    case 'me':
      return Visibility.me;
    case 'friends':
      return Visibility.friends;
    case 'everyone':
      return Visibility.everyone;
  }
  return null;
}
