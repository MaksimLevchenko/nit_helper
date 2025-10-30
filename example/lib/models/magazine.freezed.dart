// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'magazine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Magazine {
  String get title => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MagazineCopyWith<Magazine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MagazineCopyWith<$Res> {
  factory $MagazineCopyWith(Magazine value, $Res Function(Magazine) then) =
      _$MagazineCopyWithImpl<$Res, Magazine>;
  @useResult
  $Res call({String title, String author, int year});
}

/// @nodoc
class _$MagazineCopyWithImpl<$Res, $Val extends Magazine>
    implements $MagazineCopyWith<$Res> {
  _$MagazineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? author = null,
    Object? year = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MagazineImplCopyWith<$Res>
    implements $MagazineCopyWith<$Res> {
  factory _$$MagazineImplCopyWith(
          _$MagazineImpl value, $Res Function(_$MagazineImpl) then) =
      __$$MagazineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String title, String author, int year});
}

/// @nodoc
class __$$MagazineImplCopyWithImpl<$Res>
    extends _$MagazineCopyWithImpl<$Res, _$MagazineImpl>
    implements _$$MagazineImplCopyWith<$Res> {
  __$$MagazineImplCopyWithImpl(
      _$MagazineImpl _value, $Res Function(_$MagazineImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? author = null,
    Object? year = null,
  }) {
    return _then(_$MagazineImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$MagazineImpl implements _Magazine {
  const _$MagazineImpl(
      {required this.title, required this.author, required this.year});

  @override
  final String title;
  @override
  final String author;
  @override
  final int year;

  @override
  String toString() {
    return 'Magazine(title: $title, author: $author, year: $year)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MagazineImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.year, year) || other.year == year));
  }

  @override
  int get hashCode => Object.hash(runtimeType, title, author, year);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MagazineImplCopyWith<_$MagazineImpl> get copyWith =>
      __$$MagazineImplCopyWithImpl<_$MagazineImpl>(this, _$identity);
}

abstract class _Magazine implements Magazine {
  const factory _Magazine(
      {required final String title,
      required final String author,
      required final int year}) = _$MagazineImpl;

  @override
  String get title;
  @override
  String get author;
  @override
  int get year;
  @override
  @JsonKey(ignore: true)
  _$$MagazineImplCopyWith<_$MagazineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
