sealed class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class AccessDeniedFailure extends Failure {
  const AccessDeniedFailure()
      : super('Access denied. This app is for warehouse managers only.');
}
