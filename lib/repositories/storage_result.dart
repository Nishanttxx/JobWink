/// A typed result monad for all storage operations.
///
/// Every storage repository method returns either [StorageSuccess] (carrying a value [T])
/// or [StorageFailure] (carrying a user-friendly [message]).
sealed class StorageResult<T> {
  const StorageResult();

  bool get isSuccess => this is StorageSuccess<T>;
  bool get isFailure => this is StorageFailure<T>;

  T? get valueOrNull =>
      this is StorageSuccess<T> ? (this as StorageSuccess<T>).value : null;

  String? get errorOrNull =>
      this is StorageFailure<T> ? (this as StorageFailure<T>).message : null;

  R when<R>({
    required R Function(T value) onSuccess,
    required R Function(String message) onFailure,
  }) {
    return switch (this) {
      StorageSuccess(:final value) => onSuccess(value),
      StorageFailure(:final message) => onFailure(message),
    };
  }
}

final class StorageSuccess<T> extends StorageResult<T> {
  final T value;
  const StorageSuccess(this.value);

  @override
  String toString() => 'StorageSuccess($value)';
}

final class StorageFailure<T> extends StorageResult<T> {
  final String message;
  final String? code;

  const StorageFailure(this.message, {this.code});

  @override
  String toString() => 'StorageFailure($message)';
}
