// 봉사자 대시보드 (활동 상태, 알림 태그 요약, 대기 요청 목록)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/services/help_request_service.dart';
import '../../core/services/helper_service.dart';
import '../../core/services/tag_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'helper_dashboard_provider.dart';
import 'widgets/availability_toggle_card.dart';
import 'widgets/help_request_card.dart';
import 'widgets/helper_bottom_nav.dart';
import 'widgets/tag_summary_card.dart';

class HelperDashboardPage extends StatelessWidget {
  const HelperDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HelperDashboardProvider>(
      create: (context) => HelperDashboardProvider(
        helperService: HelperService(apiClient: context.read<ApiClient>()),
        helpRequestService: HelpRequestService(apiClient: context.read<ApiClient>()),
        tagService: TagService(apiClient: context.read<ApiClient>()),
      )
        ..loadRequests()
        ..loadTags(),
      child: const _HelperDashboardView(),
    );
  }
}

class _HelperDashboardView extends StatefulWidget {
  const _HelperDashboardView();

  @override
  State<_HelperDashboardView> createState() => _HelperDashboardViewState();
}

class _HelperDashboardViewState extends State<_HelperDashboardView> with WidgetsBindingObserver {
  int _lastToggleErrorVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 앱이 포그라운드로 돌아오면(웹은 탭 복귀) 유실됐을 수 있는 새 요청 재조회
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HelperDashboardProvider>().loadRequests(silent: true);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BeeperColors.background,
        title: const Text('로그아웃 하시겠어요?', style: BeeperTypography.titleLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소', style: BeeperTypography.bodyLarge),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              '로그아웃',
              style: BeeperTypography.bodyLarge.copyWith(color: BeeperColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    context.go(BeeperRoutes.userSelect);
  }

  void _handleMenuSelect(String value) {
    switch (value) {
      case 'profile':
        context.go(BeeperRoutes.profile);
      case 'activities':
        context.go(BeeperRoutes.activities);
      case 'verification':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('준비 중인 기능입니다.')),
        );
      case 'logout':
        _confirmLogout();
    }
  }

  Future<void> _openTagEdit(HelperDashboardProvider provider) async {
    await context.push(BeeperRoutes.tags);
    if (!mounted) return;
    provider.refreshTags();
  }

  void _handleNavSelect(HelperNavTab tab) {
    switch (tab) {
      case HelperNavTab.home:
        break; // 이미 대시보드에 있음
      case HelperNavTab.activities:
        context.go(BeeperRoutes.activities);
      case HelperNavTab.profile:
        context.go(BeeperRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HelperDashboardProvider>();

    // 활동 상태 변경 실패 시 에러 토스트를 한 번만 표시 (버전 카운터로 중복 방지)
    if (provider.toggleErrorVersion != _lastToggleErrorVersion) {
      _lastToggleErrorVersion = provider.toggleErrorVersion;
      final message = provider.toggleErrorMessage;
      if (message != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: BeeperColors.error),
          );
        });
      }
    }

    // bottomNavigationBar 슬롯을 쓰면 body 높이가 0이 되는 문제가 있어
    // 헤더, 본문, 하단 네비를 하나의 Column에 둠 (BeeperScaffold와 동일한 패턴)
    return Scaffold(
      backgroundColor: BeeperColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: BeeperConstants.maxContentWidth),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    color: BeeperColors.primary,
                    onRefresh: provider.refreshRequests,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: BeeperSpacing.s16,
                        vertical: BeeperSpacing.s16,
                      ),
                      children: [
                        AvailabilityToggleCard(
                          isAvailable: provider.isAvailable,
                          isUpdating: provider.isTogglingAvailability,
                          onChanged: (_) => provider.toggleAvailability(),
                        ),
                        const SizedBox(height: BeeperSpacing.s16),
                        TagSummaryCard(
                          tags: provider.tags,
                          isLoading: provider.isLoadingTags,
                          errorMessage: provider.tagsError,
                          onEdit: () => _openTagEdit(provider),
                        ),
                        const SizedBox(height: BeeperSpacing.s24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('대기 중인 요청', style: BeeperTypography.titleLarge),
                            Semantics(
                              button: true,
                              label: '요청 목록 새로고침',
                              child: IconButton(
                                onPressed: provider.isLoadingRequests
                                    ? null
                                    : provider.refreshRequests,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: BeeperColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        _buildRequestsSection(provider),
                      ],
                    ),
                  ),
                ),
                HelperBottomNav(
                  current: HelperNavTab.home,
                  onSelect: _handleNavSelect,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BeeperSpacing.s16,
        vertical: BeeperSpacing.s16,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Beeper', style: BeeperTypography.headlineMedium),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_rounded, color: BeeperColors.textPrimary),
            onSelected: _handleMenuSelect,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('프로필')),
              PopupMenuItem(value: 'activities', child: Text('활동 내역')),
              PopupMenuItem(value: 'verification', child: Text('봉사 인증')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('로그아웃')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection(HelperDashboardProvider provider) {
    if (provider.isLoadingRequests && provider.requests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: BeeperSpacing.s48),
        child: LoadingIndicator(),
      );
    }
    if (provider.requestsError != null && provider.requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: BeeperSpacing.s32),
        child: ErrorView(message: provider.requestsError!, onRetry: provider.refreshRequests),
      );
    }
    if (provider.requests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: BeeperSpacing.s32),
        child: EmptyState(message: '아직 대기 중인 요청이 없습니다'),
      );
    }

    return Column(
      children: [
        const SizedBox(height: BeeperSpacing.s16),
        for (final request in provider.requests)
          Padding(
            padding: const EdgeInsets.only(bottom: BeeperSpacing.s16),
            child: HelpRequestCard(
              request: request,
              onTap: () => context.push('/help-request/${request.id}'),
            ),
          ),
      ],
    );
  }
}
