// 웹은 브라우저 Notification API, 그 외 플랫폼은 아무 동작 없는 기본 구현을 조건부로 선택
export 'browser_notification_stub.dart'
    if (dart.library.html) 'browser_notification_web.dart';
