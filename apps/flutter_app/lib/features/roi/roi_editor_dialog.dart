import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/localization/app_locale_provider.dart';
import '../../../models/roi.dart';

class RoiEditorDialog extends StatefulWidget {
  final RoiPolygon? initialRoi;
  final String cameraName;
  final Function(RoiPolygon savedRoi) onSave;

  const RoiEditorDialog({
    Key? key,
    this.initialRoi,
    required this.cameraName,
    required this.onSave,
  }) : super(key: key);

  @override
  State<RoiEditorDialog> createState() => _RoiEditorDialogState();
}

class _RoiEditorDialogState extends State<RoiEditorDialog> {
  late TextEditingController _nameController;
  late String _zoneType;
  late Color _selectedColor;
  late List<RoiPoint> _points;
  int? _selectedPointIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialRoi?.name ?? 'New Region of Interest');
    _zoneType = widget.initialRoi?.zoneType ?? 'cashier_desk';
    _selectedColor = widget.initialRoi?.color ?? const Color(0xFF00E5FF);
    _points = widget.initialRoi != null
        ? List.from(widget.initialRoi!.points)
        : [
            const RoiPoint(x: 0.2, y: 0.2),
            const RoiPoint(x: 0.8, y: 0.2),
            const RoiPoint(x: 0.8, y: 0.8),
            const RoiPoint(x: 0.2, y: 0.8),
          ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('At least 3 vertices required to form a polygon.'))),
      );
      return;
    }

    final roi = RoiPolygon(
      id: widget.initialRoi?.id ?? 'roi_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      zoneType: _zoneType,
      color: _selectedColor,
      points: _points,
    );

    widget.onSave(roi);
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
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Column(
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
                      child: Icon(Icons.crop_square, color: colors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('ROI Polygon Configuration'), style: AppTypography.h2Of(context)),
                        Text(
                          '${context.tr('Target Camera')}: ${widget.cameraName} • ${context.tr('Tap canvas to add point or drag points')}',
                          style: AppTypography.captionOf(context),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: colors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Canvas & Controls Body
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Interactive Video Frame Canvas
                  Expanded(
                    flex: 5,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                        return GestureDetector(
                          onPanDown: (details) {
                            final localPos = details.localPosition;
                            // Check if hit an existing vertex
                            for (int i = 0; i < _points.length; i++) {
                              final ptOffset = _points[i].toOffset(canvasSize);
                              if ((ptOffset - localPos).distance < 20) {
                                setState(() => _selectedPointIndex = i);
                                return;
                              }
                            }
                            // Else add point
                            setState(() {
                              _points.add(RoiPoint.fromOffset(localPos, canvasSize));
                              _selectedPointIndex = _points.length - 1;
                            });
                          },
                          onPanUpdate: (details) {
                            if (_selectedPointIndex != null &&
                                _selectedPointIndex! < _points.length) {
                              setState(() {
                                _points[_selectedPointIndex!] =
                                    RoiPoint.fromOffset(details.localPosition, canvasSize);
                              });
                            }
                          },
                          onPanEnd: (_) => setState(() => _selectedPointIndex = null),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.border),
                            ),
                            child: Stack(
                              children: [
                                // Background Camera Grid / Feed Simulator
                                CustomPaint(
                                  size: canvasSize,
                                  painter: _CctvGridPainter(),
                                ),
                                // ROI Polygon Drawing
                                CustomPaint(
                                  size: canvasSize,
                                  painter: _RoiPolygonPainter(
                                    points: _points,
                                    color: _selectedColor,
                                    selectedIndex: _selectedPointIndex,
                                  ),
                                ),
                                // Camera HUD Overlay
                                Positioned(
                                  top: 10,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'LIVE SNAPSHOT • ${_points.length} VERTICES',
                                      style: AppTypography.code.copyWith(fontSize: 10, color: Colors.white70),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),

                  // 2. Settings Panel
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameController,
                            style: TextStyle(fontSize: 14, color: colors.textPrimary),
                            decoration: InputDecoration(
                              labelText: context.tr('Zone Name'),
                              hintText: 'e.g. Cashier 01 Active Counter',
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _zoneType,
                            dropdownColor: colors.surface,
                            style: TextStyle(fontSize: 14, color: colors.textPrimary),
                            decoration: InputDecoration(labelText: context.tr('Zone Purpose')),
                            items: const [
                              DropdownMenuItem(value: 'cashier_desk', child: Text('Cashier Counter')),
                              DropdownMenuItem(value: 'backstore_perimeter', child: Text('Restricted Perimeter')),
                              DropdownMenuItem(value: 'fitting_room', child: Text('Fitting Room Zone')),
                              DropdownMenuItem(value: 'queue_area', child: Text('Queue Staging Area')),
                            ],
                            onChanged: (val) => setState(() => _zoneType = val ?? 'cashier_desk'),
                          ),
                          const SizedBox(height: 16),
                          Text(context.tr('Polygon Color'), style: AppTypography.bodyMediumOf(context)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ColorDot(
                                color: const Color(0xFF00E5FF),
                                isSelected: _selectedColor.value == 0xFF00E5FF,
                                onSelect: () => setState(() => _selectedColor = const Color(0xFF00E5FF)),
                              ),
                              const SizedBox(width: 8),
                              _ColorDot(
                                color: const Color(0xFFFF5252),
                                isSelected: _selectedColor.value == 0xFFFF5252,
                                onSelect: () => setState(() => _selectedColor = const Color(0xFFFF5252)),
                              ),
                              const SizedBox(width: 8),
                              _ColorDot(
                                color: const Color(0xFFFFAB00),
                                isSelected: _selectedColor.value == 0xFFFFAB00,
                                onSelect: () => setState(() => _selectedColor = const Color(0xFFFFAB00)),
                              ),
                              const SizedBox(width: 8),
                              _ColorDot(
                                color: const Color(0xFF00E676),
                                isSelected: _selectedColor.value == 0xFF00E676,
                                onSelect: () => setState(() => _selectedColor = const Color(0xFF00E676)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _points = [
                                  const RoiPoint(x: 0.2, y: 0.2),
                                  const RoiPoint(x: 0.8, y: 0.2),
                                  const RoiPoint(x: 0.8, y: 0.8),
                                  const RoiPoint(x: 0.2, y: 0.8),
                                ];
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(context.tr('Reset to Default Box')),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 38),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _points.clear()),
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                            label: Text(context.tr('Clear All Points'), style: const TextStyle(color: AppColors.error)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 38),
                              side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 24, color: colors.border),

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
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(context.tr('Save ROI Polygon')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onSelect;

  const _ColorDot({required this.color, required this.isSelected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
        ),
      ),
    );
  }
}

class _CctvGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    // Draw grid
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Center crosshair
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2 - 15, size.height / 2), Offset(size.width / 2 + 15, size.height / 2), centerPaint);
    canvas.drawLine(Offset(size.width / 2, size.height / 2 - 15), Offset(size.width / 2, size.height / 2 + 15), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoiPolygonPainter extends CustomPainter {
  final List<RoiPoint> points;
  final Color color;
  final int? selectedIndex;

  _RoiPolygonPainter({
    required this.points,
    required this.color,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final offsets = points.map((p) => p.toOffset(size)).toList();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 1; i < offsets.length; i++) {
      path.lineTo(offsets[i].dx, offsets[i].dy);
    }
    if (offsets.length > 2) {
      path.close();
      canvas.drawPath(path, fillPaint);
    }
    canvas.drawPath(path, strokePaint);

    // Draw vertex handles
    for (int i = 0; i < offsets.length; i++) {
      final isSelected = selectedIndex == i;
      final handlePaint = Paint()
        ..color = isSelected ? Colors.white : color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offsets[i], isSelected ? 8 : 6, handlePaint);
      canvas.drawCircle(
        offsets[i],
        isSelected ? 8 : 6,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoiPolygonPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
