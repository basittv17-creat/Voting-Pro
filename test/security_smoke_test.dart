import 'package:flutter_test/flutter_test.dart';
import 'package:voting_pro/main.dart';

void main() {
  testWidgets(
    'Voting Pro app starts and shows its Material app',
    (tester) async {
      await tester.pumpWidget(const PosterApp());

      expect(find.byType(PosterApp), findsOneWidget);
      expect(find.text('Voting Pro'), findsOneWidget);
    },
  );
}
