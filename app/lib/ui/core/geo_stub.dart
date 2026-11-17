class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

Future<GeoPoint> currentPosition() {
  return Future<GeoPoint>.error(StateError('Joylashuvni aniqlab bo\'lmadi'));
}
