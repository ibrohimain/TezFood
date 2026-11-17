import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

Future<GeoPoint> currentPosition() {
  final done = Completer<GeoPoint>();
  web.window.navigator.geolocation.getCurrentPosition(
    ((web.GeolocationPosition position) {
      if (done.isCompleted) return;
      done.complete(GeoPoint(position.coords.latitude, position.coords.longitude));
    }).toJS,
    ((web.GeolocationPositionError error) {
      if (done.isCompleted) return;
      done.completeError(StateError(_geoMessage(error.code)));
    }).toJS,
    web.PositionOptions(enableHighAccuracy: true, timeout: 12000, maximumAge: 0),
  );
  return done.future.timeout(const Duration(seconds: 14));
}

String _geoMessage(int code) {
  if (code == 1) return 'Joylashuvga ruxsat berilmadi';
  if (code == 3) return 'Joylashuvni kutish vaqti tugadi';
  return 'Joylashuvni aniqlab bo\'lmadi';
}
