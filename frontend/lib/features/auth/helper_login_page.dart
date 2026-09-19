// 봉사자 로그인 페이지 (성공 시 라우터 redirect로 대시보드 이동)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/beeper_button.dart';
import '../../shared/widgets/beeper_scaffold.dart';
import '../../shared/widgets/beeper_text_field.dart';

class HelperLoginPage extends StatefulWidget {
  const HelperLoginPage({super.key});

  @override
  State<HelperLoginPage> createState() => _HelperLoginPageState();
}

class _HelperLoginPageState extends State<HelperLoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _phoneError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final phoneError = BeeperValidators.phoneNumber(_phoneController.text.trim());
    final passwordError = BeeperValidators.password(_passwordController.text);
    setState(() {
      _phoneError = phoneError;
      _passwordError = passwordError;
    });
    return phoneError == null && passwordError == null;
  }

  Future<void> _submit() async {
    setState(() => _generalError = null);
    if (!_validate()) return;

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.login(_phoneController.text.trim(), _passwordController.text);
      // 로그인 성공 시 세션 갱신, redirect가 /helper-dashboard로 이동시킴
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _generalError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _generalError = '알 수 없는 오류가 발생했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return BeeperScaffold(
      padding: const EdgeInsets.symmetric(horizontal: BeeperSpacing.s24),
      header: _HelperLoginHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: BeeperSpacing.s24),
          BeeperTextField(
            controller: _phoneController,
            label: '전화번호',
            hintText: '숫자만 입력해 주세요',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 11,
            errorText: _phoneError,
          ),
          const SizedBox(height: BeeperSpacing.s16),
          BeeperTextField(
            controller: _passwordController,
            label: '비밀번호',
            hintText: '비밀번호를 입력해 주세요',
            obscureText: true,
            errorText: _passwordError,
          ),
          if (_generalError != null) ...[
            const SizedBox(height: BeeperSpacing.s16),
            Text(
              _generalError!,
              style: BeeperTypography.labelSmall.copyWith(color: BeeperColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: BeeperSpacing.s24),
          BeeperButton(
            label: '로그인',
            isLoading: isLoading,
            onPressed: isLoading ? null : _submit,
          ),
          const SizedBox(height: BeeperSpacing.s24),
          Center(
            child: GestureDetector(
              onTap: () => context.go(BeeperRoutes.helperSignup),
              child: RichText(
                text: TextSpan(
                  style: BeeperTypography.bodyMedium,
                  children: [
                    const TextSpan(text: '아직 회원이 아니신가요? '),
                    TextSpan(
                      text: '회원가입',
                      style: const TextStyle(
                        color: BeeperColors.info,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: BeeperSpacing.s24),
        ],
      ),
    );
  }
}

// 뒤로가기 + 페이지 제목 헤더
class _HelperLoginHeader extends StatelessWidget {
  const _HelperLoginHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BeeperSpacing.s8,
        vertical: BeeperSpacing.s16,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: '뒤로가기',
            child: IconButton(
              onPressed: () => context.go(BeeperRoutes.userSelect),
              icon: const Icon(Icons.arrow_back_rounded, color: BeeperColors.textPrimary),
            ),
          ),
          const SizedBox(width: BeeperSpacing.s8),
          const Text('봉사자 로그인', style: BeeperTypography.titleLarge),
        ],
      ),
    );
  }
}
