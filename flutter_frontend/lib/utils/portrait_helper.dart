import '../models/person.dart';

class PortraitHelper {
  /// Returns the authentic photorealistic royal portrait asset path for a person.
  static String getPortraitAsset(Person person) {
    final fullName = '${person.firstName} ${person.lastName}'.trim().toLowerCase();
    final trad = (person.traditionalName ?? '').trim().toLowerCase();

    if (fullName.contains('kamgou') || trad.contains('chef') || (person.generationTier == 1 && person.isMale)) {
      return 'assets/portraits/kamgou.jpg';
    }
    if (fullName.contains('helene') || (person.generationTier == 1 && person.isFemale)) {
      return 'assets/portraits/helene.jpg';
    }
    if (fullName.contains('jean') || trad.contains('tadji') || (person.generationTier == 2 && person.isMale)) {
      return 'assets/portraits/jean.jpg';
    }
    if (fullName.contains('amina') || trad.contains('mafo') || (person.generationTier == 2 && person.isFemale)) {
      return 'assets/portraits/amina.jpg';
    }
    if (fullName.contains('lucas') || fullName.contains('liam') || fullName.contains('noah') || fullName.contains('arthur') || fullName.contains('robert') || fullName.contains('michel') || fullName.contains('samuel') || fullName.contains('david')) {
      return (person.isMale && person.generationTier >= 3) ? 'assets/portraits/lucas.jpg' : 'assets/portraits/jean.jpg';
    }
    if (fullName.contains('chloe') || fullName.contains('aria') || fullName.contains('celine') || fullName.contains('grace') || fullName.contains('nelly') || fullName.contains('odette') || fullName.contains('marie') || fullName.contains('victorine')) {
      return (person.isFemale && person.generationTier >= 3) ? 'assets/portraits/chloe.jpg' : 'assets/portraits/amina.jpg';
    }

    // Default fallback by gender
    if (person.isFemale) {
      return (person.generationTier <= 2) ? 'assets/portraits/helene.jpg' : 'assets/portraits/chloe.jpg';
    } else {
      return (person.generationTier <= 2) ? 'assets/portraits/kamgou.jpg' : 'assets/portraits/lucas.jpg';
    }
  }
}
