import 'package:flutter_test/flutter_test.dart';
import 'package:liftlog/data/models/app_settings.dart';
import 'package:liftlog/services/unit_converter.dart';

void main() {
  test('converts weight between kg and lb accurately', () {
    expect(UnitConverter.weightToDisplay(100, WeightUnit.kg), 100);
    expect(UnitConverter.weightToDisplay(100, WeightUnit.lb), closeTo(220.46, 0.01));
    expect(UnitConverter.weightToStorage(220.462, WeightUnit.lb), closeTo(100, 0.01));
  });

  test('converts distance between km and miles accurately', () {
    expect(UnitConverter.distanceToDisplay(10, DistanceUnit.km), 10);
    expect(UnitConverter.distanceToDisplay(10, DistanceUnit.miles), closeTo(6.21, 0.01));
  });
}
