import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';

class MonogramMedallion extends StatefulWidget {
  final Person person;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  const MonogramMedallion({
    super.key,
    required this.person,
    this.size = 64,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<MonogramMedallion> createState() => _MonogramMedallionState();
}

class _MonogramMedallionState extends State<MonogramMedallion> {
  String? _renewedUrl;
  bool _attemptedRefresh = false;
  Person get person => widget.person;
  double get size => widget.size;
  bool get isSelected => widget.isSelected;
  VoidCallback? get onTap => widget.onTap;

  @override
  void didUpdateWidget(MonogramMedallion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person.id != person.id ||
        oldWidget.person.profilePicture != person.profilePicture) {
      _renewedUrl = null;
      _attemptedRefresh = false;
    }
  }

  void _refreshExpiredUrl() {
    if (_attemptedRefresh) return;
    _attemptedRefresh = true;
    final id = person.id;
    Future<void>(() async {
      if (!mounted) return;
      final fresh = await context.read<ApiService>().getPerson(id);
      if (mounted && person.id == id && fresh?.profilePicture != null) {
        setState(() => _renewedUrl = fresh!.profilePicture);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar =
        person.profilePicture != null && person.profilePicture!.isNotEmpty;
    final palette = [
      const Color(0xFFDDF2E4),
      const Color(0xFFDFECFC),
      const Color(0xFFFCE7D7),
      const Color(0xFFEAE3F6),
    ];
    final color = palette[person.id.abs() % palette.length];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 180,
        ),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected
                ? RoyalTheme.green
                : (person.isAncestor
                      ? RoyalTheme.primaryGold
                      : Theme.of(context).colorScheme.outline),
            width: isSelected ? 3.0 : (person.isAncestor ? 2.5 : 1.8),
          ),
        ),
        child: ClipOval(
          child: hasAvatar
              ? Image.network(
                  _renewedUrl ?? person.profilePicture!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    _refreshExpiredUrl();
                    return _buildInitials();
                  },
                )
              : _buildInitials(),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        person.initials,
        style: GoogleFonts.nunito(
          color: RoyalTheme.ink,
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
