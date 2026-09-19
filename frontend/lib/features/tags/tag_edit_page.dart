// 알림 태그 편집 페이지 (검색, 다중 선택, 저장)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/services/tag_service.dart';
import '../../shared/widgets/beeper_button.dart';
import '../../shared/widgets/beeper_text_field.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'tag_edit_provider.dart';
import 'widgets/selectable_tag_chip.dart';

class TagEditPage extends StatelessWidget {
  const TagEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TagEditProvider>(
      create: (context) =>
          TagEditProvider(tagService: TagService(apiClient: context.read<ApiClient>())),
      child: const _TagEditView(),
    );
  }
}

class _TagEditView extends StatefulWidget {
  const _TagEditView();

  @override
  State<_TagEditView> createState() => _TagEditViewState();
}

class _TagEditViewState extends State<_TagEditView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleToggle(TagEditProvider provider, int tagId) {
    final ok = provider.toggleTag(tagId);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('태그는 최대 ${BeeperConstants.maxSelectableTags}개까지 선택할 수 있습니다.')),
      );
    }
  }

  Future<void> _save(TagEditProvider provider) async {
    final success = await provider.save();
    if (!mounted || !success) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TagEditProvider>();

    return Scaffold(
      backgroundColor: BeeperColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BeeperSpacing.s16),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: BeeperSpacing.s8),
              BeeperTextField(
                controller: _searchController,
                hintText: '태그 검색',
                suffixIcon: const Icon(Icons.search_rounded, color: BeeperColors.textPrimary),
                onChanged: provider.status == TagEditStatus.loaded ? provider.updateSearch : null,
              ),
              const SizedBox(height: BeeperSpacing.s16),
              Expanded(child: _buildBody(provider)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: BeeperSpacing.s16),
                child: BeeperButton(
                  label: '저장 (${provider.selectedIds.length}/${BeeperConstants.maxSelectableTags})',
                  isLoading: provider.isSaving,
                  onPressed: provider.status == TagEditStatus.loaded && !provider.isSaving
                      ? () => _save(provider)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BeeperSpacing.s16),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: '뒤로가기',
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: BeeperColors.textPrimary),
            ),
          ),
          const SizedBox(width: BeeperSpacing.s8),
          const Text('알림 태그 편집', style: BeeperTypography.titleLarge),
        ],
      ),
    );
  }

  Widget _buildBody(TagEditProvider provider) {
    switch (provider.status) {
      case TagEditStatus.loading:
        return const LoadingIndicator();
      case TagEditStatus.error:
        return ErrorView(
          message: provider.loadError ?? '태그를 불러오지 못했습니다.',
          onRetry: provider.retryLoad,
        );
      case TagEditStatus.loaded:
        final tags = provider.filteredTags;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: BeeperSpacing.s16),
                  child: Text(
                    provider.saveError!,
                    style: BeeperTypography.bodyMedium.copyWith(color: BeeperColors.error),
                  ),
                ),
              if (tags.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: BeeperSpacing.s32),
                  child: Center(
                    child: Text('검색 결과가 없습니다', style: BeeperTypography.bodyMedium),
                  ),
                )
              else
                Wrap(
                  spacing: BeeperSpacing.s8,
                  runSpacing: BeeperSpacing.s8,
                  children: tags
                      .map(
                        (tag) => SelectableTagChip(
                          label: tag.name,
                          selected: provider.selectedIds.contains(tag.id),
                          onTap: () => _handleToggle(provider, tag.id),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
    }
  }
}
