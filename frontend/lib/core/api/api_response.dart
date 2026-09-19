// 서버 공통 응답 래퍼 모델 { "resultCode": "SUCCESS", "msg": "성공", "data": {} }

// 서버가 내려주는 resultCode 값
class ApiResultCode {
  ApiResultCode._();

  static const String success = 'SUCCESS';
  static const String failure = 'FAILURE';
  static const String unauthorized = 'UNAUTHORIZED';
}

// 공통 응답 래퍼 (data 필드만 원하는 타입으로 파싱)
class ApiResponse<T> {
  final String resultCode;
  final String msg;
  final T? data;

  const ApiResponse({required this.resultCode, required this.msg, this.data});

  bool get isSuccess => resultCode == ApiResultCode.success;
  bool get isUnauthorized => resultCode == ApiResultCode.unauthorized;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromData,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      resultCode: json['resultCode']?.toString() ?? ApiResultCode.failure,
      msg: json['msg']?.toString() ?? '',
      data: rawData == null || fromData == null ? null : fromData(rawData),
    );
  }
}
