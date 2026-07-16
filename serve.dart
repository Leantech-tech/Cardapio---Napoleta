// ignore_for_file: avoid_print

import 'dart:io';

void main() async {
  const port = 8080;
  const root = 'build/web';

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Servindo $root em http://localhost:$port');
  print('Aperte Ctrl+C para parar.');

  await for (final request in server) {
    final uri = request.uri.path;
    var path = uri == '/' ? '$root/index.html' : '$root$uri';

    final file = File(path);
    if (await file.exists()) {
      final ext = path.split('.').last.toLowerCase();
      final contentType = _contentType(ext);
      request.response
        ..headers.contentType = contentType
        ..headers.set('Access-Control-Allow-Origin', '*')
        ..addStream(file.openRead())
        .then((_) => request.response.close());
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Não encontrado: $uri')
        ..close();
    }
  }
}

ContentType _contentType(String ext) {
  switch (ext) {
    case 'html':
      return ContentType.html;
    case 'js':
      return ContentType.parse('application/javascript');
    case 'css':
      return ContentType.parse('text/css');
    case 'json':
      return ContentType.json;
    case 'png':
      return ContentType.parse('image/png');
    case 'jpg':
    case 'jpeg':
      return ContentType.parse('image/jpeg');
    case 'webp':
      return ContentType.parse('image/webp');
    case 'svg':
      return ContentType.parse('image/svg+xml');
    case 'otf':
      return ContentType.parse('font/otf');
    case 'ttf':
      return ContentType.parse('font/ttf');
    case 'woff':
      return ContentType.parse('font/woff');
    case 'woff2':
      return ContentType.parse('font/woff2');
    default:
      return ContentType.text;
  }
}
