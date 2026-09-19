// FCM 포그라운드 메시지를 활성 화면의 Provider에 전달하는 최소 라우터
// 화면이 살아있는 동안에만 콜백 등록, dispose 시 반드시 해제
// 등록된 화면이 없으면 브라우저/시스템 알림으로 대체
import 'browser_notification.dart';

class FcmEventBus {
  FcmEventBus._();

  static final instance = FcmEventBus._();

  // 봉사자 대시보드 활성 시에만 채워짐 (새 도움 요청 알림 처리)
  void Function(Map<String, dynamic> data)? onHelpRequestCreated;

  // 도움 요청 대기 페이지 활성 시에만 채워짐 (요청 수락 알림 처리)
  void Function(Map<String, dynamic> data)? onHelpRequestAccepted;

  // 요청 마감 알림(HELP_REQUEST_CLOSED) 리스너
  // 대시보드와 상세 페이지가 동시에 살아있을 수 있어 여러 리스너를 허용
  final Set<void Function(Map<String, dynamic> data)> _closedListeners = {};

  void addHelpRequestClosedListener(void Function(Map<String, dynamic> data) listener) {
    _closedListeners.add(listener);
  }

  void removeHelpRequestClosedListener(void Function(Map<String, dynamic> data) listener) {
    _closedListeners.remove(listener);
  }

  // FcmService.listenForegroundMessages에 넘기는 진입점
  // type에 맞는 활성 화면 콜백으로 전달하고, 화면이 없으면 알림으로 대체
  static void routeForegroundMessage(Map<String, dynamic> data) {
    switch (data['type']?.toString()) {
      case 'HELP_REQUEST_CREATED':
        final handler = instance.onHelpRequestCreated;
        if (handler != null) {
          handler(data);
        } else {
          BrowserNotification.show(
            title: data['title']?.toString() ?? '새 도움 요청이 있습니다',
            body: data['description']?.toString(),
          );
        }
      case 'HELP_REQUEST_CLOSED':
        // 마감은 화면 갱신만 필요하므로 활성 화면이 있을 때만 전달
        for (final listener in List.of(instance._closedListeners)) {
          listener(data);
        }
      case 'HELP_REQUEST_ACCEPTED':
        final handler = instance.onHelpRequestAccepted;
        if (handler != null) {
          handler(data);
        } else {
          BrowserNotification.show(
            title: '봉사자가 도움 요청을 수락했습니다',
            body: data['title']?.toString(),
          );
        }
    }
  }
}
