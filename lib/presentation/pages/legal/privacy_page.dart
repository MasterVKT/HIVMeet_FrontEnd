import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        title: Text(LocalizationService.translate('profile.privacy_policy')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Html(
          data: LocalizationService.translate('legal.privacy_html'),
          style: _htmlStyle,
        ),
      ),
    );
  }
}

final Map<String, Style> _htmlStyle = {
  'h1': Style(
    fontSize: FontSize(24),
    fontWeight: FontWeight.bold,
    margin: Margins.only(bottom: 16),
  ),
  'h2': Style(
    fontSize: FontSize(20),
    fontWeight: FontWeight.bold,
    margin: Margins.only(top: 16, bottom: 8),
  ),
  'h3': Style(
    fontSize: FontSize(18),
    fontWeight: FontWeight.w600,
    margin: Margins.only(top: 12, bottom: 6),
  ),
  'p': Style(
    fontSize: FontSize(16),
    lineHeight: LineHeight(1.6),
    margin: Margins.only(bottom: 12),
  ),
  'li': Style(margin: Margins.only(bottom: 8)),
};
