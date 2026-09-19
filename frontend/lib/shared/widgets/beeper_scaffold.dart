// 공통 레이아웃 (480px 폭 제한, 중앙 정렬, 헤더/본문/하단 버튼 구조)
import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';

// 웹 데스크톱에서도 앱과 같은 폭으로 보이도록 480px로 제한하고 중앙 정렬
class BeeperScaffold extends StatelessWidget {
  const BeeperScaffold({
    super.key,
    required this.body,
    this.header,
    this.bottomBar,
    this.padding = const EdgeInsets.symmetric(horizontal: BeeperSpacing.s16),
    this.scrollable = true,
  });

  // 상단 고정 헤더 (없으면 표시 안 함)
  final Widget? header;

  // 중간 스크롤 본문
  final Widget body;

  // 하단 고정 버튼 영역 (없으면 표시 안 함)
  final Widget? bottomBar;

  final EdgeInsets padding;

  // 본문을 스크롤 가능하게 감쌀지 여부 (이미 스크롤뷰를 포함하면 false)
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = scrollable
        ? SingleChildScrollView(padding: padding, child: body)
        : Padding(padding: padding, child: body);

    return Scaffold(
      backgroundColor: BeeperColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: BeeperConstants.maxContentWidth,
            ),
            child: Column(
              children: [
                ?header,
                Expanded(child: content),
                if (bottomBar != null)
                  Padding(
                    padding: const EdgeInsets.all(BeeperSpacing.s16),
                    child: bottomBar,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
