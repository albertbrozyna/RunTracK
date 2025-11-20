import 'package:run_track/core/models/user.dart';

import '../../../../core/enums/sign_in_status.dart';

class SignInResult {
  final SignInStatus status;
  final User? user;
  final String? errorMessage;

  SignInResult({required this.status, this.user, this.errorMessage});
}
