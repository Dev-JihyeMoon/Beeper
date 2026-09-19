// 봉사자 회원가입 페이지 (가입 후 자동 로그인 시도)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/beeper_button.dart';
import '../../shared/widgets/beeper_scaffold.dart';
import '../../shared/widgets/beeper_text_field.dart';

class HelperSignupPage extends StatefulWidget {
  const HelperSignupPage({super.key});

  @override
  State<HelperSignupPage> createState() => _HelperSignupPageState();
}

class _HelperSignupPageState extends State<HelperSignupPage> {
  static final _birthdayFormat = DateFormat('yyyy-MM-dd');

  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _birthday;

  String? _nicknameError;
  String? _phoneError;
  String? _birthdayError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _birthday = picked;
      _birthdayController.text = _birthdayFormat.format(picked);
    });
  }

  bool _validate() {
    final nicknameError = BeeperValidators.nickname(_nicknameController.text.trim());
    final phoneError = BeeperValidators.phoneNumber(_phoneController.text.trim());
    final birthdayError = BeeperValidators.birthday(_birthday);
    final passwordError = BeeperValidators.password(_passwordController.text, minLength: 6);

    setState(() {
      _nicknameError = nicknameError;
      _phoneError = phoneError;
      _birthdayError = birthdayError;
      _passwordError = passwordError;
    });

    return nicknameError == null &&
        phoneError == null &&
        birthdayError == null &&
        passwordError == null;
  }

  Future<void> _submit() async {
    setState(() => _generalError = null);
    if (!_validate()) return;

    final authProvider = context.read<AuthProvider>();
    final phoneNumber = _phoneController.text.trim();
    final password = _passwordController.text;

    try {
      await authProvider.signUp(
        nickname: _nicknameController.text.trim(),
        birthday: _birthday!,
        phoneNumber: phoneNumber,
        password: password,
        userType: BeeperConstants.userTypeHelper,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _generalError = e.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _generalError = '알 수 없는 오류가 발생했습니다.');
      return;
    }

    // 가입 성공 시 자동 로그인 시도, 성공하면 redirect가 대시보드로 이동시킴
    try {
      await authProvider.login(phoneNumber, password);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해 주세요.')),
      );
      context.go(BeeperRoutes.helperLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return BeeperScaffold(
      padding: const EdgeInsets.symmetric(horizontal: BeeperSpacing.s24),
      header: _HelperSignupHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: BeeperSpacing.s24),
          BeeperTextField(
            controller: _nicknameController,
            label: '닉네임',
            hintText: '닉네임을 입력해 주세요',
            errorText: _nicknameError,
          ),
          const SizedBox(height: BeeperSpacing.s16),
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
            controller: _birthdayController,
            label: '생년월일',
            hintText: 'YYYY-MM-DD',
            readOnly: true,
            onTap: _pickBirthday,
            suffixIcon: const Icon(
              Icons.calendar_today_rounded,
              color: BeeperColors.textPrimary,
            ),
            errorText: _birthdayError,
          ),
          const SizedBox(height: BeeperSpacing.s16),
          BeeperTextField(
            controller: _passwordController,
            label: '비밀번호',
            hintText: '6자 이상 입력해 주세요',
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
            label: '회원가입',
            isLoading: isLoading,
            onPressed: isLoading ? null : _submit,
          ),
          const SizedBox(height: BeeperSpacing.s24),
          Center(
            child: GestureDetector(
              onTap: () => context.go(BeeperRoutes.helperLogin),
              child: RichText(
                text: TextSpan(
                  style: BeeperTypography.bodyMedium,
                  children: [
                    const TextSpan(text: '이미 회원이신가요? '),
                    TextSpan(
                      text: '로그인',
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
class _HelperSignupHeader extends StatelessWidget {
  const _HelperSignupHeader();

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
              onPressed: () => context.go(BeeperRoutes.helperLogin),
              icon: const Icon(Icons.arrow_back_rounded, color: BeeperColors.textPrimary),
            ),
          ),
          const SizedBox(width: BeeperSpacing.s8),
          const Text('봉사자 회원가입', style: BeeperTypography.titleLarge),
        ],
      ),
    );
  }
}
