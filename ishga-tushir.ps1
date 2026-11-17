$flutter = Join-Path $env:USERPROFILE "flutter\bin"
if (Test-Path $flutter) {
  $env:Path = "$flutter;" + $env:Path
}

Set-Location (Join-Path $PSScriptRoot "server")
dart run bin/server.dart
