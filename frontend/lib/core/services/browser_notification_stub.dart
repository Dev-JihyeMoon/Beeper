// dart:html을 쓸 수 없는 플랫폼(Android 등)의 기본 구현 (아무 동작 없음)
// TODO: 포그라운드 시스템 알림은 flutter_local_notifications 같은 별도 패키지가 필요함
// 백그라운드 알림은 Android FCM SDK가 기본 처리
class BrowserNotification {
  static Future<void> show({required String title, String? body}) async {}
}
