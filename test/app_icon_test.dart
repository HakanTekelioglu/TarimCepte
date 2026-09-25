import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarimcepte/widgets/app_icon.dart';

void main() {
  testWidgets('AppIcon uses the complete bundled icon family', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppIcon(Icons.agriculture_rounded)),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    final span = richText.text as TextSpan;

    expect(span.style?.fontFamily, 'AppMaterialIcons');
    expect(span.text, String.fromCharCode(Icons.agriculture_rounded.codePoint));

    final font = await rootBundle.load(
      'assets/fonts/MaterialIcons-Regular.otf',
    );
    expect(font.lengthInBytes, greaterThan(1000000));
  });
}
