import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_supported_person_typography.dart';
import '../theme/memora_theme.dart';

/// Honest placeholder destination — never simulates activity or call success.
class UserPlaceholderPage extends StatelessWidget {
  const UserPlaceholderPage({
    super.key,
    required this.title,
    required this.body,
    required this.contentKey,
  });

  final String title;
  final String body;
  final Key contentKey;

  factory UserPlaceholderPage.pasatiempos({Key? key}) {
    return UserPlaceholderPage(
      key: key,
      title: MemoraCopy.pasatiemposTitle,
      body: MemoraCopy.pasatiemposBody,
      contentKey: const Key('memora-user-pasatiempos'),
    );
  }

  factory UserPlaceholderPage.quieroHablar({Key? key}) {
    return UserPlaceholderPage(
      key: key,
      title: MemoraCopy.quieroHablarTitle,
      body: MemoraCopy.quieroHablarBody,
      contentKey: const Key('memora-user-quiero-hablar'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      key: contentKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            color: MemoraTheme.highContrastInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          body,
          style: textTheme.bodyLarge?.copyWith(
            color: MemoraTheme.highContrastInk,
            fontSize: MemoraSupportedPersonTypography.body,
            height: MemoraSupportedPersonTypography.bodyHeight,
          ),
        ),
      ],
    );
  }
}
