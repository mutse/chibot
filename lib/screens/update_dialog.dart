import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../l10n/app_localizations.dart';

class UpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final String fileName;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.updateFound(latestVersion)),
      content: SingleChildScrollView(child: Text(releaseNotes)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await UpdateService.downloadAndInstall(downloadUrl, fileName);
          },
          child: Text(l10n.updateNow),
        ),
      ],
    );
  }
}
