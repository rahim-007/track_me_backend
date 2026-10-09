import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/features/habits/data/quotes_data.dart';
import 'package:track_me/features/cashflow/presentation/widgets/cashflow_quote_card.dart';

void main() {
  group('Responsive Quote & Banner Card Layout Tests', () {
    test('Verify all quotes in kHabitQuotes have non-empty text and author', () {
      expect(kHabitQuotes.isNotEmpty, true);
      for (final q in kHabitQuotes) {
        expect(q.quote.trim().isNotEmpty, true);
        expect(q.author.trim().isNotEmpty, true);
      }
    });

    final testWidths = [320.0, 360.0, 392.0, 412.0, 508.0];
    final testScales = [1.0, 1.15, 1.25];

    for (final width in testWidths) {
      for (final scale in testScales) {
        testWidgets('CashFlowQuoteCard renders cleanly with 0 overflows at width $width, scale $scale', (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 800));

          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: const Scaffold(
                  body: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: CashFlowQuoteCard(),
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(CashFlowQuoteCard), findsOneWidget);

          // Cycle through 5 quotes by tapping card to verify layout adapts cleanly
          for (int i = 0; i < 5; i++) {
            await tester.tap(find.byType(CashFlowQuoteCard));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  });
}
