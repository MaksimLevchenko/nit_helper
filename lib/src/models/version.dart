class Version implements Comparable<Version> {
  final int major;
  final int minor;
  final int patch;

  const Version(
      {required this.major, required this.minor, required this.patch});

  @override
  String toString() => '$major.$minor.$patch';

  static Version? parse(String version) {
    final parts = version.split('.');
    if (parts.length != 3) return null;

    try {
      return Version(
        major: int.parse(parts[0]),
        minor: int.parse(parts[1]),
        patch: int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  int compareTo(Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Version &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch;

  @override
  int get hashCode => major.hashCode ^ minor.hashCode ^ patch.hashCode;

  bool operator <(Version other) => compareTo(other) < 0;
  bool operator >(Version other) => compareTo(other) > 0;
  bool operator <=(Version other) => compareTo(other) <= 0;
  bool operator >=(Version other) => compareTo(other) >= 0;
}
