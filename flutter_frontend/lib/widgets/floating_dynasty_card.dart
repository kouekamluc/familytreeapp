import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/royal_theme.dart';

class FloatingDynastyMemberData {
  final String id;
  final String name;
  final String traditionalTitle;
  final String role;
  final String village;
  final String totem;
  final String portraitAsset;
  final String sacredLore;
  final String audioDuration;
  final int generationTier;
  final bool isMale;

  const FloatingDynastyMemberData({
    required this.id,
    required this.name,
    required this.traditionalTitle,
    required this.role,
    required this.village,
    required this.totem,
    required this.portraitAsset,
    required this.sacredLore,
    required this.audioDuration,
    required this.generationTier,
    required this.isMale,
  });

  static List<FloatingDynastyMemberData> get royalShowcaseList => const [
        FloatingDynastyMemberData(
          id: 'kamgou',
          name: 'Fo Kamgou II',
          traditionalTitle: 'Chef Supérieur & Roi Sacré (Fo)',
          role: 'Patriarche de la Dynastie • Gardien du Feu Sacré',
          village: 'Chefferie Bandjoun',
          totem: 'Léopard Royal 🐆',
          portraitAsset: 'assets/portraits/kamgou.jpg',
          sacredLore:
              '« La grandeur d\'un arbre se mesure à la profondeur de ses racines dans la terre sacrée de Bandjoun. »',
          audioDuration: '0:48',
          generationTier: 1,
          isMale: true,
        ),
        FloatingDynastyMemberData(
          id: 'helene',
          name: 'Mafo Hélène Kkevo',
          traditionalTitle: 'Reine Mère & Haute Dignitaire (Mafo)',
          role: 'Matriarche Suprême • Protectrice des Lignées Utérines',
          village: 'Concession Maa Kkevo',
          totem: 'Panthère Noire 🐆',
          portraitAsset: 'assets/portraits/helene.jpg',
          sacredLore:
              '« Les enfants nés du même ventre sacré portent la bénédiction inaltérable de la première mère. »',
          audioDuration: '1:12',
          generationTier: 1,
          isMale: false,
        ),
        FloatingDynastyMemberData(
          id: 'jean',
          name: 'Tadji Jean Kkevo',
          traditionalTitle: 'Premier Prince Héritier (Tadji)',
          role: 'Successeur Désigné • Gardien des Alliances Coutumières',
          village: 'Concession Royale',
          totem: 'Aigle Royal 🦅',
          portraitAsset: 'assets/portraits/jean.jpg',
          sacredLore:
              '« Un peuple qui oublie ses ancêtres est comme une rivière qui s\'éloigne de sa source vive. »',
          audioDuration: '0:36',
          generationTier: 2,
          isMale: true,
        ),
        FloatingDynastyMemberData(
          id: 'amina',
          name: 'Reine Amina Kkevo',
          traditionalTitle: 'Épouse Royale & Mère de Lignée',
          role: 'Protectrice de la Seconde Concession',
          village: 'Alliances Haut-Nkam',
          totem: 'Gazelle Dorée 🦌',
          portraitAsset: 'assets/portraits/amina.jpg',
          sacredLore:
              '« La concorde entre les concessions fait la puissance inébranlable de notre famille. »',
          audioDuration: '0:54',
          generationTier: 2,
          isMale: false,
        ),
        FloatingDynastyMemberData(
          id: 'lucas',
          name: 'Prince Lucas Kkevo',
          traditionalTitle: 'Nji Lucas • Dignitaire de la Jeunesse',
          role: 'Passeur de Flambeau • Souveraineté Numérique',
          village: 'Diaspora & Bandjoun',
          totem: 'Lionceau Ardent 🦁',
          portraitAsset: 'assets/portraits/lucas.jpg',
          sacredLore:
              '« L\'héritage de nos aïeux vit désormais dans notre sang et dans la mémoire numérique éternelle. »',
          audioDuration: '0:42',
          generationTier: 3,
          isMale: true,
        ),
        FloatingDynastyMemberData(
          id: 'chloe',
          name: 'Princesse Chloé Kkevo',
          traditionalTitle: 'Ngouh Chloé • Ambassadrice Royale',
          role: 'Gardienne des Parures & Rites Sacrés',
          village: 'Diaspora & Rayonnement',
          totem: 'Colombe de Paix 🕊️',
          portraitAsset: 'assets/portraits/chloe.jpg',
          sacredLore:
              '« Chaque nouvelle génération est une perle précieuse ajoutée au collier de nos pères. »',
          audioDuration: '0:39',
          generationTier: 3,
          isMale: false,
        ),
      ];
}

/// A Fish Audio-inspired floating dynamic component card featuring real photorealistic heads,
/// interactive oral waveform equalizer bars, and fluid native spring physics.
class FloatingDynastyCard extends StatefulWidget {
  final FloatingDynastyMemberData member;
  final double floatPhase;
  final double floatAmplitudeY;
  final double floatAmplitudeX;
  final Duration floatDuration;
  final bool isSelected;
  final VoidCallback? onTap;

  const FloatingDynastyCard({
    super.key,
    required this.member,
    this.floatPhase = 0.0,
    this.floatAmplitudeY = 10.0,
    this.floatAmplitudeX = 6.0,
    this.floatDuration = const Duration(seconds: 4),
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<FloatingDynastyCard> createState() => _FloatingDynastyCardState();
}

class _FloatingDynastyCardState extends State<FloatingDynastyCard>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _waveController;
  bool _isPlayingAudio = false;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: widget.floatDuration,
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPlayingAudio = !_isPlayingAudio;
      _isExpanded = _isPlayingAudio;
    });
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final m = widget.member;

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final progress = _floatController.value * 2 * math.pi + widget.floatPhase;
        final offsetY = math.sin(progress) * widget.floatAmplitudeY;
        final offsetX = math.cos(progress * 0.8) * widget.floatAmplitudeX;

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _isPressed = true);
          },
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: _togglePlayback,
          child: AnimatedScale(
            scale: _isPressed
                ? 0.94
                : (_isExpanded
                    ? 1.04
                    : (_isHovered ? 1.025 : 1.0)),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: isDark
                    ? (_isPlayingAudio
                        ? const Color(0xFF191E2D)
                        : const Color(0xFF131622).withValues(alpha: 0.94))
                    : (_isPlayingAudio
                        ? const Color(0xFFFFFBF0)
                        : Colors.white.withValues(alpha: 0.95)),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isPlayingAudio || widget.isSelected
                      ? RoyalTheme.brightGold
                      : (_isHovered
                          ? RoyalTheme.primaryGold.withValues(alpha: 0.8)
                          : RoyalTheme.brightGold.withValues(alpha: isDark ? 0.35 : 0.25)),
                  width: _isPlayingAudio || widget.isSelected ? 2.0 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isPlayingAudio || widget.isSelected)
                        ? RoyalTheme.brightGold.withValues(alpha: isDark ? 0.35 : 0.22)
                        : Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    blurRadius: _isPlayingAudio ? 24 : (_isHovered ? 20 : 14),
                    spreadRadius: _isPlayingAudio ? 2 : 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Real Person Portrait Head + Status Badge + Play/Pause Button
                  Row(
                    children: [
                      // Real Head Avatar with Royal Gold Crown Halo
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isPlayingAudio
                                    ? RoyalTheme.brightGold
                                    : RoyalTheme.primaryGold.withValues(alpha: 0.8),
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: RoyalTheme.brightGold
                                      .withValues(alpha: _isPlayingAudio ? 0.45 : 0.2),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                m.portraitAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    m.name.isNotEmpty ? m.name[0] : '👑',
                                    style: GoogleFonts.cinzel(
                                      color: RoyalTheme.brightGold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Small Customary Crown / Tier Emblem
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3.5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10121A),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                m.generationTier == 1
                                    ? '👑'
                                    : (m.generationTier == 2 ? '🗡️' : '🌿'),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 14),

                      // Name and Traditional Honorific Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.name,
                                    style: GoogleFonts.cinzel(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1C1917),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.traditionalTitle,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: RoyalTheme.brightGold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.village,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Interactive Fish Audio Play/Pulse Button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isPlayingAudio
                                ? [const Color(0xFFFFDE7A), const Color(0xFFD4AF37)]
                                : [
                                    RoyalTheme.brightGold.withValues(alpha: 0.15),
                                    RoyalTheme.primaryGold.withValues(alpha: 0.1)
                                  ],
                          ),
                          border: Border.all(
                            color: RoyalTheme.brightGold.withValues(alpha: 0.7),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: _isPlayingAudio ? Colors.black : RoyalTheme.brightGold,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Middle Row: Dynamic Fish Audio-Style Waveform Equalizer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D0F17)
                          : const Color(0xFFF6F2E8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: RoyalTheme.primaryGold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Live Microphone / Oral Icon
                        Icon(
                          Icons.graphic_eq_rounded,
                          color: _isPlayingAudio ? RoyalTheme.brightGold : Colors.grey[500],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tradition Orale',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Animated Dynamic Soundwave Bars
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, _) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(9, (barIdx) {
                                  final phase = (barIdx * 0.7) + (_waveController.value * 2 * math.pi);
                                  final double barHeight = _isPlayingAudio
                                      ? (6.0 + (math.sin(phase).abs() * 16.0))
                                      : (4.0 + ((barIdx % 3) * 3.5));

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    width: 3.0,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: _isPlayingAudio
                                            ? [
                                                const Color(0xFFB8860B),
                                                const Color(0xFFD4AF37),
                                                const Color(0xFFFFDF73),
                                              ]
                                            : [
                                                Colors.grey.withValues(alpha: 0.4),
                                                Colors.grey.withValues(alpha: 0.7),
                                              ],
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 8),
                        Text(
                          m.audioDuration,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: RoyalTheme.brightGold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expandable Sacred Lore Proverb Bubble
                  if (_isExpanded) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: RoyalTheme.brightGold.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: RoyalTheme.brightGold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        m.sacredLore,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                          color: isDark ? const Color(0xFFFFE8B2) : const Color(0xFF6B4508),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Bottom Tags Row: Totem + Role Chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: RoyalTheme.brightGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m.totem,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: RoyalTheme.brightGold,
                          ),
                        ),
                      ),
                      Text(
                        'Gen ${m.generationTier} • Lignée Pure',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
