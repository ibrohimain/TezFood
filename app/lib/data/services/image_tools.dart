import 'dart:typed_data';

import 'package:image/image.dart' as img;

Uint8List compressFoodPhoto(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return raw;
  final oriented = img.bakeOrientation(decoded);
  final resized = oriented.width > 1024 ? img.copyResize(oriented, width: 1024) : oriented;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 74));
}
