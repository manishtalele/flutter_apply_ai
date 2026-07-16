import 'package:flutter/material.dart';
import 'package:flutter_apply_ai/core/theme/app_dimensions.dart';
import 'package:flutter_apply_ai/core/utils/signature_formatter.dart';

/// Renders a live preview of the email signature exactly as it will appear in
/// sent emails: line breaks preserved, and detected URLs/emails highlighted as
/// links (via the shared [SignatureFormatter] rules).
class SignaturePreview extends StatelessWidget {
  const SignaturePreview({required this.signature, super.key});

  final String signature;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle = theme.textTheme.bodyMedium ?? const TextStyle();
    final TextStyle linkStyle = baseStyle.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );

    final bool isEmpty = signature.trim().isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'PREVIEW',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXs),
          if (isEmpty)
            Text(
              'Your signature preview appears here.',
              style: baseStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...SignatureFormatter.toLines(signature).map(
              (List<SignatureToken> tokens) => _buildLine(
                tokens,
                baseStyle,
                linkStyle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLine(
    List<SignatureToken> tokens,
    TextStyle baseStyle,
    TextStyle linkStyle,
  ) {
    if (tokens.isEmpty) {
      return const SizedBox(height: 6);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          style: baseStyle,
          children: <InlineSpan>[
            for (int i = 0; i < tokens.length; i++)
              TextSpan(
                text: i == tokens.length - 1
                    ? tokens[i].text
                    : '${tokens[i].text} ',
                style: tokens[i].isLink ? linkStyle : baseStyle,
              ),
          ],
        ),
      ),
    );
  }
}
