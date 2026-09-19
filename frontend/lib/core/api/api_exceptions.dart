// API 호출 예외를 원인별로 구분하는 타입 정의

// 공통 상위 예외 (ApiException으로 한 번에 catch 가능)
sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

// 네트워크 연결 실패, 타임아웃 등 DioException 기반 오류
class NetworkException extends ApiException {
  const NetworkException([super.message = '네트워크 연결을 확인해 주세요.']);
}

// 응답 JSON 파싱 실패
class ParsingException extends ApiException {
  const ParsingException([super.message = '응답을 처리하는 중 문제가 발생했습니다.']);
}

// 인증 만료/실패 (401 또는 resultCode UNAUTHORIZED)
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = '로그인이 만료되었습니다. 다시 로그인해 주세요.']);
}

// 서버가 FAILURE로 응답한 업무 오류 (msg 그대로 노출)
class ServerFailureException extends ApiException {
  const ServerFailureException(super.message);
}
