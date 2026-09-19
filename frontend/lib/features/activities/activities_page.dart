// 활동 내역 페이지 (무한 스크롤 목록, 하단 네비 "활동 내역" 탭)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/services/activity_service.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../helper/widgets/helper_bottom_nav.dart';
import 'activities_provider.dart';
import 'widgets/activity_card.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActivitiesProvider>(
      create: (context) =>
          ActivitiesProvider(activityService: ActivityService(apiClient: context.read<ApiClient>())),
      child: const _ActivitiesView(),
    );
  }
}

class _ActivitiesView extends StatefulWidget {
  const _ActivitiesView();

  @override
  State<_ActivitiesView> createState() => _ActivitiesViewState();
}

class _ActivitiesViewState extends State<_ActivitiesView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // 스크롤이 끝에서 200px 이내면 다음 페이지 미리 로드
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<ActivitiesProvider>().loadMore();
    }
  }

  void _handleNavSelect(HelperNavTab tab) {
    switch (tab) {
      case HelperNavTab.home:
        context.go(BeeperRoutes.helperDashboard);
      case HelperNavTab.activities:
        break; // 이미 활동 내역에 있음
      case HelperNavTab.profile:
        context.go(BeeperRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivitiesProvider>();

    return Scaffold(
      backgroundColor: BeeperColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: BeeperConstants.maxContentWidth),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody(provider)),
                HelperBottomNav(current: HelperNavTab.activities, onSelect: _handleNavSelect),
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
      child: Text('활동 내역', style: BeeperTypography.headlineMedium),
    );
  }

  Widget _buildBody(ActivitiesProvider provider) {
    if (provider.isLoading && provider.activities.isEmpty) {
      return const LoadingIndicator();
    }
    if (provider.error != null && provider.activities.isEmpty) {
      return ErrorView(message: provider.error!, onRetry: provider.refresh);
    }
    if (provider.activities.isEmpty) {
      return const EmptyState(message: '아직 활동 내역이 없습니다', icon: Icons.history_rounded);
    }

    final showFooter = provider.isLoadingMore || provider.loadMoreError != null;

    return RefreshIndicator(
      color: BeeperColors.primary,
      onRefresh: provider.refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: BeeperSpacing.s16,
          vertical: BeeperSpacing.s16,
        ),
        itemCount: provider.activities.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.activities.length) {
            return _buildFooter(provider);
          }
          final activity = provider.activities[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: BeeperSpacing.s16),
            child: ActivityCard(
              activity: activity,
              onTap: () => context.push('/activities/${activity.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(ActivitiesProvider provider) {
    if (provider.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BeeperSpacing.s16),
        child: Center(
          child: TextButton(
            onPressed: provider.loadMore,
            child: Text(
              '${provider.loadMoreError} 다시 시도',
              style: const TextStyle(color: BeeperColors.error),
            ),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: BeeperSpacing.s24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(BeeperColors.primary),
          ),
        ),
      ),
    );
  }
}
