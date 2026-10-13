# Prompted values are kept in memory and passed as dart-define, never in a file.
param([string]$Device = 'chrome')
$ErrorActionPreference = 'Stop'
$coverrSecret = Read-Host 'Clave de Coverr (Enter para omitir)' -AsSecureString
$pixabaySecret = Read-Host 'Clave de Pixabay (Enter para omitir)' -AsSecureString
$coverrValue = [System.Net.NetworkCredential]::new('', $coverrSecret).Password
$pixabayValue = [System.Net.NetworkCredential]::new('', $pixabaySecret).Password
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
  & flutter run -d $Device "--dart-define=COVERR_API_KEY=$coverrValue" "--dart-define=PIXABAY_API_KEY=$pixabayValue"
} finally {
  $coverrValue = $null
  $pixabayValue = $null
  $coverrSecret.Dispose()
  $pixabaySecret.Dispose()
  Pop-Location
}
