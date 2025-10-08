import 'package:run_track/models/user.dart' as model;
import '../common/enums/sign_in_status.dart';

class SignInResult {
  final SignInStatus status;
  final model.User? user;
  final String? errorMessage;

  SignInResult({required this.status, this.user, this.errorMessage});
}