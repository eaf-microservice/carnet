import 'package:flutter/material.dart';

/// A small utility class that shows a customizable About dialog.
///
/// It's used like: `const AboutMe(...).showCustomAbout(context);`
class AboutMe {
  final String applicationName;
  final String developerName = "Fouad El Azbi";
  final String companyName = "EAF microservice";
  final String companyDomain = "https://eaf-microservice.netlify.app/";
  final String emailCompany = "EAF.microservice@gmail.com";
  final String phoneCompany = "+212 645 994 904";
  final String version;
  final String? legalese;
  final String description;
  final List<Widget>? additionalContent;
  final Widget? logo;
  final Color? backgroundColor;
  final Color? textColor;

  const AboutMe({
    required this.applicationName,
    required this.version,
    required this.description,
    this.legalese,
    this.additionalContent,
    this.logo,
    this.backgroundColor,
    this.textColor,
  });

  /// Shows the dialog. Returns when dismissed.
  Future<void> showCustomAbout(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor:
              backgroundColor ?? Theme.of(context).dialogTheme.backgroundColor,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (logo != null) ...[logo!, const SizedBox(height: 24)],
                  Text(
                    applicationName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "المطور: $developerName",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 16.0,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "الشركة: $companyName\nالموقع: $companyDomain\nالبريد الإلكتروني: $emailCompany\nالهاتف: $phoneCompany",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 14.0,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'النسخة: $version',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: textColor),
                    textAlign: TextAlign.center,
                  ),

                  if (legalese != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      legalese!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (additionalContent != null) ...[
                    const SizedBox(height: 12),
                    ...additionalContent!,
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('اغلاق'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
