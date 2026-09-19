// 공통 로딩 UI (primary 스피너 + 선택적 안내 메시지)
import 'package:flutter/material.dart';

import '../../config/theme.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.message,
    this.messageStyle = BeeperTypography.bodyMedium,
  });

  final String? message;

  // 12px/14px 텍스트가 금지된 곳(시니어 화면 등)에서는 bodyLarge로 덮어써서 사용
  final TextStyle messageStyle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(BeeperColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: BeeperSpacing.s16),
            Text(message!, style: messageStyle, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
