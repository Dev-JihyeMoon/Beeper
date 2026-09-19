// Flutter Web에서 브라우저 Notification API로 알림 표시
// 관련 화면이 열려 있지 않을 때의 대체 알림 수단
// 조건부 export로만 선택되는 웹 전용 구현이라 dart:html 사용이 의도적임
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class BrowserNotification {
  static Future<void> show({required String title, String? body}) async {
    if (!html.Notification.supported) return;

    var permission = html.Notification.permission;
    if (permission != 'granted' && permission != 'denied') {
      permission = await html.Notification.requestPermission();
    }
    if (permission == 'granted') {
      html.Notification(title, body: body);
    }
  }
}
