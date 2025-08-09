import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/error/utils/rtl_support.dart';

void main() {
  group('RTLSupport', () {
    group('isRTLLocale', () {
      test('returns true for RTL locales', () {
        expect(RTLSupport.isRTLLocale(const Locale('ar')), isTrue); // Arabic
        expect(RTLSupport.isRTLLocale(const Locale('he')), isTrue); // Hebrew
        expect(RTLSupport.isRTLLocale(const Locale('fa')), isTrue); // Persian
        expect(RTLSupport.isRTLLocale(const Locale('ur')), isTrue); // Urdu
        expect(RTLSupport.isRTLLocale(const Locale('ku')), isTrue); // Kurdish
        expect(RTLSupport.isRTLLocale(const Locale('dv')), isTrue); // Divehi
        expect(RTLSupport.isRTLLocale(const Locale('ps')), isTrue); // Pashto
        expect(RTLSupport.isRTLLocale(const Locale('sd')), isTrue); // Sindhi
      });

      test('returns false for LTR locales', () {
        expect(RTLSupport.isRTLLocale(const Locale('en')), isFalse); // English
        expect(RTLSupport.isRTLLocale(const Locale('vi')), isFalse); // Vietnamese
        expect(RTLSupport.isRTLLocale(const Locale('es')), isFalse); // Spanish
        expect(RTLSupport.isRTLLocale(const Locale('fr')), isFalse); // French
        expect(RTLSupport.isRTLLocale(const Locale('de')), isFalse); // German
        expect(RTLSupport.isRTLLocale(const Locale('ja')), isFalse); // Japanese
        expect(RTLSupport.isRTLLocale(const Locale('ko')), isFalse); // Korean
        expect(RTLSupport.isRTLLocale(const Locale('zh')), isFalse); // Chinese
      });
    });

    group('getTextDirection', () {
      test('returns RTL for RTL locales', () {
        expect(RTLSupport.getTextDirection(const Locale('ar')), equals(TextDirection.rtl));
        expect(RTLSupport.getTextDirection(const Locale('he')), equals(TextDirection.rtl));
        expect(RTLSupport.getTextDirection(const Locale('fa')), equals(TextDirection.rtl));
      });

      test('returns LTR for LTR locales', () {
        expect(RTLSupport.getTextDirection(const Locale('en')), equals(TextDirection.ltr));
        expect(RTLSupport.getTextDirection(const Locale('vi')), equals(TextDirection.ltr));
        expect(RTLSupport.getTextDirection(const Locale('es')), equals(TextDirection.ltr));
      });
    });

    group('getIcon', () {
      testWidgets('returns flipped icons for RTL context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) {
                expect(RTLSupport.getIcon(context, Icons.arrow_back), equals(Icons.arrow_forward));
                expect(RTLSupport.getIcon(context, Icons.arrow_forward), equals(Icons.arrow_back));
                expect(RTLSupport.getIcon(context, Icons.chevron_left), equals(Icons.chevron_right));
                expect(RTLSupport.getIcon(context, Icons.chevron_right), equals(Icons.chevron_left));
                expect(RTLSupport.getIcon(context, Icons.navigate_before), equals(Icons.navigate_next));
                expect(RTLSupport.getIcon(context, Icons.navigate_next), equals(Icons.navigate_before));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('returns same icons for LTR context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                expect(RTLSupport.getIcon(context, Icons.arrow_back), equals(Icons.arrow_back));
                expect(RTLSupport.getIcon(context, Icons.arrow_forward), equals(Icons.arrow_forward));
                expect(RTLSupport.getIcon(context, Icons.chevron_left), equals(Icons.chevron_left));
                expect(RTLSupport.getIcon(context, Icons.chevron_right), equals(Icons.chevron_right));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('returns same icon for non-directional icons', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) {
                expect(RTLSupport.getIcon(context, Icons.home), equals(Icons.home));
                expect(RTLSupport.getIcon(context, Icons.settings), equals(Icons.settings));
                expect(RTLSupport.getIcon(context, Icons.refresh), equals(Icons.refresh));
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('getTextAlign', () {
      testWidgets('flips text alignment for RTL context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) {
                expect(RTLSupport.getTextAlign(context, defaultAlign: TextAlign.left), 
                       equals(TextAlign.right));
                expect(RTLSupport.getTextAlign(context, defaultAlign: TextAlign.right), 
                       equals(TextAlign.left));
                expect(RTLSupport.getTextAlign(context, defaultAlign: TextAlign.start), 
                       equals(TextAlign.start));
                expect(RTLSupport.getTextAlign(context, defaultAlign: TextAlign.end), 
                       equals(TextAlign.end));
                expect(RTLSupport.getTextAlign(context, defaultAlign: TextAlign.center), 
                       equals(TextAlign.center));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('keeps text alignment for LTR context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                expect(RTLSupport.getTextAlign(context, defaultAlign: TextAlign.left), 
                       equals(TextAlign.left));
                expect(RTLSupport.getTextAlign(context, defaultAlign: TextAlign.right), 
                       equals(TextAlign.right));
                expect(RTLSupport.getTextAlign(context, defaultAlign: TextAlign.start), 
                       equals(TextAlign.start));
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('getEdgeInsets', () {
      testWidgets('flips edge insets for RTL context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) {
                final insets = RTLSupport.getEdgeInsets(
                  context,
                  left: 10,
                  top: 20,
                  right: 30,
                  bottom: 40,
                );
                
                expect(insets.left, equals(30.0)); // Flipped from right
                expect(insets.top, equals(20.0));
                expect(insets.right, equals(10.0)); // Flipped from left
                expect(insets.bottom, equals(40.0));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('keeps edge insets for LTR context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                final insets = RTLSupport.getEdgeInsets(
                  context,
                  left: 10,
                  top: 20,
                  right: 30,
                  bottom: 40,
                );
                
                expect(insets.left, equals(10.0));
                expect(insets.top, equals(20.0));
                expect(insets.right, equals(30.0));
                expect(insets.bottom, equals(40.0));
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('getAlignment', () {
      testWidgets('flips alignment for RTL context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) {
                expect(RTLSupport.getAlignment(context, Alignment.centerLeft), 
                       equals(Alignment.centerRight));
                expect(RTLSupport.getAlignment(context, Alignment.centerRight), 
                       equals(Alignment.centerLeft));
                expect(RTLSupport.getAlignment(context, Alignment.topLeft), 
                       equals(Alignment.topRight));
                expect(RTLSupport.getAlignment(context, Alignment.topRight), 
                       equals(Alignment.topLeft));
                expect(RTLSupport.getAlignment(context, Alignment.bottomLeft), 
                       equals(Alignment.bottomRight));
                expect(RTLSupport.getAlignment(context, Alignment.bottomRight), 
                       equals(Alignment.bottomLeft));
                expect(RTLSupport.getAlignment(context, Alignment.center), 
                       equals(Alignment.center));
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('getMainAxisAlignment', () {
      testWidgets('flips main axis alignment for RTL context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) {
                expect(RTLSupport.getMainAxisAlignment(context, MainAxisAlignment.start), 
                       equals(MainAxisAlignment.end));
                expect(RTLSupport.getMainAxisAlignment(context, MainAxisAlignment.end), 
                       equals(MainAxisAlignment.start));
                expect(RTLSupport.getMainAxisAlignment(context, MainAxisAlignment.center), 
                       equals(MainAxisAlignment.center));
                expect(RTLSupport.getMainAxisAlignment(context, MainAxisAlignment.spaceBetween), 
                       equals(MainAxisAlignment.spaceBetween));
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('getCrossAxisAlignment', () {
      testWidgets('flips cross axis alignment for RTL context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) {
                expect(RTLSupport.getCrossAxisAlignment(context, CrossAxisAlignment.start), 
                       equals(CrossAxisAlignment.end));
                expect(RTLSupport.getCrossAxisAlignment(context, CrossAxisAlignment.end), 
                       equals(CrossAxisAlignment.start));
                expect(RTLSupport.getCrossAxisAlignment(context, CrossAxisAlignment.center), 
                       equals(CrossAxisAlignment.center));
                expect(RTLSupport.getCrossAxisAlignment(context, CrossAxisAlignment.stretch), 
                       equals(CrossAxisAlignment.stretch));
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('widget creation helpers', () {
      testWidgets('createRTLText creates text with proper direction', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Builder(
                builder: (context) {
                  return RTLSupport.createRTLText(
                    context,
                    'Test text',
                    style: const TextStyle(fontSize: 16),
                  );
                },
              ),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.data, equals('Test text'));
        expect(textWidget.textDirection, equals(TextDirection.rtl));
      });

      testWidgets('createRTLRow creates row with proper direction', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Builder(
                builder: (context) {
                  return RTLSupport.createRTLRow(
                    context,
                    children: [
                      const Text('Child 1'),
                      const Text('Child 2'),
                    ],
                    mainAxisAlignment: MainAxisAlignment.start,
                  );
                },
              ),
            ),
          ),
        );

        final rowWidget = tester.widget<Row>(find.byType(Row));
        expect(rowWidget.textDirection, equals(TextDirection.rtl));
        expect(rowWidget.mainAxisAlignment, equals(MainAxisAlignment.end)); // Flipped
        expect(rowWidget.children.length, equals(2));
      });

      testWidgets('createRTLColumn creates column with proper direction', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Builder(
                builder: (context) {
                  return RTLSupport.createRTLColumn(
                    context,
                    children: [
                      const Text('Child 1'),
                      const Text('Child 2'),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  );
                },
              ),
            ),
          ),
        );

        final columnWidget = tester.widget<Column>(find.byType(Column));
        expect(columnWidget.textDirection, equals(TextDirection.rtl));
        expect(columnWidget.crossAxisAlignment, equals(CrossAxisAlignment.end)); // Flipped
        expect(columnWidget.children.length, equals(2));
      });

      testWidgets('createRTLIconButton creates icon button with flipped icon', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Builder(
                builder: (context) {
                  return RTLSupport.createRTLIconButton(
                    context,
                    icon: Icons.arrow_back,
                    onPressed: () {},
                  );
                },
              ),
            ),
          ),
        );

        final iconButton = tester.widget<IconButton>(find.byType(IconButton));
        final icon = iconButton.icon as Icon;
        expect(icon.icon, equals(Icons.arrow_forward)); // Flipped for RTL
      });
    });

    group('isRTL', () {
      testWidgets('returns true for RTL context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) {
                expect(RTLSupport.isRTL(context), isTrue);
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('returns false for LTR context', (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                expect(RTLSupport.isRTL(context), isFalse);
                return Container();
              },
            ),
          ),
        );
      });
    });
  });
}