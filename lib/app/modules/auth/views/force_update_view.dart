import 'dart:io';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../constants/color_constants.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/name_constants.dart';

class ForceUpdateView extends StatefulWidget {
  const ForceUpdateView({super.key});

  @override
  State<ForceUpdateView> createState() => _ForceUpdateViewState();
}

class _ForceUpdateViewState extends State<ForceUpdateView> {
  double progress = 0.0;
  bool isDownloading = false;
  bool isInstalling = false;
  String? savedPath;

  // Platform channel for install packages permission
  static const MethodChannel _channel = MethodChannel('install_permission');

  Future<bool> _checkInstallPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final bool? hasPermission =
          await _channel.invokeMethod('checkPermission');
      return hasPermission ?? false;
    } catch (e) {
      print('Permission check error: $e');
      // If method channel fails, assume we have permission and let system handle it
      return true;
    }
  }

  Future<void> _requestInstallPermission() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('requestPermission');
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  Future<String?> _extractApkIfNeeded(String filePath) async {
    try {
      final lower = filePath.toLowerCase();
      if (!lower.endsWith('.zip')) return filePath;

      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      String? apkPath;
      final dir = File(filePath).parent.path;

      for (final f in archive) {
        if (f.isFile && f.name.toLowerCase().endsWith('.apk')) {
          final out = File('$dir/${f.name}');
          await out.create(recursive: true);
          await out.writeAsBytes(f.content as List<int>);
          apkPath = out.path;
          break;
        }
      }
      return apkPath;
    } catch (e) {
      print('APK extraction error: $e');
      return null;
    }
  }

  Future<void> _startDownloadAndInstall() async {
    final url = authController.forceUpdateUrl.value.trim();
    if (url.isEmpty) {
      _showError("URL not found");
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError("Unable to open browser");
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 6),
      margin: const EdgeInsets.all(16),
    );
  }

  void _showBrowserOption(String url) {
    Get.snackbar(
      'Alternative Download',
      'Tap to download via browser',
      backgroundColor: Colors.orange.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
      onTap: (_) => _openInBrowser(url),
      mainButton: TextButton(
        onPressed: () => _openInBrowser(url),
        child:
            const Text('Open Browser', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Browser launch error: $e');
      _showError('Could not open browser');
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = authController.serverVersion.value;
    final current = kAppVersion;

    return WillPopScope(
      onWillPop: () async => false,
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(color: Colors.transparent),
              ),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: child,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.86,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3E245E),
                        Color(0xFF1E1236),
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 24,
                        spreadRadius: 4,
                        offset: Offset(0, 12),
                      ),
                    ],
                    border: Border.all(
                      width: 1.2,
                      color: const Color(0x55FFFFFF),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              kAppColor,
                              const Color(0xFFDB79FF),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.system_update,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'New Version Available',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current $current • Latest $latest',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isInstalling
                            ? 'Installing… Please wait'
                            : isDownloading
                                ? 'Downloading update…'
                                : 'Please update to continue using the app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (isDownloading || isInstalling)
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: isDownloading &&
                                        progress > 0 &&
                                        progress <= 1
                                    ? progress
                                    : null,
                                minHeight: 8,
                                backgroundColor: Colors.white24,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(kAppColor),
                              ),
                            ),
                            if (isDownloading) ...[
                              const SizedBox(height: 10),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              kAppColor,
                              const Color(0xFFB25CE5),
                            ],
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isDownloading || isInstalling
                              ? null
                              : _startDownloadAndInstall,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    isDownloading
                                        ? Icons.downloading
                                        : isInstalling
                                            ? Icons.install_mobile
                                            : Icons.download_rounded,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  isInstalling
                                      ? 'Installing…'
                                      : isDownloading
                                          ? 'Downloading…'
                                          : 'Download & Install',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
