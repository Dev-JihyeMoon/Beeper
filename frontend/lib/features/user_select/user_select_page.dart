// 사용자 유형 선택 페이지 (서비스 진입점, 요청자/봉사자 흐름 분기)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../shared/widgets/beeper_button.dart';
import '../../shared/widgets/beeper_scaffold.dart';
import '../../shared/widgets/pulse_animation.dart';

class UserSelectPage extends StatelessWidget {
  const UserSelectPage({super.key});

  static const String _repoUrl = 'https://github.com/Dev-JihyeMoon/Beeper';

  @override
  Widget build(BuildContext context) {
    // 하단 안내 문구 (백엔드 중단 안내 + GitHub 링크)
    final noticeStyle = BeeperTypography.labelSmall.copyWith(
      fontSize: 11,
      color: BeeperColors.textPrimary.withValues(alpha: 0.6),
    );

    return BeeperScaffold(
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '※ 상시 비용 문제로 인해 백엔드 인프라 구동이 중지된 상태일 수 있습니다. 양해 바랍니다.',
            textAlign: TextAlign.center,
            style: noticeStyle,
          ),
          const SizedBox(height: 4),
          // 문구 전체를 탭하면 GitHub 저장소로 이동 (주소 부분만 밑줄 표시)
          Semantics(
            link: true,
            label: 'GitHub 저장소 열기',
            child: InkWell(
              onTap: () => launchUrl(
                Uri.parse(_repoUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: Text.rich(
                TextSpan(
                  style: noticeStyle,
                  children: [
                    const TextSpan(text: '※ 구동화면 및 자세한 내용은 ('),
                    TextSpan(
                      text: _repoUrl,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ') 에서 확인 가능합니다.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: BeeperSpacing.s48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 서비스 로고
            Image.asset('assets/images/beeper_logo.png', width: 96, height: 96),
            const SizedBox(height: BeeperSpacing.s16),
            // 서비스명
            const Text('Beeper', style: BeeperTypography.displayLarge),
            const SizedBox(height: BeeperSpacing.s8),
            // 핵심 가치 문구
            Text(
              '도움이 필요할 때 간편하게!',
              style: BeeperTypography.bodyLarge.copyWith(
                color: BeeperColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: BeeperSpacing.s48),
            // 시그널 모티프 펄스 애니메이션
            const PulseAnimation(size: 56),
            const SizedBox(height: BeeperSpacing.s48),
            // 도움 요청하기 (시니어가 가장 먼저 누를 버튼이라 크게)
            Semantics(
              button: true,
              label: '도움 요청하기',
              child: BeeperButton(
                label: '도움 요청하기',
                height: 64,
                onPressed: () => context.go(BeeperRoutes.seniorMain),
              ),
            ),
            const SizedBox(height: BeeperSpacing.s24),
            // 봉사자 로그인 (보조 동선)
            Semantics(
              button: true,
              label: '봉사자로 로그인',
              child: BeeperButton(
                label: '봉사자로 로그인',
                variant: BeeperButtonVariant.secondary,
                onPressed: () => context.go(BeeperRoutes.helperLogin),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
