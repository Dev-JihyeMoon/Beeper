// 프로필 페이지 (회원 정보 조회, 수정 진입점, 하단 네비 "프로필" 탭)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/user_service.dart';
import '../../shared/widgets/beeper_button.dart';
import '../../shared/widgets/beeper_card.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../helper/widgets/helper_bottom_nav.dart';
import 'profile_edit_page.dart';
import 'profile_provider.dart';
import 'widgets/user_type_badge.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final phoneNumber = context.read<AuthProvider>().phoneNumber;

    // helperOnly 라우트라 대부분 redirect로 막히지만, 세션 값이 비어있는 예외 상황 방어
    if (phoneNumber == null) {
      return Scaffold(
        backgroundColor: BeeperColors.background,
        body: SafeArea(
          child: ErrorView(
            message: '로그인 정보를 확인할 수 없습니다.',
            onRetry: () => context.go(BeeperRoutes.userSelect),
          ),
        ),
      );
    }

    return ChangeNotifierProvider<ProfileProvider>(
      create: (context) => ProfileProvider(
        userService: UserService(apiClient: context.read<ApiClient>()),
        phoneNumber: phoneNumber,
      ),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  void _handleNavSelect(BuildContext context, HelperNavTab tab) {
    switch (tab) {
      case HelperNavTab.home:
        context.go(BeeperRoutes.helperDashboard);
      case HelperNavTab.activities:
        context.go(BeeperRoutes.activities);
      case HelperNavTab.profile:
        break; // 이미 프로필에 있음
    }
  }

  // 같은 ProfileProvider를 공유하는 화면이라 go_router 경로를 추가하지 않고 Navigator.push 사용
  Future<void> _openEdit(
    BuildContext context,
    ProfileProvider provider,
    UserProfile profile,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<ProfileProvider>.value(
          value: provider,
          child: ProfileEditPage(profile: profile),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: BeeperColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: BeeperConstants.maxContentWidth),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody(context, provider)),
                HelperBottomNav(
                  current: HelperNavTab.profile,
                  onSelect: (tab) => _handleNavSelect(context, tab),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: BeeperSpacing.s16, vertical: BeeperSpacing.s16),
      child: Row(children: [Text('프로필', style: BeeperTypography.headlineMedium)]),
    );
  }

  Widget _buildBody(BuildContext context, ProfileProvider provider) {
    switch (provider.status) {
      case ProfileStatus.loading:
        return const LoadingIndicator();
      case ProfileStatus.error:
        return ErrorView(
          message: provider.loadError ?? '프로필 정보를 불러올 수 없습니다.',
          onRetry: provider.retryLoad,
        );
      case ProfileStatus.loaded:
        final profile = provider.profile;
        if (profile == null) {
          return ErrorView(message: '프로필 정보를 불러올 수 없습니다.', onRetry: provider.retryLoad);
        }
        return _buildProfile(context, provider, profile);
    }
  }

  Widget _buildProfile(BuildContext context, ProfileProvider provider, UserProfile profile) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: BeeperSpacing.s16,
        vertical: BeeperSpacing.s16,
      ),
      children: [
        BeeperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      profile.nickname,
                      style: BeeperTypography.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile.userType != null) UserTypeBadge(userType: profile.userType!),
                ],
              ),
              const SizedBox(height: BeeperSpacing.s24),
              _InfoRow(label: '회원 번호', value: '${profile.id}'),
              _InfoRow(label: '전화번호', value: profile.phoneNumber),
              _InfoRow(
                label: '생년월일',
                value: profile.birthday != null ? _formatDate(profile.birthday!) : '-',
              ),
              _InfoRow(label: '활동 포인트', value: '${profile.point ?? 0}P'),
            ],
          ),
        ),
        const SizedBox(height: BeeperSpacing.s24),
        BeeperButton(
          label: '프로필 수정',
          variant: BeeperButtonVariant.secondary,
          onPressed: () => _openEdit(context, provider, profile),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}.${two(local.month)}.${two(local.day)}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BeeperSpacing.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: BeeperTypography.bodyMedium.copyWith(
                color: BeeperColors.textPrimary.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(child: Text(value, style: BeeperTypography.bodyLarge)),
        ],
      ),
    );
  }
}
