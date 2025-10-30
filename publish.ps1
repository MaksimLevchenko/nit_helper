# publish.ps1

# 1. Generate version
Write-Host "==> Generating version from pubspec.yaml..."
dart run bin/generate_version.dart
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error while generating version."
    exit 1
}

# 2. Format the generated file
Write-Host "==> Formatting version.g.dart..."
dart format lib/src/generated/version.g.dart

# 3. Publish the package
Write-Host "==> Publishing package to pub.dev..."
dart pub publish
