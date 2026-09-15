import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/ai_rule.dart';
import '../../models/incident.dart';
import '../../providers/admin_provider.dart';
import '../../providers/camera_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/severity_badge.dart';
import '../roi/roi_editor_dialog.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({Key? key}) : super(key: key);

  void _openRuleFormDialog(BuildContext context, {AiRuleModel? rule}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _RuleFormDialog(initialRule: rule),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final rules = adminProv.rules;

    return ResponsiveScaffold(
      currentRoute: '/rules',
      title: 'AI Detection Rules',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openRuleFormDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New Detection Rule'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header stats
            Row(
              children: [
                _StatPill(
                  label: 'Total Rules',
                  value: '${adminProv.totalRulesCount}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _StatPill(
                  label: 'Active Rules',
                  value: '${adminProv.activeRulesCount}',
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                _StatPill(
                  label: 'Configured ROIs',
                  value: '${adminProv.rois.length}',
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Rules List
            Expanded(
              child: rules.isEmpty
                  ? const Center(child: Text('No AI rules configured.'))
                  : ListView.separated(
                      itemCount: rules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final rule = rules[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon & Status
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: rule.enabled
                                        ? AppColors.primary.withOpacity(0.15)
                                        : AppColors.textMuted.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    rule.enabled ? Icons.auto_awesome : Icons.power_settings_new,
                                    color: rule.enabled ? AppColors.primary : AppColors.textMuted,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Main Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(rule.name, style: AppTypography.h3),
                                          const SizedBox(width: 10),
                                          SeverityBadge(severity: rule.severity),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: rule.enabled
                                                  ? AppColors.success.withOpacity(0.15)
                                                  : AppColors.textMuted.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              rule.enabled ? 'ACTIVE' : 'DISABLED',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: rule.enabled ? AppColors.success : AppColors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Type: ${rule.ruleTypeDisplayName} • Camera: ${rule.cameraName} (${rule.branchName})',
                                        style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                                      ),
                                      const SizedBox(height: 12),

                                      // Parameters Row (duration, min people, ROI)
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          _ParamBadge(
                                            icon: Icons.timer_outlined,
                                            label: 'Duration Threshold',
                                            value: '${rule.durationSeconds} seconds',
                                          ),
                                          _ParamBadge(
                                            icon: Icons.group_outlined,
                                            label: 'Min Occupancy',
                                            value: '${rule.minPeople} persons',
                                          ),
                                          _ParamBadge(
                                            icon: Icons.crop_square,
                                            label: 'Target ROI',
                                            value: rule.roiName ?? 'Full Frame',
                                            color: AppColors.secondary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Actions
                                Column(
                                  children: [
                                    Switch(
                                      value: rule.enabled,
                                      onChanged: (_) => adminProv.toggleRuleEnabled(rule.id),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.crop, size: 18),
                                          tooltip: 'Edit ROI Polygon',
                                          onPressed: () {
                                            final roi = adminProv.getRoiById(rule.roiId ?? '');
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => RoiEditorDialog(
                                                cameraName: rule.cameraName,
                                                initialRoi: roi,
                                                onSave: (savedRoi) => adminProv.saveRoi(savedRoi),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          tooltip: 'Edit Rule',
                                          onPressed: () => _openRuleFormDialog(context, rule: rule),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _ParamBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _ParamBadge({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c),
          ),
        ],
      ),
    );
  }
}

class _RuleFormDialog extends StatefulWidget {
  final AiRuleModel? initialRule;

  const _RuleFormDialog({this.initialRule});

  @override
  State<_RuleFormDialog> createState() => _RuleFormDialogState();
}

class _RuleFormDialogState extends State<_RuleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _durationController;
  late TextEditingController _minPeopleController;
  String _ruleType = 'cashier_empty';
  IncidentSeverity _severity = IncidentSeverity.critical;
  String? _selectedCameraId;
  String? _selectedRoiId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialRule?.name ?? '');
    _durationController = TextEditingController(
      text: (widget.initialRule?.durationSeconds ?? 180).toString(),
    );
    _minPeopleController = TextEditingController(
      text: (widget.initialRule?.minPeople ?? 0).toString(),
    );
    if (widget.initialRule != null) {
      _ruleType = widget.initialRule!.ruleType;
      _severity = widget.initialRule!.severity;
      _selectedCameraId = widget.initialRule!.cameraId;
      _selectedRoiId = widget.initialRule!.roiId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _minPeopleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final adminProv = context.read<AdminProvider>();
    final camProv = context.read<CameraProvider>();
    final cameras = camProv.allCameras;

    final cam = cameras.firstWhere(
      (c) => c.id == _selectedCameraId,
      orElse: () => cameras.first,
    );

    final roi = adminProv.rois.firstWhere(
      (r) => r.id == _selectedRoiId,
      orElse: () => adminProv.rois.first,
    );

    final rule = AiRuleModel(
      id: widget.initialRule?.id ?? 'rule_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      ruleType: _ruleType,
      durationSeconds: int.tryParse(_durationController.text.trim()) ?? 180,
      minPeople: int.tryParse(_minPeopleController.text.trim()) ?? 0,
      severity: _severity,
      cameraId: cam.id,
      cameraName: cam.name,
      branchId: cam.branchId,
      branchName: cam.branchName ?? 'Branch',
      roiId: roi.id,
      roiName: roi.name,
      enabled: widget.initialRule?.enabled ?? true,
    );

    if (widget.initialRule != null) {
      adminProv.updateRule(rule);
    } else {
      adminProv.addRule(rule);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final camProv = context.watch<CameraProvider>();
    final cameras = camProv.allCameras;
    final rois = adminProv.rois;

    if (_selectedCameraId == null && cameras.isNotEmpty) {
      _selectedCameraId = cameras.first.id;
    }
    if (_selectedRoiId == null && rois.isNotEmpty) {
      _selectedRoiId = rois.first.id;
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialRule != null ? 'Edit AI Detection Rule' : 'Create AI Detection Rule',
                style: AppTypography.h2,
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure computer vision parameters for automated event detection.',
                style: AppTypography.caption,
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Rule Name'),
                validator: (v) => v == null || v.isEmpty ? 'Rule name required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ruleType,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Rule Type'),
                      items: const [
                        DropdownMenuItem(value: 'cashier_empty', child: Text('Unattended Cashier')),
                        DropdownMenuItem(value: 'perimeter_breach', child: Text('Perimeter Breach')),
                        DropdownMenuItem(value: 'loitering', child: Text('Suspicious Loitering')),
                        DropdownMenuItem(value: 'occupancy_limit', child: Text('Max Occupancy')),
                      ],
                      onChanged: (val) => setState(() => _ruleType = val ?? 'cashier_empty'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<IncidentSeverity>(
                      value: _severity,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Alert Severity'),
                      items: const [
                        DropdownMenuItem(value: IncidentSeverity.critical, child: Text('Critical')),
                        DropdownMenuItem(value: IncidentSeverity.warning, child: Text('Warning')),
                        DropdownMenuItem(value: IncidentSeverity.info, child: Text('Information')),
                      ],
                      onChanged: (val) => setState(() => _severity = val ?? IncidentSeverity.critical),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Duration (Seconds)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minPeopleController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Min People Count'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCameraId,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Target Camera'),
                      items: cameras.map((c) {
                        return DropdownMenuItem(value: c.id, child: Text(c.name));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCameraId = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRoiId,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Target ROI Zone'),
                      items: rois.map((r) {
                        return DropdownMenuItem(value: r.id, child: Text(r.name));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRoiId = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Save Rule'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
