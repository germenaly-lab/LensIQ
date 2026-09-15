import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/localization/app_locale_provider.dart';
import '../../../models/camera.dart';

class AddCameraDialog extends StatefulWidget {
  final Function(CameraModel newCamera) onAdd;

  const AddCameraDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<AddCameraDialog> createState() => _AddCameraDialogState();
}

class _AddCameraDialogState extends State<AddCameraDialog> {
  final _formKey = GlobalKey<FormState>();
  CameraSourceType _sourceType = CameraSourceType.rtsp;
  String _streamProfile = 'main';

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _rtspUrlController = TextEditingController(text: 'rtsp://camera.local:554/live/ch1');
  final _hikDeviceIdController = TextEditingController(text: 'HIK-DS-2CD-NEW');
  final _hikSerialController = TextEditingController(text: 'SERIAL-8891');
  final _hikChannelController = TextEditingController(text: '1');
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'secret_password_123');

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _rtspUrlController.dispose();
    _hikDeviceIdController.dispose();
    _hikSerialController.dispose();
    _hikChannelController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final newCam = CameraModel(
      id: 'cam_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      companyId: '11111111-1111-1111-1111-111111111111',
      brandId: '22222222-2222-2222-2222-222222222222',
      branchId: '33333333-3333-3333-3333-333333333333',
      branchName: 'Ego Mall of Arabia Branch',
      sourceType: _sourceType,
      status: CameraStatus.online,
      locationDescription: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : 'New CCTV Feed',
      rtspUrl: _sourceType == CameraSourceType.rtsp ? _rtspUrlController.text.trim() : null,
      hikDeviceId: _sourceType == CameraSourceType.hikvisionP2p ? _hikDeviceIdController.text.trim() : null,
      hikSerialNumber: _sourceType == CameraSourceType.hikvisionP2p ? _hikSerialController.text.trim() : null,
      hikChannel: _sourceType == CameraSourceType.hikvisionP2p
          ? int.tryParse(_hikChannelController.text.trim()) ?? 1
          : null,
      streamProfile: _streamProfile,
      lastSeenAt: DateTime.now(),
    );

    widget.onAdd(newCam);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add_a_photo_outlined, color: colors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(context.tr('Provision New Camera'), style: AppTypography.h2Of(context)),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: colors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('Register a camera into the enterprise platform. Sensitive credentials are encrypted and stored into the Vault.'),
                  style: AppTypography.captionOf(context),
                ),
                Divider(height: 24, color: colors.border),

                // Source Type Selector Tabs
                Text(context.tr('Video Source Architecture'), style: AppTypography.bodyMediumOf(context)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SourceTypeTab(
                        title: 'RTSP Stream',
                        subtitle: 'Local IP / NVR Feed',
                        icon: Icons.router_outlined,
                        isSelected: _sourceType == CameraSourceType.rtsp,
                        color: AppColors.rtspBadge,
                        onTap: () => setState(() => _sourceType = CameraSourceType.rtsp),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SourceTypeTab(
                        title: 'Hikvision P2P',
                        subtitle: 'Hik-Connect Cloud Relay',
                        icon: Icons.cloud_done_outlined,
                        isSelected: _sourceType == CameraSourceType.hikvisionP2p,
                        color: AppColors.hikvisionBadge,
                        onTap: () => setState(() => _sourceType = CameraSourceType.hikvisionP2p),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // General Information
                Text(context.tr('Camera Details'), style: AppTypography.bodyMediumOf(context)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: context.tr('Camera Name'),
                    hintText: 'e.g. Cashier 02, Drive-Thru Lane 1',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Camera name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: context.tr('Location / Zone Description'),
                    hintText: 'e.g. Counter 2 - Front Checkout Area',
                  ),
                ),
                const SizedBox(height: 18),

                // Source-Specific Configuration Fields
                if (_sourceType == CameraSourceType.rtsp) ...[
                  Text(context.tr('RTSP Connection Settings'), style: AppTypography.bodyMediumOf(context)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _rtspUrlController,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      labelText: 'RTSP Stream URL',
                      hintText: 'rtsp://username:password@ip:554/live/ch1',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'RTSP URL is required' : null,
                  ),
                ] else ...[
                  Text(context.tr('Hikvision P2P Cloud Settings'), style: AppTypography.bodyMediumOf(context)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hikDeviceIdController,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: context.tr('Device Identifier'),
                            hintText: 'e.g. HIK-BAY-4491',
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Device ID is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _hikSerialController,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: context.tr('Serial Number'),
                            hintText: 'e.g. SER-BAY-99182',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _hikChannelController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: context.tr('Channel Number'),
                            hintText: '1',
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n < 1) return 'Must be >= 1';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _streamProfile,
                          dropdownColor: colors.surface,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(labelText: context.tr('Stream Profile')),
                          items: const [
                            DropdownMenuItem(value: 'main', child: Text('Main Stream (1080p)')),
                            DropdownMenuItem(value: 'sub', child: Text('Sub Stream (360p / Bandwidth Saver)')),
                          ],
                          onChanged: (val) => setState(() => _streamProfile = val ?? 'main'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),

                // Credentials Vault Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.success, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('Zero Credential Leakage: Passwords & AppKeys are stored in the secure Vault and never sent to clients.'),
                          style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.tr('Cancel')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(context.tr('Save & Provision Camera')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceTypeTab extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _SourceTypeTab({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : colors.textSecondary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? color : colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? color : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
