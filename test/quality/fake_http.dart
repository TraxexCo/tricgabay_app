import 'dart:async';
import 'dart:convert';
import 'dart:io';

class FixtureHttp extends HttpOverrides {
  static final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jG+UAAAAASUVORK5CYII=',
  );
  @override
  HttpClient createHttpClient(SecurityContext? context) => _Client();
}

class _Client implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _Request();
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _Request();
  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  @override
  final headers = _Headers();
  @override
  bool followRedirects = true, persistentConnection = true;
  @override
  int maxRedirects = 5, contentLength = -1;
  @override
  Future<HttpClientResponse> close() async => _Response();
  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Headers implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  List<String>? operator [](String name) =>
      name.toLowerCase() == 'content-type' ? ['image/png'] : null;
  @override
  void forEach(void Function(String, List<String>) action) {
    action('content-type', ['image/png']);
    action('cache-control', ['max-age=3600']);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => FixtureHttp.bytes.length;
  @override
  final headers = _Headers();
  @override
  String get reasonPhrase => 'OK';
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => true;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(FixtureHttp.bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
