import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear_track/auth/auth_widgets.dart';

void main() {
  testWidgets('canceling the password reset dialog closes cleanly', (
    tester,
  ) async {
    var dialogResult = 'pending';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  dialogResult =
                      await showDialog<String>(
                        context: context,
                        builder: (_) => const PasswordResetDialog(
                          initialEmail: 'test@example.com',
                        ),
                      ) ??
                      'cancelled';
                },
                child: const Text('Open dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsNothing);
    expect(dialogResult, 'cancelled');
  });
}
