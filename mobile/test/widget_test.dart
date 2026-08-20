import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:speciestrace_mobile/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NeuralPatrolApp());
    await tester.pump();
    expect(find.text('NEURAL PATROL'), findsWidgets);
  });
}
