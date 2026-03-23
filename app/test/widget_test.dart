import 'package:flutter_test/flutter_test.dart';

import 'package:couwang_app/app/app.dart';

void main() {
  testWidgets('app starts on coupon home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CouWangApp());

    expect(find.text('쿠왕'), findsOneWidget);
    expect(find.text('브랜드 또는 제목 검색'), findsOneWidget);
  });
}
