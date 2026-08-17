import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hivmeet/core/config/constants.dart';
import 'package:hivmeet/core/config/theme/app_theme.dart';
import 'package:hivmeet/core/services/localization_service.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        title: Text(LocalizationService.translate('profile.terms')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Html(
          data: LocalizationService.translate('legal.terms_html'),
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
  'p': Style(
    fontSize: FontSize(16),
    lineHeight: LineHeight(1.6),
    margin: Margins.only(bottom: 12),
  ),
  'li': Style(margin: Margins.only(bottom: 8)),
};
