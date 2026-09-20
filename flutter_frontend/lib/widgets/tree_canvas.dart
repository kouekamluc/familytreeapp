import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import '../providers/tree_provider.dart';
import '../utils/genealogy_helper.dart';
import 'monogram_medallion.dart';

enum TreeLayoutMode { pedigree, tiered }

class TreeCanvas extends StatefulWidget {
  final List<Person> people;
  final List<Relationship> relationships;
  final Person? selectedPerson;
  final TreeOrientation orientation;
  final TreeLayoutMode layoutMode;
  final String searchQuery;
  final Function(Person) onSelectPerson;

  const TreeCanvas({
    super.key,
    required this.people,
    required this.relationships,
    this.selectedPerson,
    this.orientation = TreeOrientation.vertical,
    this.layoutMode = TreeLayoutMode.pedigree,
    this.searchQuery = '',
    required this.onSelectPerson,
  });

  @override
  State<TreeCanvas> createState() => _TreeCanvasState();
}

class _TreeCanvasState extends State<TreeCanvas> with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _matrixAnimation;
  int? _hoveredPersonId;
  int? _internalTappedPersonId;
  Offset? _lastDoubleTapFocalPoint;

  static const double cardWidth = 244.0;
  static const double cardHeight = 98.0;
  static const double gapSpouse = 82.0; // Room for "💍 Married" pill badge
  static const double gapBranch = 68.0;
  static const double gapVertical = 118.0; // Room for "🌿 Children / Lineage" badge

  bool _initializedFit = false;
  int _lastPeopleCount = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onAnimationUpdate() {
    if (_matrixAnimation != null) {
      _transformController.value = _matrixAnimation!.value;
    }
  }

  void _animateToMatrix(
    Matrix4 targetMatrix, {
    Duration duration = const Duration(milliseconds: 420),
    Curve curve = Curves.easeOutCubic,
  }) {
    if (!mounted) return;
    _animController.stop();
    _animController.duration = duration;

    _matrixAnimation?.removeListener(_onAnimationUpdate);

    _matrixAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: curve,
    ));

    _matrixAnimation!.addListener(_onAnimationUpdate);
    _animController.forward(from: 0.0);
  }

  void _animateToZoom(double factor, Offset focalPoint) {
    if (!mounted) return;
    final currentM = _transformController.value;
    final targetM = Matrix4.identity()
      ..multiply(Matrix4.translationValues(focalPoint.dx, focalPoint.dy, 0.0))
      ..multiply(Matrix4.diagonal3Values(factor, factor, 1.0))
      ..multiply(Matrix4.translationValues(-focalPoint.dx, -focalPoint.dy, 0.0))
      ..multiply(currentM);

    final targetScale = targetM.getMaxScaleOnAxis();
    if (targetScale < 0.10 || targetScale > 3.5) return;

    _animateToMatrix(targetM, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void fitToScreen(double totalWidth, double totalHeight, {bool animated = true}) {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final isMobile = size.shortestSide < 600;

    // True screen dimensions for mobile vs desktop
    final availableW = isMobile ? (size.width - 24) : math.max(size.width - 320, 600.0);
    final availableH = isMobile ? (size.height - 210) : math.max(size.height - 180, 500.0);
    final scale = math.min(availableW / totalWidth, availableH / totalHeight).clamp(0.08, 0.85);

    final offsetX = math.max(12.0, (availableW - (totalWidth * scale)) / 2 + (isMobile ? 12 : 10));
    final offsetY = math.max(20.0, (availableH - (totalHeight * scale)) / 2 + (isMobile ? 16 : 25));

    final matrix = Matrix4.identity();
    matrix.storage[0] = scale;
    matrix.storage[5] = scale;
    matrix.storage[10] = 1.0;
    matrix.storage[12] = offsetX;
    matrix.storage[13] = offsetY;

    if (animated) {
      _animateToMatrix(matrix, duration: const Duration(milliseconds: 450));
    } else {
      _transformController.value = matrix;
    }
  }

  void centerOnAncestors(Map<int, Offset> positions, {bool animated = true}) {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final isMobile = size.shortestSide < 600;

    // Locate Gen 1 root matriarch / patriarch
    final gen1 = widget.people.where((p) => p.generationTier == 1).toList();
    Offset targetOffset = const Offset(1000, 200);
    if (gen1.isNotEmpty && positions.containsKey(gen1.first.id)) {
      targetOffset = positions[gen1.first.id]!;
    } else if (positions.isNotEmpty) {
      targetOffset = positions.values.first;
    }

    final scale = isMobile ? 0.60 : 0.78;
    final screenCenterX = size.width / 2;
    final screenCenterY = (size.height - (isMobile ? 200 : 150)) / 2;

    final targetX = screenCenterX - (targetOffset.dx + cardWidth / 2) * scale;
    final targetY = screenCenterY - (targetOffset.dy + cardHeight / 2) * scale;

    final matrix = Matrix4.identity();
    matrix.storage[0] = scale;
    matrix.storage[5] = scale;
    matrix.storage[10] = 1.0;
    matrix.storage[12] = targetX;
    matrix.storage[13] = targetY;

    if (animated) {
      _animateToMatrix(matrix, duration: const Duration(milliseconds: 500));
    } else {
      _transformController.value = matrix;
    }
  }

  void centerOnPerson(int personId, Map<int, Offset> positions, {bool animated = true}) {
    if (!mounted || !positions.containsKey(personId)) return;
    final size = MediaQuery.of(context).size;
    final isMobile = size.shortestSide < 600;
    final targetOffset = positions[personId]!;

    final scale = isMobile ? 0.72 : 0.85;
    final screenCenterX = size.width / 2;
    final screenCenterY = (size.height - (isMobile ? 200 : 150)) / 2;

    final targetX = screenCenterX - (targetOffset.dx + cardWidth / 2) * scale;
    final targetY = screenCenterY - (targetOffset.dy + cardHeight / 2) * scale;

    final matrix = Matrix4.identity();
    matrix.storage[0] = scale;
    matrix.storage[5] = scale;
    matrix.storage[10] = 1.0;
    matrix.storage[12] = targetX;
    matrix.storage[13] = targetY;

    if (animated) {
      _animateToMatrix(matrix, duration: const Duration(milliseconds: 480));
    } else {
      _transformController.value = matrix;
    }
  }

  @override
  void didUpdateWidget(covariant TreeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPerson != null && widget.selectedPerson?.id != oldWidget.selectedPerson?.id) {
      final selectedId = widget.selectedPerson!.id;
      // If the selection was triggered by directly tapping the card on the canvas,
      // do not jump/teleport the viewport under the user's touch.
      if (_internalTappedPersonId == selectedId) {
        _internalTappedPersonId = null;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final layout = widget.layoutMode == TreeLayoutMode.pedigree
              ? _computePedigreeLayout()
              : _computeTieredLayout();
          centerOnPerson(selectedId, layout.positions, animated: true);
        });
      }
    }
  }

  void resetZoom(double totalWidth, double totalHeight) {
    fitToScreen(totalWidth, totalHeight, animated: true);
  }

  void zoomIn() {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    _animateToZoom(1.35, center);
  }

  void zoomOut() {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    _animateToZoom(0.74, center);
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

    final layout = widget.layoutMode == TreeLayoutMode.pedigree
        ? _computePedigreeLayout()
        : _computeTieredLayout();

    final size = MediaQuery.of(context).size;
    final isMobile = size.shortestSide < 600;

    if (!_initializedFit || _lastPeopleCount != widget.people.length) {
      _initializedFit = true;
      _lastPeopleCount = widget.people.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.selectedPerson != null && layout.positions.containsKey(widget.selectedPerson!.id)) {
          centerOnPerson(widget.selectedPerson!.id, layout.positions);
        } else if (isMobile) {
          centerOnAncestors(layout.positions);
        } else {
          fitToScreen(layout.totalWidth, layout.totalHeight);
        }
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.10,
          maxScale: 3.5,
          panAxis: PanAxis.free,
          clipBehavior: Clip.hardEdge,
          onInteractionStart: (_) {
            if (_animController.isAnimating) {
              _animController.stop();
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTapDown: (details) {
              _lastDoubleTapFocalPoint = details.localPosition;
            },
            onDoubleTap: () {
              final currentScale = _transformController.value.getMaxScaleOnAxis();
              if (currentScale < 0.85) {
                final focal = _lastDoubleTapFocalPoint ?? Offset(size.width / 2, size.height / 2);
                _animateToZoom(1.6, focal);
              } else {
                fitToScreen(layout.totalWidth, layout.totalHeight, animated: true);
              }
            },
            child: Container(
              width: layout.totalWidth,
              height: layout.totalHeight,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C0E14) : const Color(0xFFF7F8FA),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Infinite Sacred Constellation & Dot-Grid Matrix
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _InfiniteSacredCanvasPainter(isDark: isDark),
                    ),
                  ),

                  // Generational Guideline Watermarks on the left
                  if (widget.layoutMode == TreeLayoutMode.pedigree)
                    _buildGenerationalBackdrops(layout),

                  // Vector Lines Painter (Draws Branches, "💍 Married", "🌿 Children / Lineage" Badges)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PedigreeBranchPainter(
                        positions: layout.positions,
                        spouseConnectors: layout.spouseConnectors,
                        familyForks: layout.familyForks,
                        lineageStems: layout.lineageStems,
                        peopleMap: {for (var p in widget.people) p.id: p},
                        selectedPersonId: widget.selectedPerson?.id,
                        hoveredPersonId: _hoveredPersonId,
                        isDark: isDark,
                      ),
                    ),
                  ),

                  // Family Member Cards with Explicit Genealogical Roles
                  for (final person in widget.people)
                    if (layout.positions.containsKey(person.id))
                      Positioned(
                        left: layout.positions[person.id]!.dx,
                        top: layout.positions[person.id]!.dy,
                        child: _buildPersonCard(person, isDark),
                      ),
                ],
              ),
            ),
          ),
        ),

        // Senior Guidance Banner (Desktop Only - Avoids Cluttering Mobile Screens)
        if (!isMobile)
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161A26).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: RoyalTheme.brightGold.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tip: Tap any relative to inspect kinship & history • Drag screen to pan • Use bottom buttons to zoom',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Floating Viewport Controls (Sleek Mobile Frosted Glass HUD vs Desktop Large Buttons)
        if (isMobile)
          Positioned(
            bottom: 22,
            right: 18,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131722).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: RoyalTheme.brightGold.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: zoomIn,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: RoyalTheme.brightGold, size: 22),
                    tooltip: 'Zoom In',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  Container(height: 1, width: 22, color: isDark ? Colors.white12 : Colors.black12),
                  IconButton(
                    onPressed: zoomOut,
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: RoyalTheme.brightGold, size: 22),
                    tooltip: 'Zoom Out',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  Container(height: 1, width: 22, color: isDark ? Colors.white12 : Colors.black12),
                  IconButton(
                    onPressed: () => centerOnAncestors(layout.positions),
                    icon: const Icon(Icons.filter_center_focus_rounded, color: RoyalTheme.brightGold, size: 22),
                    tooltip: 'Center on Ancestors',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  Container(height: 1, width: 22, color: isDark ? Colors.white12 : Colors.black12),
                  IconButton(
                    onPressed: () => fitToScreen(layout.totalWidth, layout.totalHeight),
                    icon: const Icon(Icons.fullscreen_rounded, color: RoyalTheme.brightGold, size: 22),
                    tooltip: 'Show Entire Dynasty',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          )
        else
          Positioned(
            bottom: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131722).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? RoyalTheme.brightGold.withValues(alpha: 0.45) : RoyalTheme.borderLight,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: zoomOut,
                    icon: const Icon(Icons.remove_circle_outline, color: RoyalTheme.brightGold, size: 20),
                    label: Text(
                      'Zoom Out',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                  Container(height: 24, width: 1, color: isDark ? Colors.white24 : Colors.black12),
                  TextButton.icon(
                    onPressed: () => fitToScreen(layout.totalWidth, layout.totalHeight),
                    icon: const Icon(Icons.fit_screen_outlined, color: RoyalTheme.brightGold, size: 20),
                    label: Text(
                      'Show Entire Tree',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: RoyalTheme.brightGold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                  Container(height: 24, width: 1, color: isDark ? Colors.white24 : Colors.black12),
                  TextButton.icon(
                    onPressed: zoomIn,
                    icon: const Icon(Icons.add_circle_outline, color: RoyalTheme.brightGold, size: 20),
                    label: Text(
                      'Zoom In',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenerationalBackdrops(_PedigreeLayoutResult layout) {
    if (layout.tierYLevels.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final entry in layout.tierYLevels.entries) ...[
          // Subtle horizontal generational guideline across the canvas
          Positioned(
            left: 28,
            right: 60,
            top: entry.value + (cardHeight / 2),
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RoyalTheme.brightGold.withValues(alpha: isDark ? 0.35 : 0.45),
                    RoyalTheme.primaryGold.withValues(alpha: isDark ? 0.15 : 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Generational Label Badge (Sitting cleanly in the left margin, zero overlap with cards)
          Positioned(
            left: 28,
            top: entry.value + 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161A26).withValues(alpha: 0.92) : const Color(0xFFE2E8F0).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: RoyalTheme.brightGold.withValues(alpha: 0.45),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.key == 1
                        ? Icons.shield
                        : (entry.key == 2
                            ? Icons.military_tech_outlined
                            : (entry.key == 3 ? Icons.park_outlined : Icons.child_care_outlined)),
                    size: 15,
                    color: RoyalTheme.brightGold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key == 1
                        ? 'GEN 1 • GREAT-GRANDPARENTS & PATRIARCHS'
                        : (entry.key == 2
                            ? 'GEN 2 • GRANDPARENTS & ROYAL ELDERS'
                            : (entry.key == 3
                                ? 'GEN 3 • PARENTS & PILLARS'
                                : 'GEN 4 • GREAT-GRANDCHILDREN & PRINCES')),
                    style: GoogleFonts.cinzel(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: RoyalTheme.brightGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPersonCard(Person person, bool isDark) {
    final isSelected = widget.selectedPerson?.id == person.id;
    final isHovered = _hoveredPersonId == person.id;

    // Compute explicit genealogical lineage role
    final kinship = GenealogyHelper.getKinshipSummary(person, widget.people, widget.relationships);

    // Search match check
    final isSearchMatch = widget.searchQuery.isNotEmpty &&
        (person.fullName.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
            (person.traditionalName ?? '').toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
            kinship.lineageRole.toLowerCase().contains(widget.searchQuery.toLowerCase()));

    final isSearchActive = widget.searchQuery.isNotEmpty;
    final isDimmed = isSearchActive && !isSearchMatch;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredPersonId = person.id),
      onExit: (_) => setState(() => _hoveredPersonId = null),
      child: GestureDetector(
        onTap: () {
          _internalTappedPersonId = person.id;
          widget.onSelectPerson(person);
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDimmed ? 0.35 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: cardWidth,
            height: cardHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        isSelected
                            ? const Color(0xFF242A3C)
                            : (person.isAncestor
                                ? const Color(0xFF221C14)
                                : (person.isMale ? const Color(0xFF151C2C) : const Color(0xFF241520))),
                        isSelected
                            ? const Color(0xFF161A26)
                            : (person.isAncestor
                                ? const Color(0xFF16120B)
                                : (person.isMale ? const Color(0xFF0F1420) : const Color(0xFF170C14))),
                      ]
                    : [
                        isSelected ? const Color(0xFFFFFBEB) : Colors.white,
                        isSelected ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : (isSearchMatch
                        ? const Color(0xFFFFD700)
                        : (isHovered
                            ? RoyalTheme.brightGold.withValues(alpha: 0.85)
                            : (person.isAncestor
                                ? RoyalTheme.primaryGold.withValues(alpha: 0.75)
                                : (isDark ? const Color(0xFF2D3748) : RoyalTheme.borderLight)))),
                width: isSelected ? 2.8 : (isSearchMatch ? 2.8 : (person.isAncestor ? 1.8 : 1.2)),
              ),
              boxShadow: [
                if (isSelected || isSearchMatch)
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.45),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  )
                else if (isHovered)
                  BoxShadow(
                    color: RoyalTheme.brightGold.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Medallion with crown badge if ancestor
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    MonogramMedallion(
                      person: person,
                      size: 52,
                      isSelected: isSelected || isSearchMatch,
                    ),
                    if (person.isAncestor)
                      const Positioned(
                        top: -7,
                        right: -5,
                        child: Text('👑', style: TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name, Role & Kinship Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Full Name
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              person.fullName,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (kinship.spouses.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text('💍', style: TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),

                      // Explicit Genealogical Role Badge (e.g. Great-Grandfather, Father, Mother)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: person.isAncestor
                              ? const Color(0xFFB8860B).withValues(alpha: 0.25)
                              : RoyalTheme.primaryGold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: RoyalTheme.brightGold.withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          kinship.lineageRole,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: RoyalTheme.brightGold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Traditional Name or Customary Title
                      Row(
                        children: [
                          if (person.traditionalName != null && person.traditionalName!.isNotEmpty)
                            Expanded(
                              child: Text(
                                person.traditionalName!,
                                style: GoogleFonts.cinzel(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF855B14),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            Expanded(
                              child: Text(
                                'Gen ${person.generationTier}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ),
                          Text(
                            person.isLiving ? '● Living' : 'Ancestor',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: person.isLiving ? FontWeight.w600 : FontWeight.normal,
                              color: person.isLiving
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
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
        ),
      ),
    );
  }

  // ==========================================
  // PEDIGREE TREE HIERARCHICAL LAYOUT ALGORITHM
  // ==========================================

  _PedigreeLayoutResult _computePedigreeLayout() {
    final positions = <int, Offset>{};
    final spouseConnectors = <_SpouseConnector>[];
    final familyForks = <_FamilyForkConnector>[];
    final lineageStems = <_LineageStemConnector>[];
    final tierYLevels = <int, double>{};

    final peopleMap = {for (var p in widget.people) p.id: p};
    final spouses = <int, List<int>>{};
    final parents = <int, Set<int>>{};
    final children = <int, Set<int>>{};

    for (var r in widget.relationships) {
      if (r.isSpouse) {
        spouses.putIfAbsent(r.person1Id, () => []).add(r.person2Id);
        spouses.putIfAbsent(r.person2Id, () => []).add(r.person1Id);
      } else if (r.isParent) {
        parents.putIfAbsent(r.person2Id, () => {}).add(r.person1Id);
        children.putIfAbsent(r.person1Id, () => {}).add(r.person2Id);
      }
    }

    // Identify True Roots (Ancestors without parents in tree)
    final trueRoots = <int>[];
    final visitedRoots = <int>{};

    for (var p in widget.people) {
      final pid = p.id;
      if (parents.containsKey(pid) && parents[pid]!.isNotEmpty) continue;
      final spList = spouses[pid] ?? [];
      bool hasParentInSpouses = false;
      for (final sp in spList) {
        if (parents.containsKey(sp) && parents[sp]!.isNotEmpty) {
          hasParentInSpouses = true;
          break;
        }
      }
      if (hasParentInSpouses) continue;

      if (!visitedRoots.contains(pid)) {
        trueRoots.add(pid);
        visitedRoots.add(pid);
        for (final sp in spList) {
          visitedRoots.add(sp);
        }
      }
    }

    if (trueRoots.isEmpty && widget.people.isNotEmpty) {
      trueRoots.add(widget.people.first.id);
    }

    // Build hierarchical tree nodes
    final placed = <int>{};

    _LayoutTreeNode buildTree(int pid) {
      final spList = (spouses[pid] ?? []).where((s) => !placed.contains(s) && peopleMap.containsKey(s)).toList();
      final node = _LayoutTreeNode(primaryId: pid, spouseIds: spList);
      placed.add(pid);
      for (final sp in spList) {
        placed.add(sp);
      }

      // Group and order children by maternal concession (spouse) followed by unwed/direct children
      final orderedKids = <int>[];
      for (final sp in spList) {
        final spKids = (children[pid] ?? {}).intersection(children[sp] ?? {}).toList();
        for (final k in spKids) {
          if (!orderedKids.contains(k)) orderedKids.add(k);
        }
      }
      for (final k in (children[pid] ?? {})) {
        if (!orderedKids.contains(k)) orderedKids.add(k);
      }
      for (final sp in spList) {
        for (final k in (children[sp] ?? {})) {
          if (!orderedKids.contains(k)) orderedKids.add(k);
        }
      }

      for (final k in orderedKids) {
        if (!placed.contains(k) && peopleMap.containsKey(k)) {
          node.children.add(buildTree(k));
        }
      }
      return node;
    }

    double measureTree(_LayoutTreeNode node) {
      final totalAdults = 1 + node.spouseIds.length;
      final unitWidth = totalAdults * cardWidth + (totalAdults - 1) * gapSpouse;
      if (node.children.isEmpty) {
        node.width = unitWidth;
        return node.width;
      }

      double childrenTotalWidth = 0;
      for (int i = 0; i < node.children.length; i++) {
        if (i > 0) childrenTotalWidth += gapBranch;
        childrenTotalWidth += measureTree(node.children[i]);
      }

      node.width = math.max(unitWidth, childrenTotalWidth);
      return node.width;
    }

    void placeTree(_LayoutTreeNode node, double startX, double y) {
      node.y = y;
      final pPerson = peopleMap[node.primaryId];
      if (pPerson != null) {
        tierYLevels.putIfAbsent(pPerson.generationTier, () => y);
      }

      final totalAdults = 1 + node.spouseIds.length;
      final unitWidth = totalAdults * cardWidth + (totalAdults - 1) * gapSpouse;

      if (node.children.isEmpty) {
        final ux = startX + (node.width - unitWidth) / 2;
        positions[node.primaryId] = Offset(ux, y);
        for (int i = 0; i < node.spouseIds.length; i++) {
          final spId = node.spouseIds[i];
          final spX = ux + (i + 1) * (cardWidth + gapSpouse);
          positions[spId] = Offset(spX, y);
          spouseConnectors.add(_SpouseConnector(node.primaryId, spId));
        }
        return;
      }

      // First place children
      double childrenCombinedWidth = 0;
      for (int i = 0; i < node.children.length; i++) {
        if (i > 0) childrenCombinedWidth += gapBranch;
        childrenCombinedWidth += node.children[i].width;
      }

      double currX = startX + (node.width - childrenCombinedWidth) / 2;
      final childMidpoints = <Offset>[];
      final childY = y + cardHeight + gapVertical;

      for (final c in node.children) {
        placeTree(c, currX, childY);
        final cTotalAdults = 1 + c.spouseIds.length;
        final cUnitW = cTotalAdults * cardWidth + (cTotalAdults - 1) * gapSpouse;
        final cPos = positions[c.primaryId]!;
        final cCenter = cPos.dx + (cUnitW / 2);
        childMidpoints.add(Offset(cCenter, childY));
        currX += c.width + gapBranch;
      }

      // Center parent couple or single parent directly above children
      final midChildrenX = (childMidpoints.first.dx + childMidpoints.last.dx) / 2;
      final ux = midChildrenX - (unitWidth / 2);
      positions[node.primaryId] = Offset(ux, y);

      for (int i = 0; i < node.spouseIds.length; i++) {
        final spId = node.spouseIds[i];
        final spX = ux + (i + 1) * (cardWidth + gapSpouse);
        positions[spId] = Offset(spX, y);
        spouseConnectors.add(_SpouseConnector(node.primaryId, spId));
      }

      final Offset originPoint;
      if (node.spouseIds.isEmpty) {
        originPoint = Offset(ux + (cardWidth / 2), y + cardHeight);
      } else if (node.spouseIds.length == 1) {
        originPoint = Offset(ux + cardWidth + (gapSpouse / 2), y + cardHeight);
      } else {
        originPoint = Offset(ux + (unitWidth / 2), y + cardHeight);
      }

      // Register descendant family fork
      familyForks.add(_FamilyForkConnector(
        origin: originPoint,
        childrenCenters: childMidpoints,
        forkY: y + cardHeight + (gapVertical / 2),
        parentIds: [node.primaryId, ...node.spouseIds],
        childIds: node.children.map((c) => c.primaryId).toList(),
      ));
    }

    // Dedicated left margin (310px) so generational labels never touch cards, plus top headroom (90px)
    const double leftMargin = 310.0;
    const double topMargin = 90.0;

    double currentRootX = leftMargin;

    for (final rootId in trueRoots) {
      if (placed.contains(rootId)) continue;
      final rootNode = buildTree(rootId);
      measureTree(rootNode);
      placeTree(rootNode, currentRootX, topMargin);
      currentRootX += rootNode.width + 100.0;
    }

    // Handle any orphan / unplaced people
    for (final p in widget.people) {
      if (!positions.containsKey(p.id)) {
        positions[p.id] = Offset(currentRootX, topMargin + (p.generationTier - 1) * (cardHeight + gapVertical));
        currentRootX += cardWidth + gapBranch;
      }
    }

    // Single parent lineage stems (only if child is not already part of a family fork)
    final childrenInForks = familyForks.expand((f) => f.childIds).toSet();
    for (final r in widget.relationships) {
      if (r.isParent) {
        final p1 = positions[r.person1Id];
        final p2 = positions[r.person2Id];
        if (p1 != null && p2 != null && !childrenInForks.contains(r.person2Id)) {
          lineageStems.add(_LineageStemConnector(
            start: Offset(p1.dx + cardWidth / 2, p1.dy + cardHeight),
            end: Offset(p2.dx + cardWidth / 2, p2.dy),
            person1Id: r.person1Id,
            person2Id: r.person2Id,
          ));
        }
      }
    }

    // Measure exact bounding box
    double minX = double.infinity;
    double maxX = 0;
    double minY = double.infinity;
    double maxY = 0;
    for (final pos in positions.values) {
      if (pos.dx < minX) minX = pos.dx;
      if (pos.dx + cardWidth > maxX) maxX = pos.dx + cardWidth;
      if (pos.dy < minY) minY = pos.dy;
      if (pos.dy + cardHeight > maxY) maxY = pos.dy + cardHeight;
    }

    // Normalize X: if any branch drifted to the left of leftMargin, shift all positions and connectors
    if (minX.isFinite && minX < leftMargin) {
      final shiftX = leftMargin - minX;
      for (final key in positions.keys.toList()) {
        positions[key] = Offset(positions[key]!.dx + shiftX, positions[key]!.dy);
      }
      for (int i = 0; i < familyForks.length; i++) {
        final fork = familyForks[i];
        familyForks[i] = _FamilyForkConnector(
          origin: Offset(fork.origin.dx + shiftX, fork.origin.dy),
          childrenCenters: fork.childrenCenters.map((c) => Offset(c.dx + shiftX, c.dy)).toList(),
          forkY: fork.forkY,
          parentIds: fork.parentIds,
          childIds: fork.childIds,
        );
      }
      for (int i = 0; i < lineageStems.length; i++) {
        final stem = lineageStems[i];
        lineageStems[i] = _LineageStemConnector(
          start: Offset(stem.start.dx + shiftX, stem.start.dy),
          end: Offset(stem.end.dx + shiftX, stem.end.dy),
          person1Id: stem.person1Id,
          person2Id: stem.person2Id,
        );
      }
      maxX += shiftX;
    }

    // Normalize Y: ensure ample top headroom
    if (minY.isFinite && minY < topMargin) {
      final shiftY = topMargin - minY;
      for (final key in positions.keys.toList()) {
        positions[key] = Offset(positions[key]!.dx, positions[key]!.dy + shiftY);
      }
      for (final key in tierYLevels.keys.toList()) {
        tierYLevels[key] = tierYLevels[key]! + shiftY;
      }
      for (int i = 0; i < familyForks.length; i++) {
        final fork = familyForks[i];
        familyForks[i] = _FamilyForkConnector(
          origin: Offset(fork.origin.dx, fork.origin.dy + shiftY),
          childrenCenters: fork.childrenCenters.map((c) => Offset(c.dx, c.dy + shiftY)).toList(),
          forkY: fork.forkY + shiftY,
          parentIds: fork.parentIds,
          childIds: fork.childIds,
        );
      }
      for (int i = 0; i < lineageStems.length; i++) {
        final stem = lineageStems[i];
        lineageStems[i] = _LineageStemConnector(
          start: Offset(stem.start.dx, stem.start.dy + shiftY),
          end: Offset(stem.end.dx, stem.end.dy + shiftY),
          person1Id: stem.person1Id,
          person2Id: stem.person2Id,
        );
      }
      maxY += shiftY;
    }

    return _PedigreeLayoutResult(
      positions: positions,
      spouseConnectors: spouseConnectors,
      familyForks: familyForks,
      lineageStems: lineageStems,
      tierYLevels: tierYLevels,
      totalWidth: math.max(maxX + 320.0, 2200.0),
      totalHeight: math.max(maxY + 260.0, 1300.0),
    );
  }

  // ==========================================
  // TIERED FALLBACK LAYOUT (BY GENERATIONS)
  // ==========================================

  _PedigreeLayoutResult _computeTieredLayout() {
    final positions = <int, Offset>{};
    final spouseConnectors = <_SpouseConnector>[];
    final familyForks = <_FamilyForkConnector>[];
    final lineageStems = <_LineageStemConnector>[];
    final tierYLevels = <int, double>{};

    final generations = <int, List<Person>>{};
    for (var p in widget.people) {
      generations.putIfAbsent(p.generationTier, () => []).add(p);
    }
    final sortedTiers = generations.keys.toList()..sort();

    const double leftMargin = 310.0;
    double currentY = 90.0;
    double maxRowWidth = 0;

    for (final tier in sortedTiers) {
      tierYLevels[tier] = currentY;
      final rowPeople = generations[tier]!;
      final rowWidth = rowPeople.length * cardWidth + (rowPeople.length - 1) * 40.0;
      if (rowWidth > maxRowWidth) maxRowWidth = rowWidth;

      double currentX = leftMargin;
      for (final person in rowPeople) {
        positions[person.id] = Offset(currentX, currentY);
        currentX += cardWidth + 40.0;
      }
      currentY += cardHeight + gapVertical;
    }

    return _PedigreeLayoutResult(
      positions: positions,
      spouseConnectors: spouseConnectors,
      familyForks: familyForks,
      lineageStems: lineageStems,
      tierYLevels: tierYLevels,
      totalWidth: math.max(leftMargin + maxRowWidth + 320.0, 2200.0),
      totalHeight: math.max(currentY + 260.0, 1300.0),
    );
  }
}

// ==========================================
// TREE DATA CLASSES & CUSTOM PAINTER
// ==========================================

class _LayoutTreeNode {
  final int primaryId;
  final List<int> spouseIds;
  final List<_LayoutTreeNode> children = [];
  double width = 0;
  double y = 0;

  _LayoutTreeNode({required this.primaryId, List<int>? spouseIds})
      : spouseIds = spouseIds ?? [];
}

class _SpouseConnector {
  final int person1Id;
  final int person2Id;
  _SpouseConnector(this.person1Id, this.person2Id);
}

class _FamilyForkConnector {
  final Offset origin;
  final List<Offset> childrenCenters;
  final double forkY;
  final List<int> parentIds;
  final List<int> childIds;

  _FamilyForkConnector({
    required this.origin,
    required this.childrenCenters,
    required this.forkY,
    required this.parentIds,
    required this.childIds,
  });
}

class _LineageStemConnector {
  final Offset start;
  final Offset end;
  final int person1Id;
  final int person2Id;

  _LineageStemConnector({
    required this.start,
    required this.end,
    required this.person1Id,
    required this.person2Id,
  });
}

class _PedigreeLayoutResult {
  final Map<int, Offset> positions;
  final List<_SpouseConnector> spouseConnectors;
  final List<_FamilyForkConnector> familyForks;
  final List<_LineageStemConnector> lineageStems;
  final Map<int, double> tierYLevels;
  final double totalWidth;
  final double totalHeight;

  _PedigreeLayoutResult({
    required this.positions,
    required this.spouseConnectors,
    required this.familyForks,
    required this.lineageStems,
    required this.tierYLevels,
    required this.totalWidth,
    required this.totalHeight,
  });
}

class _PedigreeBranchPainter extends CustomPainter {
  final Map<int, Offset> positions;
  final List<_SpouseConnector> spouseConnectors;
  final List<_FamilyForkConnector> familyForks;
  final List<_LineageStemConnector> lineageStems;
  final Map<int, Person> peopleMap;
  final int? selectedPersonId;
  final int? hoveredPersonId;
  final bool isDark;

  _PedigreeBranchPainter({
    required this.positions,
    required this.spouseConnectors,
    required this.familyForks,
    required this.lineageStems,
    required this.peopleMap,
    this.selectedPersonId,
    this.hoveredPersonId,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double cardW = _TreeCanvasState.cardWidth;
    const double cardH = _TreeCanvasState.cardHeight;

    final defaultPaint = Paint()
      ..color = isDark ? const Color(0xFFC5A059).withValues(alpha: 0.55) : const Color(0xFFB8860B).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final highlightPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final activeId = selectedPersonId ?? hoveredPersonId;

    // 1. Draw Spousal Horizontal Connectors with African Customary Alliance Badge
    for (final conn in spouseConnectors) {
      final pos1 = positions[conn.person1Id];
      final pos2 = positions[conn.person2Id];
      if (pos1 == null || pos2 == null) continue;

      final isBranchActive = activeId != null && (conn.person1Id == activeId || conn.person2Id == activeId);

      final p1 = Offset(pos1.dx + cardW, pos1.dy + cardH / 2);
      final p2 = Offset(pos2.dx, pos2.dy + cardH / 2);

      canvas.drawLine(p1, p2, isBranchActive ? highlightPaint : defaultPaint);

      // Customary Alliance Badge ("💍 Alliance Coutumière")
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      _drawBranchPillBadge(canvas, mid, '💍 Alliance Coutumière', isBranchActive);
    }

    // 2. Draw Family Descendant Forks with Customary Concession & Lineage Badge
    for (final fork in familyForks) {
      final isBranchActive = activeId != null &&
          (fork.parentIds.contains(activeId) || fork.childIds.contains(activeId));

      final paintToUse = isBranchActive ? highlightPaint : defaultPaint;

      // Vertical stem dropping from parent union down to horizontal bus
      canvas.drawLine(fork.origin, Offset(fork.origin.dx, fork.forkY), paintToUse);

      // Draw "🌿 Concession & Enfants" Badge on vertical stem
      final stemMid = Offset(fork.origin.dx, (fork.origin.dy + fork.forkY) / 2);
      _drawBranchPillBadge(canvas, stemMid, '🌿 Concession & Enfants', isBranchActive);

      if (fork.childrenCenters.length == 1) {
        // Single child
        final childCenter = fork.childrenCenters.first;
        if ((childCenter.dx - fork.origin.dx).abs() < 2.0) {
          canvas.drawLine(Offset(fork.origin.dx, fork.forkY), childCenter, paintToUse);
        } else {
          canvas.drawLine(Offset(fork.origin.dx, fork.forkY), Offset(childCenter.dx, fork.forkY), paintToUse);
          canvas.drawLine(Offset(childCenter.dx, fork.forkY), childCenter, paintToUse);
        }
        canvas.drawCircle(childCenter, 4.0, dotPaint);
      } else if (fork.childrenCenters.length > 1) {
        // Multiple children: Horizontal bus bar
        double minX = fork.childrenCenters.first.dx;
        double maxX = fork.childrenCenters.first.dx;
        for (final c in fork.childrenCenters) {
          if (c.dx < minX) minX = c.dx;
          if (c.dx > maxX) maxX = c.dx;
        }

        if (fork.origin.dx < minX) minX = fork.origin.dx;
        if (fork.origin.dx > maxX) maxX = fork.origin.dx;

        // Draw horizontal bus bar
        canvas.drawLine(Offset(minX, fork.forkY), Offset(maxX, fork.forkY), paintToUse);

        // Draw vertical drops to each child
        for (final c in fork.childrenCenters) {
          canvas.drawLine(Offset(c.dx, fork.forkY), c, paintToUse);
          canvas.drawCircle(c, 4.0, dotPaint);
        }
      }
    }

    // 3. Draw Single-parent Lineage Stems with Maternal/Paternal Lineage Badge
    for (final stem in lineageStems) {
      final isBranchActive = activeId != null && (stem.person1Id == activeId || stem.person2Id == activeId);
      final paintToUse = isBranchActive ? highlightPaint : defaultPaint;

      final midY = (stem.start.dy + stem.end.dy) / 2;

      final path = Path();
      path.moveTo(stem.start.dx, stem.start.dy);
      path.lineTo(stem.start.dx, midY);
      path.lineTo(stem.end.dx, midY);
      path.lineTo(stem.end.dx, stem.end.dy);

      canvas.drawPath(path, paintToUse);
      canvas.drawCircle(stem.end, 4.0, dotPaint);

      final p1 = peopleMap[stem.person1Id];
      final isMother = p1 != null && p1.isFemale;
      final badgeLabel = isMother ? '👑 Lignée Maternelle' : '👑 Lignée Paternelle';
      _drawBranchPillBadge(canvas, Offset((stem.start.dx + stem.end.dx) / 2, midY), badgeLabel, isBranchActive);
    }
  }

  void _drawBranchPillBadge(Canvas canvas, Offset center, String label, bool isHighlighted) {
    final bgPaint = Paint()..color = isDark ? const Color(0xFF131722) : Colors.white;
    final borderPaint = Paint()
      ..color = isHighlighted ? const Color(0xFFFFD700) : const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted ? 1.8 : 1.1;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isHighlighted ? const Color(0xFFFFD700) : (isDark ? const Color(0xFFE5C07B) : const Color(0xFF855B14)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + 14.0;
    final pillHeight = textPainter.height + 6.0;
    final rect = Rect.fromCenter(center: center, width: pillWidth, height: pillHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Shadow
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PedigreeBranchPainter oldDelegate) {
    return oldDelegate.selectedPersonId != selectedPersonId ||
        oldDelegate.hoveredPersonId != hoveredPersonId ||
        oldDelegate.positions != positions ||
        oldDelegate.isDark != isDark;
  }
}

class _InfiniteSacredCanvasPainter extends CustomPainter {
  final bool isDark;

  const _InfiniteSacredCanvasPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = isDark ? const Color(0xFFD4AF37).withValues(alpha: 0.12) : const Color(0xFFB8860B).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final brightDotPaint = Paint()
      ..color = isDark ? const Color(0xFFFFD700).withValues(alpha: 0.30) : const Color(0xFFD4AF37).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = isDark ? const Color(0xFFD4AF37).withValues(alpha: 0.035) : const Color(0xFFB8860B).withValues(alpha: 0.025)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 54.0;
    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;

    for (int i = 0; i < cols; i++) {
      final x = i * spacing;
      if (i % 4 == 0) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
      for (int j = 0; j < rows; j++) {
        final y = j * spacing;
        if (i % 4 == 0 && j % 4 == 0) {
          canvas.drawCircle(Offset(x, y), 2.2, brightDotPaint);
        } else {
          canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InfiniteSacredCanvasPainter oldDelegate) => oldDelegate.isDark != isDark;
}

