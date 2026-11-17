import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tez_food/main.dart';
import 'package:tez_food/ui/session.dart';

void main() {
  testWidgets('bosh sahifada menyu, kassa va admin bor', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTezApp(SessionModel()));
    expect(find.text('Menyu'), findsOneWidget);
    expect(find.text('Kassa'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Tez, issiq, mazali'), findsOneWidget);
  });
}
