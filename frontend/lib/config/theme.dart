// Beeper 디자인 시스템 (색상, 서체, 간격, 반경, 그림자, ThemeData)
import 'package:flutter/material.dart';

// 색상 팔레트 (따뜻하고 차분한 톤)
class BeeperColors {
  BeeperColors._();

  // 전체 배경 (아이보리)
  static const Color background = Color(0xFFF9F5F0);

  // 서브 배경 / 카드 배경 (베이지)
  static const Color surface = Color(0xFFF2EAD3);

  // 포인트/CTA 버튼 배경 전용, 텍스트 색상으로 사용 금지
  static const Color primary = Color(0xFFF4991A);

  // 주 텍스트 및 아이콘 (깊은 그린)
  static const Color textPrimary = Color(0xFF344F1F);

  // 성공 상태
  static const Color success = Color(0xFF4A7A2B);

  // 오류 상태
  static const Color error = Color(0xFFD4553A);

  // 정보 상태 (primary와 구분되는 컬러)
  static const Color info = Color(0xFFC47F17);

  // 오렌지 버튼 위 텍스트 전용
  static const Color onPrimary = Color(0xFFFFFFFF);
}

// 타이포그래피 (시니어 화면은 bodyLarge 이상만 사용)
class BeeperTypography {
  BeeperTypography._();

  // 페이지 대제목
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: BeeperColors.textPrimary,
    height: 1.3,
  );

  // 섹션 제목
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: BeeperColors.textPrimary,
    height: 1.3,
  );

  // 카드 제목
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: BeeperColors.textPrimary,
    height: 1.35,
  );

  // 본문
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: BeeperColors.textPrimary,
    height: 1.5,
  );

  // 보조 텍스트
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: BeeperColors.textPrimary,
    height: 1.5,
  );

  // 캡션, 뱃지 (시니어 화면 사용 금지)
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: BeeperColors.textPrimary,
    height: 1.4,
  );
}

// 간격 체계 (8의 배수만 사용)
class BeeperSpacing {
  BeeperSpacing._();

  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

// 모서리 반경
class BeeperRadius {
  BeeperRadius._();

  // 작은 요소 (뱃지, 칩)
  static const double small = 8;

  // 카드
  static const double card = 16;

  // 버튼, 바텀시트
  static const double button = 24;
}

// 컬러 섀도우 (primary 색상의 옅은 불투명도 사용)
class BeeperShadows {
  BeeperShadows._();

  // 기본 카드 그림자
  static List<BoxShadow> card = [
    BoxShadow(
      color: BeeperColors.primary.withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // 호버/강조 시 그림자
  static List<BoxShadow> cardHover = [
    BoxShadow(
      color: BeeperColors.primary.withValues(alpha: 0.18),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

// 앱 전역 ThemeData 조립
class BeeperTheme {
  BeeperTheme._();

  // 스크롤 물리 통일 (iOS 바운스, Android 오버스크롤 글로우 제거)
  static const ScrollBehavior scrollBehavior = BeeperScrollBehavior();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      platform: TargetPlatform.android, // 플랫폼별 스타일 차이 제거를 위해 고정
      scaffoldBackgroundColor: BeeperColors.background,
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['Noto Sans KR', 'Segoe UI', 'sans-serif'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: BeeperColors.primary,
        primary: BeeperColors.primary,
        onPrimary: BeeperColors.onPrimary,
        surface: BeeperColors.surface,
        error: BeeperColors.error,
      ),
      textTheme: const TextTheme(
        displayLarge: BeeperTypography.displayLarge,
        headlineMedium: BeeperTypography.headlineMedium,
        titleLarge: BeeperTypography.titleLarge,
        bodyLarge: BeeperTypography.bodyLarge,
        bodyMedium: BeeperTypography.bodyMedium,
        labelSmall: BeeperTypography.labelSmall,
      ),
      // 페이지 전환은 Fade/Slide로 통일
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: BeeperColors.background,
        foregroundColor: BeeperColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BeeperColors.primary,
          foregroundColor: BeeperColors.onPrimary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BeeperRadius.button),
          ),
        ),
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}

// 스크롤 물리를 전 플랫폼 동일하게 고정
class BeeperScrollBehavior extends ScrollBehavior {
  const BeeperScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Android 오버스크롤 글로우 제거
    return child;
  }
}
