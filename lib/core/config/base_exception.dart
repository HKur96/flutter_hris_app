abstract class BaseException {
  final String errorMessage;

  const BaseException(this.errorMessage);
}

class DataException extends BaseException {
  DataException(super.errorMessage);
}

class NetworkException extends BaseException {
  NetworkException(super.errorMessage);
}
