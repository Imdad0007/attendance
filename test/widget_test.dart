import 'package:flutter_test/flutter_test.dart';
import 'package:attendance/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('MyApp renders', (WidgetTester tester) async {
    // Avec GoRouter et Riverpod, on doit entourer par ProviderScope
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // On vérifie juste que l'app démarre (elle affichera probablement le loading ou le login)
    expect(find.byType(MyApp), findsOneWidget);
  });
}
