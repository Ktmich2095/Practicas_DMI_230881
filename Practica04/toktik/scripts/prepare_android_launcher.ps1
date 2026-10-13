# Development only: keep Flutter's fixed debug entry launchable before reinstall.
# This never changes Flutter preferences and touches only TokTik components.
param([string]$Device = 'emulator-5554')
$ErrorActionPreference = 'Stop'
$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA 'Android/Sdk' }
$adbPath = Join-Path $sdkRoot 'platform-tools/adb.exe'
if (-not (Test-Path -LiteralPath $adbPath)) { $adbPath = (Get-Command adb -ErrorAction Stop).Source }
$packagePath = & $adbPath -s $Device shell pm path com.example.toktik
if (-not $packagePath) { Write-Output 'TokTik no está instalado; se usará el launcher inicial.'; return }
$launchOutput = & $adbPath -s $Device shell am start -W -n com.example.toktik/.LauncherPreparationActivity 2>&1
if ($LASTEXITCODE -ne 0 -or ($launchOutput -join ' ') -match 'Error:|Error type|Exception') {
  throw 'El APK instalado no tiene el helper de depuración. Compila e instala el APK debug nuevo antes de preparar el launcher.'
}
Write-Output 'Entrada de desarrollo TokTik preparada; la app restaurará su temporada guardada.'
