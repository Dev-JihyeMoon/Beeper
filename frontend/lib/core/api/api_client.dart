// dio 기반 공통 API 클라이언트 (인증 헤더 부착, 401 전역 처리, 예외 래핑)
import 'package:dio/dio.dart';

import '../../config/constants.dart';
import '../storage/secure_storage.dart';
import 'api_exceptions.dart';
import 'api_response.dart';

// 401 / UNAUTHORIZED 발생 시 실행할 콜백 타입 (app.dart에서 주입)
typedef UnauthorizedHandler = Future<void> Function();

// 모든 화면이 공유하는 단일 API 클라이언트 (GET/POST/PUT 전담)
class ApiClient {
  ApiClient({BeeperSecureStorage? storage, Dio? dio})
    : _storage = storage ?? BeeperSecureStorage(),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: BeeperConstants.apiBaseUrl,
              connectTimeout: BeeperConstants.apiTimeout,
              receiveTimeout: BeeperConstants.apiTimeout,
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final resultCode = response.data is Map
              ? response.data['resultCode']?.toString()
              : null;
          if (resultCode == ApiResultCode.unauthorized) {
            _handleUnauthorized();
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _handleUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final BeeperSecureStorage _storage;

  // 세션 초기화 + 로그인 화면 이동 콜백
  UnauthorizedHandler? onUnauthorized;

  bool _handlingUnauthorized = false;

  Future<void> _handleUnauthorized() async {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    try {
      await onUnauthorized?.call();
    } finally {
      _handlingUnauthorized = false;
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromData,
  }) => _request<T>(
    () => _dio.get(path, queryParameters: queryParameters),
    fromData,
  );

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromData,
  }) => _request<T>(
    () => _dio.post(path, data: data, queryParameters: queryParameters),
    fromData,
  );

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromData,
  }) => _request<T>(
    () => _dio.put(path, data: data, queryParameters: queryParameters),
    fromData,
  );

  // 공통 래퍼를 쓰지 않는 엔드포인트 전용 (예: POST /fcm/{userId}/token)
  // 인증 헤더, 401 처리는 동일하게 적용하고 HTTP 2xx 여부로만 성공 판단
  Future<bool> postRaw(String path, {Object? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      final status = response.statusCode;
      return status != null && status >= 200 && status < 300;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      throw NetworkException(_networkMessageFor(e));
    }
  }

  Future<ApiResponse<T>> _request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic json)? fromData,
  ) async {
    Response<dynamic> response;
    try {
      response = await call();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      throw NetworkException(_networkMessageFor(e));
    }

    try {
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const ParsingException();
      }
      final parsed = ApiResponse<T>.fromJson(body, fromData);
      if (parsed.isUnauthorized) {
        throw const UnauthorizedException();
      }
      return parsed;
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      throw const ParsingException();
    }
  }

  // 서버 연결 실패 문구 하단에 붙는 안내
  static const String _infraNotice =
      '(※ 상시 비용 문제로 인해 백엔드 인프라 구동을 잠시 중단한 상태입니다. 양해 바랍니다.)';

  String _networkMessageFor(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.\n$_infraNotice';
      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없습니다. 네트워크 상태를 확인해 주세요.\n$_infraNotice';
      default:
        return '네트워크 오류가 발생했습니다.';
    }
  }
}
