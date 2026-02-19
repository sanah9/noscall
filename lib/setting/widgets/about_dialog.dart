import 'package:flutter/material.dart';
import 'package:noscall/component/icon.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:noscall/utils/modal_dialog.dart';
import 'package:noscall/utils/toast.dart';

class AboutDialog extends StatefulWidget {
  const AboutDialog({super.key});

  static void show(BuildContext context) {
    AppModalDialog.showStandardDialog(
      context: context,
      headerIcon: Icons.info_outline,
      title: 'About',
      content: const AboutDialog(),
    );
  }

  @override
  State<AboutDialog> createState() => _AboutDialogState();
}

class _AboutDialogState extends State<AboutDialog> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  late ThemeData theme;
  Color get primary => theme.colorScheme.primary;
  Color get primaryContainer => theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
  Color get onPrimaryContainer => theme.colorScheme.onPrimaryContainer;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
  Color get borderColor => theme.colorScheme.outline.withValues(alpha: 0.1);

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_packageInfo == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('Failed to load package info'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildVersionSection(),
          Container(
            height: 1,
            color: onSurfaceVariant,
            margin: const EdgeInsets.symmetric(vertical: 20),
          ),
          _buildPackageSection(),
          Container(
            height: 1,
            color: onSurfaceVariant,
            margin: const EdgeInsets.symmetric(vertical: 20),
          ),
          _buildGitHubSection(),
          Container(
            height: 1,
            color: onSurfaceVariant,
            margin: const EdgeInsets.symmetric(vertical: 20),
          ),
          _buildDescriptionSection(),
        ],
      ),
    );
  }

  Widget _buildVersionSection() {
    return _buildInfoItem(
      icon: Icons.info_outline,
      iconColor: Colors.blue.shade700,
      label: 'Version',
      value: 'v${_packageInfo!.version}+${_packageInfo!.buildNumber}',
      isValueBox: true,
    );
  }

  Widget _buildPackageSection() {
    return _buildInfoItem(
      icon: Icons.inventory_2_outlined,
      iconColor: Colors.purple.shade700,
      label: 'Package',
      value: _packageInfo!.packageName,
      isValueBox: true,
    );
  }

  Widget _buildGitHubSection() {
    const githubUrl = 'https://github.com/sanah9/noscall';
    return _buildInfoItem(
      icon: Icons.code,
      iconColor: Colors.green.shade700,
      label: 'GitHub',
      value: githubUrl,
      isValueBox: false,
      isLink: true,
      onTap: () async {
        try {
          final uri = Uri.parse(githubUrl);
          if (await canLaunchUrl(uri)) {
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!launched) {
              AppToast.showError(context, 'Unable to open URL');
            }
          } else {
            AppToast.showError(context, 'Unable to open URL');
          }
        } catch (e) {
          AppToast.showError(context, 'Failed to open URL: $e');
        }
      },
    );
  }

  Widget _buildDescriptionSection() {
    return _buildInfoItem(
      icon: Icons.description_outlined,
      iconColor: Colors.orange.shade700,
      label: 'Description',
      value: 'A secure audio and video calls app built on Nostr',
      isValueBox: false,
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isValueBox,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        SSIcon(
          icon: icon,
          size: 36,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isValueBox)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      value,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: onPrimaryContainer,
                      ),
                    ),
                  )
                else if (isLink)
                  Text(
                    value,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.blue.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  )
                else
                  Text(
                    value,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: onSurface,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}