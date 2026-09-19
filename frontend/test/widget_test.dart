// 앱이 크래시 없이 기동되고 초기 화면(사용자 유형 선택)이 뜨는지 확인하는 스모크 테스트
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app.dart';

void main() {
  testWidgets('BeeperApp이 초기 화면(사용자 유형 선택)을 표시한다', (WidgetTester tester) async {
    await tester.pumpWidget(const BeeperApp());
    await tester.pump();

    expect(find.text('Beeper'), findsOneWidget);
    expect(find.text('도움 요청하기'), findsOneWidget);
    expect(find.text('봉사자로 로그인'), findsOneWidget);
  });
}
