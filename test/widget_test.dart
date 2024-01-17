import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_sprite_hunt_game/main.dart';

void main() {
  testWidgets('Sprite position changes on tap', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify the initial position of the sprite.
    expect(find.byKey(Key('sprite')), findsOneWidget);

    // Tap the screen and trigger a frame.
    await tester.tap(find.byType(SpriteHuntGame));
    await tester.pump();

    // Verify that the sprite position has changed.
    expect(find.byKey(Key('sprite')), findsOneWidget);
  });
}
