// 도움 요청 메인 페이지 (음성으로 요청 후 확인, 제출하는 시니어용 핵심 화면)
// 시니어 접근성 규칙: 텍스트 16px 이상, 버튼 터치 영역 56x56dp 이상, 선택지 최대 2~3개
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/services/analysis_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/help_request_service.dart';
import '../../core/services/speech_service.dart';
import '../../shared/widgets/beeper_button.dart';
import '../../shared/widgets/beeper_card.dart';
import '../../shared/widgets/beeper_scaffold.dart';
import '../../shared/widgets/beeper_text_field.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/pulse_animation.dart';
import 'help_request_waiting_page.dart';
import 'senior_main_provider.dart';

class SeniorMainPage extends StatelessWidget {
  const SeniorMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SeniorMainProvider>(
      create: (context) => SeniorMainProvider(
        speechService: SpeechService(),
        analysisService: context.read<AnalysisService>(),
        helpRequestService: HelpRequestService(apiClient: context.read<ApiClient>()),
        fcmService: context.read<FcmService>(),
      ),
      child: const _SeniorMainView(),
    );
  }
}

class _SeniorMainView extends StatefulWidget {
  const _SeniorMainView();

  @override
  State<_SeniorMainView> createState() => _SeniorMainViewState();
}

class _SeniorMainViewState extends State<_SeniorMainView> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SeniorMainProvider>();

    // submitted 상태가 되면 대기 페이지로 이동 (요청 id/roomId 전달)
    final createdRequest = provider.createdRequest;
    if (provider.status == SeniorMainStatus.submitted &&
        createdRequest != null &&
        !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(
          BeeperRoutes.helpRequestWaiting,
          extra: HelpRequestWaitingArgs(
            requestId: createdRequest.id,
            roomId: createdRequest.roomId,
          ),
        );
      });
    }

    return BeeperScaffold(
      body: Center(child: _buildContent(context, provider)),
    );
  }

  Widget _buildContent(BuildContext context, SeniorMainProvider provider) {
    switch (provider.status) {
      case SeniorMainStatus.idle:
        return _IdleView(onStart: provider.startListening);
      case SeniorMainStatus.listening:
        return _ListeningView(
          recognizedText: provider.recognizedText,
          onStop: provider.stopListeningManually,
        );
      case SeniorMainStatus.processing:
        return const LoadingIndicator(
          message: '요청 내용을 정리하고 있습니다...',
          messageStyle: BeeperTypography.bodyLarge,
        );
      case SeniorMainStatus.confirmation:
        return _ConfirmationView(
          result: provider.analysisResult!,
          onConfirm: provider.submitRequest,
          onRetry: provider.reset,
          onEdit: (title, description) =>
              provider.updateRequestContent(title: title, description: description),
        );
      case SeniorMainStatus.submitting:
        return const LoadingIndicator(
          message: '도움 요청을 보내고 있습니다...',
          messageStyle: BeeperTypography.bodyLarge,
        );
      case SeniorMainStatus.submitted:
        return const LoadingIndicator(
          message: '대기 화면으로 이동하고 있습니다...',
          messageStyle: BeeperTypography.bodyLarge,
        );
      case SeniorMainStatus.error:
        return ErrorView(
          message: provider.errorMessage ?? '알 수 없는 오류가 발생했습니다.',
          onRetry: provider.retry,
        );
    }
  }
}

// idle: 음성 버튼을 눌러 요청을 시작하는 첫 화면
class _IdleView extends StatelessWidget {
  const _IdleView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '버튼을 눌러\n도움이 필요한 내용을 말씀해주세요',
          style: BeeperTypography.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BeeperSpacing.s48),
        _VoiceButton(onTap: onStart),
      ],
    );
  }
}

// listening: 실시간 인식 텍스트 + 중지 버튼
class _ListeningView extends StatelessWidget {
  const _ListeningView({required this.recognizedText, required this.onStop});

  final String recognizedText;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('듣고 있어요', style: BeeperTypography.titleLarge),
        const SizedBox(height: BeeperSpacing.s24),
        const PulseAnimation(size: 56, icon: Icons.mic_rounded),
        const SizedBox(height: BeeperSpacing.s32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BeeperSpacing.s16),
          decoration: BoxDecoration(
            color: BeeperColors.surface,
            borderRadius: BorderRadius.circular(BeeperRadius.card),
          ),
          constraints: const BoxConstraints(minHeight: 80),
          child: Text(
            recognizedText.isEmpty ? '말씀해 주세요...' : recognizedText,
            style: BeeperTypography.bodyLarge,
          ),
        ),
        const SizedBox(height: BeeperSpacing.s32),
        Semantics(
          button: true,
          label: '음성 인식 중지',
          child: BeeperButton(
            label: '중지',
            height: 56,
            variant: BeeperButtonVariant.secondary,
            onPressed: onStop,
          ),
        ),
      ],
    );
  }
}

// confirmation: 분석 결과 확인, 직접 수정, 제출 여부 선택
class _ConfirmationView extends StatefulWidget {
  const _ConfirmationView({
    required this.result,
    required this.onConfirm,
    required this.onRetry,
    required this.onEdit,
  });

  final AnalysisResult result;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;
  final void Function(String title, String description) onEdit;

  @override
  State<_ConfirmationView> createState() => _ConfirmationViewState();
}

class _ConfirmationViewState extends State<_ConfirmationView> {
  late final _titleController = TextEditingController(text: widget.result.title);
  late final _descriptionController = TextEditingController(text: widget.result.description);

  bool _isEditing = false;
  String? _titleError;
  String? _descriptionError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startEditing() {
    _titleController.text = widget.result.title;
    _descriptionController.text = widget.result.description;
    setState(() {
      _isEditing = true;
      _titleError = null;
      _descriptionError = null;
    });
  }

  // 제목, 내용이 비어 있으면 저장하지 않음
  void _saveEditing() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final titleError = title.isEmpty ? '제목을 입력해 주세요.' : null;
    final descriptionError = description.isEmpty ? '내용을 입력해 주세요.' : null;
    if (titleError != null || descriptionError != null) {
      setState(() {
        _titleError = titleError;
        _descriptionError = descriptionError;
      });
      return;
    }

    widget.onEdit(title, description);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _isEditing ? '요청 내용을 수정해 주세요' : '이대로 도움을 요청할까요?',
          style: BeeperTypography.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BeeperSpacing.s24),
        if (_isEditing) ..._buildEditForm() else ..._buildSummary(),
      ],
    );
  }

  List<Widget> _buildSummary() {
    final result = widget.result;

    return [
      BeeperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.title, style: BeeperTypography.titleLarge),
            const SizedBox(height: BeeperSpacing.s8),
            Text(result.description, style: BeeperTypography.bodyLarge),
            if (result.isPassthrough) ...[
              const SizedBox(height: BeeperSpacing.s16),
              Text(
                '음성 인식 결과를 그대로 사용합니다.',
                style: BeeperTypography.bodyLarge.copyWith(color: BeeperColors.info),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: BeeperSpacing.s32),
      BeeperButton(label: '이대로 요청', height: 56, onPressed: widget.onConfirm),
      const SizedBox(height: BeeperSpacing.s16),
      BeeperButton(
        label: '내용 수정',
        height: 56,
        variant: BeeperButtonVariant.secondary,
        icon: Icons.edit_rounded,
        onPressed: _startEditing,
      ),
      const SizedBox(height: BeeperSpacing.s16),
      BeeperButton(
        label: '다시 말하기',
        height: 56,
        variant: BeeperButtonVariant.secondary,
        onPressed: widget.onRetry,
      ),
    ];
  }

  List<Widget> _buildEditForm() {
    return [
      BeeperTextField(
        controller: _titleController,
        label: '제목',
        maxLength: 50,
        errorText: _titleError,
      ),
      const SizedBox(height: BeeperSpacing.s16),
      BeeperTextField(
        controller: _descriptionController,
        label: '내용',
        minLines: 4,
        maxLines: 8,
        keyboardType: TextInputType.multiline,
        errorText: _descriptionError,
      ),
      const SizedBox(height: BeeperSpacing.s32),
      BeeperButton(label: '수정 완료', height: 56, onPressed: _saveEditing),
      const SizedBox(height: BeeperSpacing.s16),
      BeeperButton(
        label: '취소',
        height: 56,
        variant: BeeperButtonVariant.secondary,
        onPressed: () => setState(() => _isEditing = false),
      ),
    ];
  }
}

// 가장 크고 눈에 띄는 음성 입력 버튼 (CTA 색상 원형 + 펄스)
class _VoiceButton extends StatelessWidget {
  const _VoiceButton({required this.onTap});

  final VoidCallback onTap;

  static const double _diameter = 140;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '음성으로 도움 요청하기',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: _diameter,
          height: _diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BeeperColors.primary,
            boxShadow: BeeperShadows.cardHover,
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: BeeperColors.onPrimary,
            size: 64,
          ),
        ),
      ),
    );
  }
}
