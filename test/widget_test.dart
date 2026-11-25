
import 'package:flutter_test/flutter_test.dart';
import 'package:item_shop/main.dart' as app;

void main() {
  testWidgets('Aplikasi berhasil dijalankan', (
    WidgetTester tester,
  ) async {
    app.main();

    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
