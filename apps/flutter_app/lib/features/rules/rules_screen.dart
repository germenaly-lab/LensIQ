import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/localization/app_locale_provider.dart';
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
    final colors = context.colors;
    final adminProv = context.watch<AdminProvider>();
    final rules = adminProv.rules;

    return ResponsiveScaffold(
      currentRoute: '/rules',
      title: 'AI Rules',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openRuleFormDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: Text(context.tr('Add AI Rule')),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
                  label: context.tr('Active Rules'),
                  value: '${adminProv.totalRulesCount}',
                  color: colors.primary,
                  colors: colors,
                ),
                const SizedBox(width: 12),
                _StatPill(
                  label: context.tr('Enabled'),
                  value: '${adminProv.activeRulesCount}',
                  color: colors.success,
                  colors: colors,
                ),
                const SizedBox(width: 12),
                _StatPill(
                  label: 'ROIs',
                  value: '${adminProv.rois.length}',
                  color: colors.secondary,
                  colors: colors,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Rules List
            Expanded(
              child: rules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tune_outlined, size: 48, color: colors.textMuted),
                          const SizedBox(height: 12),
                          Text(context.tr('No data found'), style: TextStyle(color: colors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: rules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final rule = rules[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                            boxShadow: colors.cardShadow,
                          ),
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
                                        ? colors.primary.withOpacity(0.12)
                                        : colors.textMuted.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    rule.enabled ? Icons.auto_awesome : Icons.power_settings_new,
                                    color: rule.enabled ? colors.primary : colors.textMuted,
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
                                          Text(
                                            context.tr(rule.name),
                                            style: AppTypography.h3Of(context).copyWith(fontSize: 16),
                                          ),
                                          const SizedBox(width: 10),
                                          SeverityBadge(severity: rule.severity),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: rule.enabled
                                                  ? colors.success.withOpacity(0.12)
                                                  : colors.textMuted.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              rule.enabled ? context.tr('Active') : context.tr('Inactive'),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: rule.enabled ? colors.success : colors.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${context.tr("Rule Type")}: ${context.tr(rule.ruleTypeDisplayName)} • ${context.tr("Camera")}: ${rule.cameraName} (${rule.branchName})',
                                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                      ),
                                      const SizedBox(height: 12),

                                      // Parameters Row (duration, min people, ROI)
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          _ParamBadge(
                                            icon: Icons.timer_outlined,
                                            label: context.tr('Cooldown (Seconds)'),
                                            value: '${rule.durationSeconds}s',
                                            colors: colors,
                                          ),
                                          _ParamBadge(
                                            icon: Icons.group_outlined,
                                            label: 'Min Occupancy',
                                            value: '${rule.minPeople} persons',
                                            colors: colors,
                                          ),
                                          _ParamBadge(
                                            icon: Icons.crop_square,
                                            label: 'ROI Zone',
                                            value: rule.roiName ?? 'Full Frame',
                                            color: colors.secondary,
                                            colors: colors,
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
                                      activeColor: colors.primary,
                                      onChanged: (_) => adminProv.toggleRuleEnabled(rule.id),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.crop, size: 18, color: colors.textSecondary),
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
                                          icon: Icon(Icons.edit_outlined, size: 18, color: colors.textSecondary),
                                          tooltip: context.tr('Edit AI Rule'),
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
  final AppSemanticColors colors;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
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
  final AppSemanticColors colors;

  const _ParamBadge({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 11, color: colors.textMuted)),
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
    final colors = context.colors;
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
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
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
                widget.initialRule != null
                    ? context.tr('Edit AI Rule')
                    : context.tr('Add AI Rule'),
                style: AppTypography.h3Of(context),
              ),
              const SizedBox(height: 6),
              Text(
                'Configure computer vision parameters for automated event detection.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              Divider(height: 24, color: colors.borderSubtle),
              TextFormField(
                controller: _nameController,
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: context.tr('Rule Name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Rule name required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ruleType,
                      dropdownColor: colors.surfaceElevated,
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: context.tr('Rule Type'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: [
                        DropdownMenuItem(value: 'cashier_empty', child: Text(context.tr('Cashier Area Empty'))),
                        DropdownMenuItem(value: 'perimeter_breach', child: Text(context.tr('Perimeter Breach'))),
                        DropdownMenuItem(value: 'loitering', child: Text(context.tr('Loitering Detected'))),
                        DropdownMenuItem(value: 'occupancy_limit', child: Text(context.tr('Overcrowding Alert'))),
                      ],
                      onChanged: (val) => setState(() => _ruleType = val ?? 'cashier_empty'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<IncidentSeverity>(
                      value: _severity,
                      dropdownColor: colors.surfaceElevated,
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: context.tr('Alert Severity'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: [
                        DropdownMenuItem(value: IncidentSeverity.critical, child: Text(context.tr('Critical'))),
                        DropdownMenuItem(value: IncidentSeverity.warning, child: Text(context.tr('Warning'))),
                        DropdownMenuItem(value: IncidentSeverity.info, child: Text(context.tr('Info'))),
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
                      style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: '${context.tr("Cooldown (Seconds)")} (e.g. 180)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minPeopleController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Min People (e.g. 0)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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
                      dropdownColor: colors.surfaceElevated,
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: context.tr('Camera'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: cameras
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCameraId = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRoiId,
                      dropdownColor: colors.surfaceElevated,
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'ROI Zone',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: rois
                          .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedRoiId = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.tr('Cancel'), style: TextStyle(color: colors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.tr('Save Changes')),
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
