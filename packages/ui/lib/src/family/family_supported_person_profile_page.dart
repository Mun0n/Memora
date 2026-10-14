import 'package:flutter/material.dart';

import '../l10n/memora_copy.dart';
import '../theme/memora_theme.dart';
import '../widgets/draft_text_field.dart';
import 'family_supported_person_profile_controller.dart';

/// Caregiver supported-person profile area: preferred name for the home greeting.
///
/// Field label is exactly `Nombre que verá en Memora`. Non-primary roles see a
/// read-only or unauthorized state; domain denial remains authoritative.
class FamilySupportedPersonProfilePage extends StatelessWidget {
  const FamilySupportedPersonProfilePage({super.key, required this.controller});

  final FamilySupportedPersonProfileController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        return Column(
          key: const Key('memora-supported-person-profile'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              MemoraCopy.supportedPersonProfileSectionBody,
              style: textTheme.bodyLarge?.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 20),
            if (!controller.canView)
              Text(
                controller.errorMessage ??
                    MemoraCopy.supportedPersonProfileUnauthorized,
                key: const Key('memora-supported-person-profile-denied'),
                style: textTheme.bodyLarge?.copyWith(fontSize: 17),
              )
            else ...[
              if (!controller.canEdit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    MemoraCopy.supportedPersonProfileReadOnly,
                    key: const Key('memora-supported-person-profile-read-only'),
                    style: textTheme.bodyLarge?.copyWith(fontSize: 17),
                  ),
                ),
              DraftTextField(
                key: const Key('memora-preferred-name-field'),
                revision: controller.editorRevision,
                initialText: controller.draftPreferredName,
                onChanged: controller.setDraftPreferredName,
                labelText: MemoraCopy.preferredNameFieldLabel,
                readOnly: !controller.canEdit,
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage!,
                  key: const Key('memora-preferred-name-error'),
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (controller.successMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  controller.successMessage!,
                  key: const Key('memora-preferred-name-saved'),
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MemoraTheme.highContrastInk,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (controller.canEdit)
                FilledButton(
                  key: const Key('memora-preferred-name-save'),
                  onPressed: controller.savePreferredName,
                  child: Text(
                    controller.profile == null
                        ? MemoraCopy.savePreferredName
                        : MemoraCopy.correctPreferredName,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
