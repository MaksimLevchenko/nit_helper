import 'package:freezed_annotation/freezed_annotation.dart';

part 'magazine.freezed.dart';

@freezed
class Magazine with _$Magazine {
  const factory Magazine({
    required String title,
    required String author,
    required int year,
  }) = _Magazine;
}
