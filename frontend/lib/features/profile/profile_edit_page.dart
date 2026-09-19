// 프로필 수정 페이지 (닉네임, 전화번호, 생년월일, 비밀번호 선택 수정)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/user_profile.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/beeper_button.dart';
import '../../shared/widgets/beeper_text_field.dart';
import 'profile_provider.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final _nicknameController = TextEditingController(text: widget.profile.nickname);
  late final _phoneController = TextEditingController(text: widget.profile.phoneNumber);
  late final _birthdayController = TextEditingController(
    text: _birthday != null ? _birthdayFormat.format(_birthday!) : '',
  );
  final _passwordController = TextEditingController();

  static final _birthdayFormat = DateFormat('yyyy-MM-dd');

  late DateTime? _birthday = widget.profile.birthday?.toLocal();

  String? _nicknameError;
  String? _phoneError;
  String? _birthdayError;
  String? _passwordError;

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
    // 비밀번호는 비워두면 변경하지 않으므로 입력했을 때만 검증
    final password = _passwordController.text;
    final passwordError = password.isEmpty ? null : BeeperValidators.password(password, minLength: 6);
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

  Future<void> _submit(ProfileProvider provider) async {
    if (!_validate()) return;

    final newPhoneNumber = _phoneController.text.trim();
    final newPassword = _passwordController.text;
    final success = await provider.updateProfile(
      nickname: _nicknameController.text.trim(),
      phoneNumber: newPhoneNumber,
      birthday: _birthday!,
      password: newPassword.isEmpty ? null : newPassword,
    );
    if (!mounted || !success) return; // 실패 시 에러는 provider.updateError로 표시

    if (provider.phoneNumberChanged) {
      // 전화번호가 바뀌면 기존 토큰이 무효화되므로 재로그인 안내
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: BeeperColors.background,
          title: const Text('전화번호가 변경되었습니다', style: BeeperTypography.titleLarge),
          content: const Text('보안을 위해 다시 로그인해 주세요.', style: BeeperTypography.bodyLarge),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인', style: BeeperTypography.bodyLarge),
            ),
          ],
        ),
      );
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      context.go(BeeperRoutes.helperLogin);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: BeeperColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BeeperSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: BeeperSpacing.s24),
                    BeeperTextField(
                      controller: _nicknameController,
                      label: '닉네임',
                      errorText: _nicknameError,
                    ),
                    const SizedBox(height: BeeperSpacing.s16),
                    BeeperTextField(
                      controller: _phoneController,
                      label: '전화번호',
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
                      label: '새 비밀번호',
                      hintText: '변경할 때만 입력해 주세요 (6자 이상)',
                      obscureText: true,
                      errorText: _passwordError,
                    ),
                    if (provider.updateError != null) ...[
                      const SizedBox(height: BeeperSpacing.s16),
                      Text(
                        provider.updateError!,
                        style: BeeperTypography.bodyMedium.copyWith(color: BeeperColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: BeeperSpacing.s16),
                child: BeeperButton(
                  label: '저장',
                  isLoading: provider.isUpdating,
                  onPressed: provider.isUpdating ? null : () => _submit(provider),
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
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: BeeperColors.textPrimary),
            ),
          ),
          const SizedBox(width: BeeperSpacing.s8),
          const Text('프로필 수정', style: BeeperTypography.titleLarge),
        ],
      ),
    );
  }
}
