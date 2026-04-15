import 'dart:async';
import 'dart:io';

class ServerConnectionException implements Exception {
  const ServerConnectionException([
    this.message = 'No se puede conectar con el servidor',
  ]);

  final String message;

  @override
  String toString() => message;
}

bool isServerConnectionFailure(Object error) {
  if (error is ServerConnectionException ||
      error is SocketException ||
      error is TimeoutException ||
      error is HttpException) {
    return true;
  }

  final message = error.toString().toLowerCase();
  const indicators = [
    'socketexception',
    'failed host lookup',
    'connection refused',
    'connection reset',
    'connection closed',
    'network is unreachable',
    'timed out',
    'timeoutexception',
    'clientexception',
  ];

  return indicators.any(message.contains);
}
