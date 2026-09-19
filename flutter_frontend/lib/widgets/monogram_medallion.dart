import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/royal_theme.dart';
import '../models/person.dart';

class MonogramMedallion extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final hasAvatar = person.profilePicture != null && person.profilePicture!.isNotEmpty;
    final isMale = person.isMale;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isMale
                ? [
                    const Color(0xFF1E2A38),
                    const Color(0xFF0F1722),
                  ]
                : [
                    const Color(0xFF381E29),
                    const Color(0xFF220F19),
                  ],
          ),
          border: Border.all(
            color: isSelected
                ? RoyalTheme.brightGold
                : (person.isAncestor ? RoyalTheme.primaryGold : RoyalTheme.borderDark),
            width: isSelected ? 3.0 : (person.isAncestor ? 2.5 : 1.8),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: RoyalTheme.brightGold.withOpacity(0.5),
                blurRadius: 16,
                spreadRadius: 2,
              )
            else if (person.isAncestor)
              BoxShadow(
                color: RoyalTheme.primaryGold.withOpacity(0.25),
                blurRadius: 10,
              ),
          ],
        ),
        child: ClipOval(
          child: hasAvatar
              ? Image.network(
                  person.profilePicture!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildInitials(),
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
        style: GoogleFonts.cinzel(
          color: person.isAncestor ? RoyalTheme.lightGold : Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
