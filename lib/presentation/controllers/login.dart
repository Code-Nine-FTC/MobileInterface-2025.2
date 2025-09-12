import '../../domain/auth/auth_repository.dart';

class LoginController {
  final AuthRepository _authRepository;

  LoginController(this._authRepository);

  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;

    try {
      await _authRepository.login(email, password);
      isLoading = false;
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      return false;
    }
  }
}