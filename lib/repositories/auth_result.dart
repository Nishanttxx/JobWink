/// A typed result monad for all authentication operations.
///
/// Every repository method returns either [AuthSuccess] (carrying a value [T])
/// or [AuthFailure] (carrying a user-friendly [message]).
///
/// ### Usage
/// ```dart
/// final result = await _repo.signIn(email: e, password: p);
/// switch (result) {
///   case AuthSuccess(:final value):
///     // use value
///   case AuthFailure(:final message):
///     // show error
/// }
/// ```
sealed class AuthResult<T> {
  const AuthResult();

  /// Returns `true` if this result represents a successful operation.
  bool get isSuccess => this is AuthSuccess<T>;

  /// Returns `true` if this result represents a failure.
  bool get isFailure => this is AuthFailure<T>;

  /// Returns the success value, or `null` if this is a failure.
  T? get valueOrNull =>
      this is AuthSuccess<T> ? (this as AuthSuccess<T>).value : null;

  /// Returns the error message, or `null` if this is a success.
  String? get errorOrNull =>
      this is AuthFailure<T> ? (this as AuthFailure<T>).message : null;

  /// Runs [onSuccess] with the value when successful, [onFailure] with the
  /// message when failed, and returns the result of whichever branch runs.
  R when<R>({
    required R Function(T value) onSuccess,
    required R Function(String message) onFailure,
  }) {
    return switch (this) {
      AuthSuccess(:final value) => onSuccess(value),
      AuthFailure(:final message) => onFailure(message),
    };
  }
}

/// Represents a successful auth operation, carrying an optional [value].
final class AuthSuccess<T> extends AuthResult<T> {
  final T value;
  const AuthSuccess(this.value);

  @override
  String toString() => 'AuthSuccess($value)';
}

/// Represents a failed auth operation, carrying a user-friendly [message].
final class AuthFailure<T> extends AuthResult<T> {
  final String message;

  /// Optional machine-readable error code (e.g., 'invalid_credentials').
  final String? code;

  const AuthFailure(this.message, {this.code});

  @override
  String toString() => 'AuthFailure($message)';
}
