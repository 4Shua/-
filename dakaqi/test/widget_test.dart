import 'package:dakaqi/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows app title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DakaqiApp(),
      ),
    );

    expect(find.text('乱七八糟打卡器'), findsOneWidget);
  });
}
