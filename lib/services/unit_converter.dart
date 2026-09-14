import '../data/models/app_settings.dart';

class UnitConverter {
  const UnitConverter._();

  static const double _kgToLb = 2.20462;
  static const double _kmToMile = 0.621371;

  static double weightToDisplay(double weightInKg, WeightUnit unit) {
    if (unit == WeightUnit.lb) {
      return weightInKg * _kgToLb;
    }
    return weightInKg;
  }

  static double weightToStorage(double displayedWeight, WeightUnit unit) {
    if (unit == WeightUnit.lb) {
      return displayedWeight / _kgToLb;
    }
    return displayedWeight;
  }

  static double distanceToDisplay(double distanceInKm, DistanceUnit unit) {
    if (unit == DistanceUnit.miles) {
      return distanceInKm * _kmToMile;
    }
    return distanceInKm;
  }

  static double distanceToStorage(double displayedDistance, DistanceUnit unit) {
    if (unit == DistanceUnit.miles) {
      return displayedDistance / _kmToMile;
    }
    return displayedDistance;
  }

  static String formatWeight(double weightInKg, WeightUnit unit) {
    final value = weightToDisplay(weightInKg, unit);
    final unitString = unit == WeightUnit.kg ? 'kg' : 'lbs';
    final formatted = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
    return '$formatted $unitString';
  }

  static String formatDistance(double distanceInKm, DistanceUnit unit) {
    final value = distanceToDisplay(distanceInKm, unit);
    final unitString = unit == DistanceUnit.km ? 'km' : 'mi';
    return '${value.toStringAsFixed(1)} $unitString';
  }
}
