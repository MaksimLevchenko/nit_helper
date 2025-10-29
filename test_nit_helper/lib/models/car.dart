import 'package:freezed_annotation/freezed_annotation.dart';

part 'car.freezed.dart';

@freezed
class Car with _$Car {
  const factory Car({
    required String make,
    required String model,
    required int year,
  }) = _Car;
}
