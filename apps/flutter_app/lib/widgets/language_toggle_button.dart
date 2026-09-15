import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization/app_locale_provider.dart';
import '../core/theme/app_colors.dart';

class LanguageToggleButton extends StatelessWidget {
  final bool isCompact;

  const LanguageToggleButton({
    Key? key,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<AppLocaleProvider>();
    final colors = context.colors;
    final isAr = localeProvider.isArabic;

    return Tooltip(
      message: isAr ? 'Switch to English' : 'التحويل إلى العربية',
      child: InkWell(
        onTap: () => localeProvider.toggleLanguage(),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: colors.primary.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                size: 14,
                color: colors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                isAr ? 'عربي' : 'EN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
