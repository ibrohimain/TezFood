import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'package:tez_food_server/api.dart';
import 'package:tez_food_server/store.dart';

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final adminPin = Platform.environment['ADMIN_PIN'] ?? '2468';
  final kassaPin = Platform.environment['KASSA_PIN'] ?? '1357';
  final root = Directory(p.join(Directory.current.path, 'data'));
  final store = Store(root);
  await store.init();

  final api = Api(store: store, adminPin: adminPin, kassaPin: kassaPin);
  final webRoot = Directory(p.join(Directory.current.path, '..', 'app', 'build', 'web'));

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addMiddleware(apiErrors)
      .addHandler((request) {
    final path = request.url.path;
    if (path == 'api' || path.startsWith('api/')) return api.router.call(request);
    if (path == 'uploads' || path.startsWith('uploads/')) {
      return _uploads(request, store.uploads.path);
    }
    return _web(request, webRoot.path);
  });

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  final shown = 'http://${server.address.host}:${server.port}';
  print('TEZ FOOD server ishlayapti: $shown');
  print('Shu kompyuterda: http://localhost:${server.port}');
  print('Admin PIN: $adminPin');
  print('Kassa PIN: $kassaPin');
  if (!webRoot.existsSync()) {
    print('Web ilova hali yig\'ilmagan. app papkasida: flutter build web');
  }
}

Middleware _cors() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  };
  return (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await inner(request);
      return response.change(headers: headers);
    };
  };
}

Future<Response> _uploads(Request request, String uploadsPath) async {
  final name = request.url.path.replaceFirst(RegExp(r'^uploads/?'), '');
  if (name.isEmpty || name.contains('..') || name.contains('/') || name.contains('\\')) {
    return Response.forbidden('Ruxsat yo\'q');
  }
  final file = File(p.join(uploadsPath, name));
  if (!file.existsSync()) return Response.notFound('Rasm topilmadi');
  final type = name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
  return Response.ok(
    file.openRead(),
    headers: {
      'content-type': type,
      'cache-control': 'public, max-age=86400',
    },
  );
}

Future<Response> _web(Request request, String webRoot) async {
  final root = Directory(webRoot);
  if (!root.existsSync()) {
    return Response.notFound(
      'TEZ FOOD server ishlayapti. Ilovani ko\'rish uchun app papkasida flutter build web qiling '
      'yoki ishlab chiqishda flutter run -d chrome ishlating.',
      headers: {'content-type': 'text/plain; charset=utf-8'},
    );
  }
  final relative = request.url.path.isEmpty ? 'index.html' : request.url.path;
  final rootPath = p.normalize(root.absolute.path);
  final candidate = p.normalize(File(p.join(rootPath, relative)).absolute.path);
  if (_inside(rootPath, candidate)) {
    final file = File(candidate);
    if (file.existsSync() && file.statSync().type == FileSystemEntityType.file) {
      return Response.ok(file.openRead(), headers: {'content-type': _mime(candidate)});
    }
  }
  if (relative.contains('.')) {
    return Response.notFound('Topilmadi');
  }
  final index = File(p.join(rootPath, 'index.html'));
  if (!index.existsSync()) return Response.notFound('index.html topilmadi');
  return Response.ok(
    await index.readAsString(),
    headers: {'content-type': 'text/html; charset=utf-8'},
  );
}

bool _inside(String root, String candidate) {
  final left = root.toLowerCase();
  final right = candidate.toLowerCase();
  final sep = p.separator;
  return right == left || right.startsWith('$left$sep');
}

String _mime(String name) {
  switch (p.extension(name).toLowerCase()) {
    case '.html':
      return 'text/html; charset=utf-8';
    case '.js':
    case '.mjs':
      return 'application/javascript; charset=utf-8';
    case '.css':
      return 'text/css; charset=utf-8';
    case '.json':
      return 'application/json; charset=utf-8';
    case '.png':
      return 'image/png';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.svg':
      return 'image/svg+xml';
    case '.ico':
      return 'image/x-icon';
    case '.wasm':
      return 'application/wasm';
    case '.woff2':
      return 'font/woff2';
    case '.ttf':
      return 'font/ttf';
    case '.otf':
      return 'font/otf';
    default:
      return 'application/octet-stream';
  }
}
