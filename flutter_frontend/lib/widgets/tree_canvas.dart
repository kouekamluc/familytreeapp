import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import '../providers/tree_provider.dart';
import 'monogram_medallion.dart';

class TreeCanvas extends StatefulWidget {
  final List<Person> people;
  final List<Relationship> relationships;
  final Person? selectedPerson;
  final TreeOrientation orientation;
  final Function(Person) onSelectPerson;

  const TreeCanvas({
    super.key,
    required this.people,
    required this.relationships,
    this.selectedPerson,
    this.orientation = TreeOrientation.vertical,
    required this.onSelectPerson,
  });

  @override
  State<TreeCanvas> createState() => _TreeCanvasState();
}

class _TreeCanvasState extends State<TreeCanvas> {
  final TransformationController _transformController = TransformationController();

  static const double cardWidth = 220.0;
  static const double cardHeight = 110.0;
  static const double gapX = 50.0;
  static const double gapY = 100.0;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  void zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale < 2.5) {
      _transformController.value = _transformController.value.scaled(1.25);
    }
  }

  void zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    if (currentScale > 0.3) {
      _transformController.value = _transformController.value.scaled(0.8);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.people.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_tree_outlined, size: 64, color: RoyalTheme.primaryGold),
            const SizedBox(height: 16),
            Text(
              'No Lineage Records Available',
              style: GoogleFonts.cinzel(
                color: RoyalTheme.primaryGold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add members to start weaving your royal family tree.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Compute node coordinates
    final layout = _computeLayout();

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(1200),
          minScale: 0.25,
          maxScale: 2.5,
          child: Container(
            width: layout.totalWidth,
            height: layout.totalHeight,
            padding: const EdgeInsets.all(80),
            child: Stack(
              children: [
                // Vector lines painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TreeBranchPainter(
                      positions: layout.positions,
                      relationships: widget.relationships,
                      orientation: widget.orientation,
                      selectedPersonId: widget.selectedPerson?.id,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
                // Nodes
                for (final person in widget.people)
                  if (layout.positions.containsKey(person.id))
                    Positioned(
                      left: layout.positions[person.id]!.dx,
                      top: layout.positions[person.id]!.dy,
                      child: _buildPersonNode(person),
                    ),
              ],
            ),
          ),
        ),
        // Floating Controls (Zoom in, Zoom out, Reset)
        Positioned(
          bottom: 24,
          right: 24,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? RoyalTheme.surfaceDark.withOpacity(0.9)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: RoyalTheme.borderDark),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: RoyalTheme.brightGold),
                  tooltip: 'Zoom Out',
                  onPressed: zoomOut,
                ),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong, color: RoyalTheme.brightGold),
                  tooltip: 'Reset View',
                  onPressed: resetZoom,
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: RoyalTheme.brightGold),
                  tooltip: 'Zoom In',
                  onPressed: zoomIn,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonNode(Person person) {
    final isSelected = widget.selectedPerson?.id == person.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => widget.onSelectPerson(person),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? RoyalTheme.cardDark : RoyalTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? RoyalTheme.brightGold
                : (person.isAncestor ? RoyalTheme.primaryGold : (isDark ? RoyalTheme.borderDark : RoyalTheme.borderLight)),
            width: isSelected ? 2.5 : (person.isAncestor ? 2.0 : 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? RoyalTheme.brightGold.withOpacity(0.4)
                  : (isDark ? Colors.black45 : Colors.black12),
              blurRadius: isSelected ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MonogramMedallion(
              person: person,
              size: 52,
              isSelected: isSelected,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          person.fullName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (person.isAncestor)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.shield, size: 14, color: RoyalTheme.brightGold),
                        ),
                    ],
                  ),
                  if (person.traditionalName != null && person.traditionalName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        person.traditionalName!,
                        style: GoogleFonts.cinzel(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: RoyalTheme.brightGold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: RoyalTheme.primaryGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Gen ${person.generationTier}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: RoyalTheme.brightGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (person.lifespanText.isNotEmpty)
                        Text(
                          person.lifespanText,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TreeLayoutData _computeLayout() {
    final positions = <int, Offset>{};

    // Group people by generation tier
    final generations = <int, List<Person>>{};
    for (var p in widget.people) {
      final tier = p.generationTier;
      generations.putIfAbsent(tier, () => []).add(p);
    }

    // Sort generation tiers
    final sortedTiers = generations.keys.toList()..sort();

    double maxRowWidth = 0;
    double totalHeight = 0;

    if (widget.orientation == TreeOrientation.vertical) {
      double currentY = 40.0;
      for (final tier in sortedTiers) {
        final rowPeople = generations[tier]!;
        final rowWidth = rowPeople.length * cardWidth + (rowPeople.length - 1) * gapX;
        if (rowWidth > maxRowWidth) maxRowWidth = rowWidth;

        double currentX = 40.0;
        for (final person in rowPeople) {
          positions[person.id] = Offset(currentX, currentY);
          currentX += cardWidth + gapX;
        }
        currentY += cardHeight + gapY;
      }
      totalHeight = currentY + 100;
      maxRowWidth += 120;
    } else {
      // Horizontal orientation (Ancestors on Left, Descendants on Right)
      double currentX = 40.0;
      for (final tier in sortedTiers) {
        final colPeople = generations[tier]!;
        final colHeight = colPeople.length * cardHeight + (colPeople.length - 1) * gapY;
        if (colHeight > totalHeight) totalHeight = colHeight;

        double currentY = 40.0;
        for (final person in colPeople) {
          positions[person.id] = Offset(currentX, currentY);
          currentY += cardHeight + gapY;
        }
        currentX += cardWidth + gapX + 60;
      }
      maxRowWidth = currentX + 120;
      totalHeight += 100;
    }

    return _TreeLayoutData(
      positions: positions,
      totalWidth: math.max(maxRowWidth, 1200.0),
      totalHeight: math.max(totalHeight, 800.0),
    );
  }
}

class _TreeLayoutData {
  final Map<int, Offset> positions;
  final double totalWidth;
  final double totalHeight;

  _TreeLayoutData({
    required this.positions,
    required this.totalWidth,
    required this.totalHeight,
  });
}

class _TreeBranchPainter extends CustomPainter {
  final Map<int, Offset> positions;
  final List<Relationship> relationships;
  final TreeOrientation orientation;
  final int? selectedPersonId;
  final bool isDark;

  _TreeBranchPainter({
    required this.positions,
    required this.relationships,
    required this.orientation,
    this.selectedPersonId,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double cardW = _TreeCanvasState.cardWidth;
    const double cardH = _TreeCanvasState.cardHeight;

    final defaultLinePaint = Paint()
      ..color = isDark ? RoyalTheme.primaryGold.withOpacity(0.4) : RoyalTheme.primaryGold.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final highlightLinePaint = Paint()
      ..color = RoyalTheme.brightGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;

    final spouseLinePaint = Paint()
      ..color = const Color(0xFFE5C07B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    for (final rel in relationships) {
      final pos1 = positions[rel.person1Id];
      final pos2 = positions[rel.person2Id];
      if (pos1 == null || pos2 == null) continue;

      final isHighlighted = selectedPersonId != null &&
          (rel.person1Id == selectedPersonId || rel.person2Id == selectedPersonId);

      if (rel.isSpouse) {
        // Draw spousal connection bar with wedding ring emoji badge
        final p1 = Offset(pos1.dx + cardW, pos1.dy + cardH / 2);
        final p2 = Offset(pos2.dx, pos2.dy + cardH / 2);

        final spousePath = Path();
        spousePath.moveTo(p1.dx, p1.dy);
        spousePath.lineTo(p2.dx, p2.dy);
        canvas.drawPath(spousePath, spouseLinePaint);

        // Draw wedding ring symbol on the link
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        _drawRingBadge(canvas, mid);
      } else if (rel.isParent) {
        // Parent -> Child line
        final path = Path();
        if (orientation == TreeOrientation.vertical) {
          final start = Offset(pos1.dx + cardW / 2, pos1.dy + cardH);
          final end = Offset(pos2.dx + cardW / 2, pos2.dy);

          final ctrl1 = Offset(start.dx, start.dy + (end.dy - start.dy) / 2);
          final ctrl2 = Offset(end.dx, start.dy + (end.dy - start.dy) / 2);

          path.moveTo(start.dx, start.dy);
          path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, end.dx, end.dy);

          canvas.drawPath(path, isHighlighted ? highlightLinePaint : defaultLinePaint);

          // Draw small arrow / badge indicator
          if (isHighlighted) {
            _drawBadge(canvas, Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2), 'Lineage');
          }
        } else {
          final start = Offset(pos1.dx + cardW, pos1.dy + cardH / 2);
          final end = Offset(pos2.dx, pos2.dy + cardH / 2);

          final ctrl1 = Offset(start.dx + (end.dx - start.dx) / 2, start.dy);
          final ctrl2 = Offset(start.dx + (end.dx - start.dx) / 2, end.dy);

          path.moveTo(start.dx, start.dy);
          path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, end.dx, end.dy);

          canvas.drawPath(path, isHighlighted ? highlightLinePaint : defaultLinePaint);
        }
      }
    }
  }

  void _drawRingBadge(Canvas canvas, Offset center) {
    final bgPaint = Paint()..color = const Color(0xFF1E1C18);
    final borderPaint = Paint()
      ..color = RoyalTheme.brightGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 12, bgPaint);
    canvas.drawCircle(center, 12, borderPaint);

    final textPainter = TextPainter(
      text: const TextSpan(text: '💍', style: TextStyle(fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  void _drawBadge(Canvas canvas, Offset center, String text) {
    final bgPaint = Paint()..color = RoyalTheme.surfaceDark;
    final borderPaint = Paint()
      ..color = RoyalTheme.brightGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(fontSize: 9, color: RoyalTheme.brightGold, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

    final rect = Rect.fromCenter(
      center: center,
      width: textPainter.width + 12,
      height: textPainter.height + 6,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TreeBranchPainter oldDelegate) {
    return oldDelegate.selectedPersonId != selectedPersonId ||
        oldDelegate.relationships != relationships ||
        oldDelegate.orientation != orientation ||
        oldDelegate.isDark != isDark;
  }
}
