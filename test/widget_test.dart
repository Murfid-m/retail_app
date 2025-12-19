// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' as mat;

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build a minimal counter widget for testing instead of the full app.
    await tester.pumpWidget(mat.MaterialApp(home: CounterTestWidget()));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(mat.Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

class CounterTestWidget extends StatefulWidget {
  @override
  _CounterTestWidgetState createState() => _CounterTestWidgetState();
}

class _CounterTestWidgetState extends State<CounterTestWidget> {
  int _counter = 0;

  void _increment() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) {
    return mat.Scaffold(
      body: Center(child: Text('$_counter')),
      floatingActionButton: mat.FloatingActionButton(
        onPressed: _increment,
        child: const Icon(mat.Icons.add),
      ),
    );
  }
}
