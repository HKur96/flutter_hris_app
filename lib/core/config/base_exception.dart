abstract class BaseException {
  final String errorMessage;

  const BaseException(this.errorMessage);

  String get message => errorMessage;

  @override
  String toString() => errorMessage;
}

class DataException extends BaseException {
  DataException(super.errorMessage);
}

class NetworkException extends BaseException {
  NetworkException(super.errorMessage);
}
