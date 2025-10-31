enum ComVisibility { me, friends, everyone }

ComVisibility? parseVisibility(String? str) {
  if (str == null) return null;
  switch (str) {
    case 'Visibility.me':
      return ComVisibility.me;
    case 'Visibility.friends':
      return ComVisibility.friends;
    case 'Visibility.everyone':
      return ComVisibility.everyone;
  }
  return null;
}
