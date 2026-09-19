// 앱 전역 상수 (API 주소, 시그널링 주소 등)
import 'secrets.dart';

class BeeperConstants {
  BeeperConstants._();

  // 백엔드 API 기본 주소 (secrets.dart의 apiBaseUrl)
  static final String apiBaseUrl = _trimTrailingSlash(BeeperSecrets.apiBaseUrl);

  // WebRTC 시그널링 서버 주소 (API 주소에서 생성: http > ws, https > wss)
  static final String signalingUrl = '${apiBaseUrl.replaceFirst('http', 'ws')}/signal';

  static String _trimTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  // API 요청 타임아웃 (연결/수신 공통)
  static const Duration apiTimeout = Duration(seconds: 15);

  // 사용자 유형 값 (백엔드 userType과 동일하게 유지)
  static const String userTypeHelper = 'HELPER';
  static const String userTypeSenior = 'SENIOR';

  // 레이아웃 최대 폭 (웹/데스크톱 중앙 정렬 기준)
  static const double maxContentWidth = 480;

  // TODO: geolocator로 실제 위치 가져오도록 교체
  // 현재는 도움 요청 생성 시 기본 좌표(강남 인근)를 전송함
  static const double defaultLatitude = 37.4979;
  static const double defaultLongitude = 127.0276;

  // 알림 태그 최대 선택 개수
  static const int maxSelectableTags = 10;
}
