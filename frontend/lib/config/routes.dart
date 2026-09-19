// go_router 라우트 정의 및 인증 상태에 따른 리다이렉트 관리
import 'package:go_router/go_router.dart';

import '../core/auth/auth_provider.dart';
import '../features/activities/activities_page.dart';
import '../features/activities/activity_detail_page.dart';
import '../features/auth/helper_login_page.dart';
import '../features/auth/helper_signup_page.dart';
import '../features/helper/help_request_detail_page.dart';
import '../features/helper/helper_dashboard_page.dart';
import '../features/profile/profile_page.dart';
import '../features/senior/help_request_waiting_page.dart';
import '../features/senior/senior_main_page.dart';
import '../features/tags/tag_edit_page.dart';
import '../features/user_select/user_select_page.dart';
import '../features/video_call/helper_video_call_page.dart';
import '../features/video_call/senior_video_call_page.dart';
import 'constants.dart';

// 라우트 경로 상수 (오타 방지용)
class BeeperRoutes {
  BeeperRoutes._();

  static const String userSelect = '/';
  static const String helperLogin = '/helper-login';
  static const String helperSignup = '/helper-signup';
  static const String seniorMain = '/senior-main';
  static const String helpRequestWaiting = '/help-request/waiting';
  static const String helperDashboard = '/helper-dashboard';
  static const String helpRequestDetail = '/help-request/:id';
  static const String videoCallHelper = '/video-call/helper/:roomId';
  static const String videoCallSenior = '/video-call/senior/:roomId';
  static const String profile = '/profile';
  static const String tags = '/tags';
  static const String activities = '/activities';
  static const String activityDetail = '/activities/:id';

  // 봉사자 로그인이 필요한 경로 (비로그인 시 /로 리다이렉트)
  static const Set<String> helperOnly = {
    helperDashboard,
    helpRequestDetail,
    videoCallHelper,
    profile,
    tags,
    activities,
    activityDetail,
  };
}

// AuthProvider 상태에 따라 자동 리다이렉트하는 GoRouter 생성
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: BeeperRoutes.userSelect,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final userType = authProvider.userType;
      // fullPath는 매칭된 라우트 템플릿(예: /help-request/:id)을 반환함
      // matchedLocation을 쓰면 /help-request/waiting이 helperOnly로 잘못 판정됨
      final path = state.fullPath ?? state.matchedLocation;

      final isHelperOnlyRoute = BeeperRoutes.helperOnly.contains(path);

      // 인증이 필요한 페이지에 비로그인 접근 시 사용자 유형 선택으로 이동
      if (!isLoggedIn && isHelperOnlyRoute) {
        return BeeperRoutes.userSelect;
      }

      // 이미 로그인된 상태로 진입/로그인 화면에 있으면 대시보드로 이동
      final isEntryRoute =
          path == BeeperRoutes.userSelect ||
          path == BeeperRoutes.helperLogin ||
          path == BeeperRoutes.helperSignup;

      if (isLoggedIn && isEntryRoute) {
        if (userType == BeeperConstants.userTypeHelper) {
          return BeeperRoutes.helperDashboard;
        }
        if (userType == BeeperConstants.userTypeSenior) {
          return BeeperRoutes.seniorMain;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: BeeperRoutes.userSelect,
        builder: (context, state) => const UserSelectPage(),
      ),
      GoRoute(
        path: BeeperRoutes.helperLogin,
        builder: (context, state) => const HelperLoginPage(),
      ),
      GoRoute(
        path: BeeperRoutes.helperSignup,
        builder: (context, state) => const HelperSignupPage(),
      ),
      GoRoute(
        path: BeeperRoutes.seniorMain,
        builder: (context, state) => const SeniorMainPage(),
      ),
      GoRoute(
        path: BeeperRoutes.helpRequestWaiting,
        builder: (context, state) => HelpRequestWaitingPage(
          args: state.extra is HelpRequestWaitingArgs
              ? state.extra as HelpRequestWaitingArgs
              : null,
        ),
      ),
      GoRoute(
        path: BeeperRoutes.helperDashboard,
        builder: (context, state) => const HelperDashboardPage(),
      ),
      GoRoute(
        path: BeeperRoutes.helpRequestDetail,
        builder: (context, state) =>
            HelpRequestDetailPage(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: BeeperRoutes.videoCallHelper,
        builder: (context, state) => HelperVideoCallPage(
          roomId: state.pathParameters['roomId']!,
          requestId: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: BeeperRoutes.videoCallSenior,
        builder: (context, state) =>
            SeniorVideoCallPage(roomId: state.pathParameters['roomId']!),
      ),
      GoRoute(
        path: BeeperRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: BeeperRoutes.tags,
        builder: (context, state) => const TagEditPage(),
      ),
      GoRoute(
        path: BeeperRoutes.activities,
        builder: (context, state) => const ActivitiesPage(),
      ),
      GoRoute(
        path: BeeperRoutes.activityDetail,
        builder: (context, state) =>
            ActivityDetailPage(activityId: state.pathParameters['id']!),
      ),
    ],
  );
}
