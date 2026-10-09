part of '../settings_screen.dart';

class _PlatformDirectoryInfo {
  final Directory directory;
  final String platformName;
  final String displayPath;

  const _PlatformDirectoryInfo({
    required this.directory,
    required this.platformName,
    required this.displayPath,
  });
}
/// data_io.dart - _SettingsScreenState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _DataIoExt on _SettingsScreenState {
  void _showSettingsSavedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsSaved),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showStatusSnackBar(
    BuildContext context, {
    required Widget content,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  void _showSimpleStatusMessage(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    _showStatusSnackBar(
      context,
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
    );
  }

  Widget _buildStatusDetails({
    required String title,
    required List<Widget> details,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        if (details.isNotEmpty) const SizedBox(height: 4),
        ...details,
      ],
    );
  }

  Widget _buildImportFileInfoCard({
    required String fileName,
    required String directoryPath,
    required double fileSizeKb,
    String? sourceLabel,
    String? platformLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            directoryPath,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '文件大小: ${fileSizeKb.toStringAsFixed(1)} KB',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (sourceLabel != null)
            Text(
              '来源: $sourceLabel',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (platformLabel != null)
            Text(
              '平台: $platformLabel',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Future<_PlatformDirectoryInfo> _getChibotDirectory() async {
    if (Platform.isMacOS) {
      final documentsDir = await getApplicationDocumentsDirectory();
      return _PlatformDirectoryInfo(
        directory: Directory('${documentsDir.path}/Chibot'),
        platformName: 'macOS',
        displayPath: '~/Documents/Chibot (macOS)',
      );
    } else if (Platform.isWindows) {
      final documentsDir = await getApplicationDocumentsDirectory();
      return _PlatformDirectoryInfo(
        directory: Directory('${documentsDir.path}/Chibot'),
        platformName: 'Windows',
        displayPath: '%USERPROFILE%/Documents/Chibot (Windows)',
      );
    } else if (Platform.isLinux) {
      final documentsDir = await getApplicationDocumentsDirectory();
      return _PlatformDirectoryInfo(
        directory: Directory('${documentsDir.path}/Chibot'),
        platformName: 'Linux',
        displayPath: '~/Documents/Chibot (Linux)',
      );
    } else if (Platform.isAndroid) {
      return _PlatformDirectoryInfo(
        directory: Directory('/storage/emulated/0/Download/Chibot'),
        platformName: 'Android',
        displayPath: '/storage/emulated/0/Download/Chibot (Android)',
      );
    } else if (Platform.isIOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      return _PlatformDirectoryInfo(
        directory: Directory('${appDocDir.path}/Chibot'),
        platformName: 'iOS',
        displayPath: 'App Documents/Chibot (iOS)',
      );
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    return _PlatformDirectoryInfo(
      directory: Directory('${documentsDir.path}/Chibot'),
      platformName: 'Unknown',
      displayPath: '~/Documents/Chibot',
    );
  }

  bool _isValidSettingsXml(String xmlContent) {
    return xmlContent.trim().isNotEmpty &&
        (xmlContent.contains('<settings') ||
            xmlContent.contains('</settings>'));
  }

  String _buildImportErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('version')) {
      return '导入失败: 配置版本不兼容。此文件来自较新的应用版本。';
    }
    if (message.contains('Invalid')) {
      return '导入失败: 无效的配置文件。文件可能已损坏。';
    }
    return '导入失败: 配置格式错误或不兼容';
  }

  Future<bool> _confirmImportFile(
    BuildContext context, {
    required String fileName,
    required String directoryPath,
    required double fileSizeKb,
    String? sourceLabel,
    String? platformLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('导入配置'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('即将导入配置文件，这将覆盖您当前的所有设置。'),
              const SizedBox(height: 16),
              _buildImportFileInfoCard(
                fileName: fileName,
                directoryPath: directoryPath,
                fileSizeKb: fileSizeKb,
                sourceLabel: sourceLabel,
                platformLabel: platformLabel,
              ),
              const SizedBox(height: 16),
              const Text(
                '确定要继续吗？此操作无法撤销。',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('导入'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _applyImportedSettings(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings, {
    required String xmlContent,
    required List<Widget> successDetails,
  }) async {
    try {
      await unifiedSettings.importSettingsFromXml(xmlContent);
      setState(() {});

      if (!context.mounted) return;
      _showStatusSnackBar(
        context,
        content: _buildStatusDetails(
          title: '✅ 配置导入成功！',
          details: successDetails,
        ),
        backgroundColor: Colors.green,
      );
    } catch (error) {
      debugPrint('Import validation error: $error');
      if (!context.mounted) return;
      _showStatusSnackBar(
        context,
        content: _buildStatusDetails(
          title: '❌ 导入失败',
          details: [
            Text(
              _buildImportErrorMessage(error),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _exportSettings(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) async {
    try {
      // 强制同步最新模型到 ModelRegistry
      await unifiedSettings.syncModelsToRegistry();
      debugPrint('Starting export process...');
      final xmlContent = await unifiedSettings.exportSettingsToXml();
      debugPrint('XML content generated: ${xmlContent.length} characters');
      final directoryInfo = await _getChibotDirectory();
      final exportDir = directoryInfo.directory;

      // Create directory if it doesn't exist
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
        debugPrint('Created directory: ${exportDir.path}');
      }

      // Generate filename with timestamp
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'chibot_config_$timestamp.xml';
      final filePath = '${exportDir.path}/$fileName';

      debugPrint('Saving to: $filePath');

      // Write the file
      final file = File(filePath);
      await file.writeAsString(xmlContent);
      debugPrint('File written successfully');

      if (context.mounted) {
        _showStatusSnackBar(
          context,
          content: _buildStatusDetails(
            title: '✅ 配置导出成功！',
            details: [
              Text('文件: $fileName', style: const TextStyle(fontSize: 12)),
              Text(
                '位置: ${exportDir.path}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '平台: ${directoryInfo.platformName}',
                style: const TextStyle(fontSize: 10, color: Colors.white60),
              ),
              Text(
                '文件大小: ${(xmlContent.length / 1024).toStringAsFixed(2)} KB',
                style: const TextStyle(fontSize: 10, color: Colors.white60),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
        );
        // 导出后刷新模型数据
        setState(() {});
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (context.mounted) {
        String errorTitle = '导出失败';
        String errorMessage = e.toString();

        // Provide more helpful error messages
        if (e is FileSystemException) {
          errorTitle = '文件系统错误';
          if (e.message.contains('Permission denied')) {
            errorMessage = '权限不足: 无法写入该目录。请检查存储权限。';
          } else if (e.message.contains('No space')) {
            errorMessage = '磁盘空间不足。请清理存储空间。';
          } else {
            errorMessage = '文件操作失败: ${e.message}';
          }
        }

        _showStatusSnackBar(
          context,
          content: _buildStatusDetails(
            title: '❌ $errorTitle',
            details: [Text(errorMessage, style: const TextStyle(fontSize: 12))],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        );
      }
    }
  }

  void _showImportOptions(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.file_download, color: Colors.green),
              SizedBox(width: 8),
              Text('导入配置选项'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('请选择导入配置的方式：'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.folder, color: Colors.blue),
                title: const Text('从平台目录导入'),
                subtitle: FutureBuilder<_PlatformDirectoryInfo>(
                  future: _getChibotDirectory(),
                  builder: (context, snapshot) {
                    return Text(snapshot.data?.displayPath ?? '加载中...');
                  },
                ),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _importSettings(context, unifiedSettings);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.file_open, color: Colors.orange),
                title: const Text('手动选择文件'),
                subtitle: const Text('浏览文件系统选择配置文件'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _importSettingsFromFilePicker(context, unifiedSettings);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importSettingsFromFilePicker(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) async {
    try {
      debugPrint('Starting file picker import...');

      // Use file picker to select XML config file
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Chibot配置文件',
        extensions: <String>['xml'],
        mimeTypes: <String>['text/xml', 'application/xml'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
        initialDirectory: await _getInitialDirectory(),
      );

      if (file == null) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '未选择文件',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }

      // Validate file name pattern
      final fileName = path.basename(file.path);
      if (!fileName.contains('chibot_config_') || !fileName.endsWith('.xml')) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '文件名格式不正确。期望: chibot_config_*.xml，实际: $fileName',
            backgroundColor: Colors.red,
          );
        }
        return;
      }

      // Read and validate the file content
      final xmlContent = await file.readAsString();
      debugPrint(
        'XML content read: ${xmlContent.length} characters from $fileName',
      );

      if (!_isValidSettingsXml(xmlContent)) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '无效的配置文件格式',
            backgroundColor: Colors.red,
          );
        }
        return;
      }

      // Show confirmation dialog
      if (!context.mounted) return;
      final confirmed = await _confirmImportFile(
        context,
        fileName: fileName,
        directoryPath: path.dirname(file.path),
        fileSizeKb: xmlContent.length / 1024,
        sourceLabel: '文件选择器',
      );

      if (!context.mounted) return;
      if (confirmed) {
        debugPrint('User confirmed file picker import');
        await _applyImportedSettings(
          context,
          unifiedSettings,
          xmlContent: xmlContent,
          successDetails: [
            Text('来源: $fileName', style: const TextStyle(fontSize: 12)),
            const Text(
              '方式: 文件选择器',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        );
      } else {
        debugPrint('User cancelled file picker import');
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '导入已取消',
            backgroundColor: Colors.orange,
          );
        }
      }
    } catch (e) {
      debugPrint('File picker import error: $e');
      if (context.mounted) {
        _showStatusSnackBar(
          context,
          content: _buildStatusDetails(
            title: '❌ 导入失败',
            details: [
              Text(
                e is FileSystemException
                    ? '文件操作失败: ${e.message}'
                    : '导入失败: ${e.toString()}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        );
      }
    }
  }

  Future<String?> _getInitialDirectory() async {
    try {
      final directoryInfo = await _getChibotDirectory();
      if (await directoryInfo.directory.exists()) {
        return directoryInfo.directory.path;
      }
      if (Platform.isAndroid) {
        return '/storage/emulated/0/Download';
      }
      final documentsDir = await getApplicationDocumentsDirectory();
      return documentsDir.path;
    } catch (e) {
      debugPrint('Error getting initial directory: $e');
    }
    return null;
  }

  Future<void> _importSettings(
    BuildContext context,
    UnifiedSettingsProvider unifiedSettings,
  ) async {
    try {
      debugPrint('Starting import process...');
      final directoryInfo = await _getChibotDirectory();
      final importDir = directoryInfo.directory;

      // Check if directory exists
      if (!await importDir.exists()) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '未找到配置目录: ${importDir.path}',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }

      // Find all chibot_config_*.xml files
      final List<FileSystemEntity> files = await importDir.list().toList();
      final List<File> configFiles = [];

      for (final entity in files) {
        if (entity is File &&
            entity.path.contains('chibot_config_') &&
            entity.path.endsWith('.xml')) {
          configFiles.add(entity);
        }
      }

      // Sort files by modification time (newest first)
      configFiles.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      if (configFiles.isEmpty) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '在 ${importDir.path} 中未找到配置文件',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }

      // If multiple files found, show selection dialog
      File selectedFile;
      if (configFiles.length == 1) {
        selectedFile = configFiles.first;
      } else {
        // Show file selection dialog
        if (!context.mounted) return;
        final selectedIndex = await showDialog<int>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.folder_open, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('选择配置文件'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('找到 ${configFiles.length} 个配置文件:'),
                    const SizedBox(height: 12),
                    ...configFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      final fileName = path.basename(file.path);
                      final fileSize = (file.lengthSync() / 1024)
                          .toStringAsFixed(1);
                      final modifiedTime = DateTime.fromMillisecondsSinceEpoch(
                        file.lastModifiedSync().millisecondsSinceEpoch,
                      );
                      final timeString =
                          '${modifiedTime.year}-${modifiedTime.month.toString().padLeft(2, '0')}-${modifiedTime.day.toString().padLeft(2, '0')} ${modifiedTime.hour.toString().padLeft(2, '0')}:${modifiedTime.minute.toString().padLeft(2, '0')}';

                      return ListTile(
                        leading: const Icon(Icons.description),
                        title: Text(fileName),
                        subtitle: Text('大小: $fileSize KB | 修改时间: $timeString'),
                        onTap: () => Navigator.of(dialogContext).pop(index),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(-1),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );

        if (selectedIndex == null || selectedIndex == -1) {
          if (context.mounted) {
            _showSimpleStatusMessage(
              context,
              message: '导入已取消',
              backgroundColor: Colors.orange,
            );
          }
          return;
        }
        selectedFile = configFiles[selectedIndex];
      }

      // Read and validate the selected file
      final xmlContent = await selectedFile.readAsString();
      debugPrint(
        'XML content read: ${xmlContent.length} characters from ${path.basename(selectedFile.path)}',
      );

      // Validate XML content
      if (!_isValidSettingsXml(xmlContent)) {
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '无效的配置文件格式',
            backgroundColor: Colors.red,
          );
        }
        return;
      }

      // Show confirmation dialog with file info
      if (!context.mounted) return;
      final confirmed = await _confirmImportFile(
        context,
        fileName: path.basename(selectedFile.path),
        directoryPath: path.dirname(selectedFile.path),
        fileSizeKb: xmlContent.length / 1024,
        platformLabel: directoryInfo.platformName,
      );

      if (!context.mounted) return;
      if (confirmed) {
        debugPrint('User confirmed import');
        await _applyImportedSettings(
          context,
          unifiedSettings,
          xmlContent: xmlContent,
          successDetails: [
            Text(
              '来源: ${path.basename(selectedFile.path)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '位置: ${path.dirname(selectedFile.path)}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      } else {
        debugPrint('User cancelled import');
        if (context.mounted) {
          _showSimpleStatusMessage(
            context,
            message: '导入已取消',
            backgroundColor: Colors.orange,
          );
        }
      }
    } catch (e) {
      debugPrint('Import error: $e');
      if (context.mounted) {
        _showStatusSnackBar(
          context,
          content: _buildStatusDetails(
            title: '❌ 导入失败',
            details: [
              Text(
                e is FileSystemException
                    ? '文件操作失败: ${e.message}'
                    : '导入失败: ${e.toString()}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        );
      }
    }
  }
}
