param([Parameter(Mandatory=$true)][string]$ApiBaseUrl)
$ErrorActionPreference = 'Stop'
$baseUri = $null
if (-not [Uri]::TryCreate($ApiBaseUrl, [UriKind]::Absolute, [ref]$baseUri) -or
    $baseUri.Scheme -ne 'https' -or $baseUri.UserInfo -or $baseUri.Query -or $baseUri.Fragment -or
    $baseUri.IsLoopback -or $baseUri.Host.EndsWith('.example')) {
  throw 'Indica la URL HTTPS pública real del backend, sin claves, query ni fragmento.'
}
$base = $ApiBaseUrl.TrimEnd('/')
foreach ($provider in @('coverr','pixabay')) {
  try {
    $catalog = Invoke-RestMethod -Uri "$base/v1/videos/$provider" -TimeoutSec 20
    if (-not $catalog.hits -or $catalog.hits.Count -eq 0) { throw 'empty catalog' }
  } catch {
    # Do not relay raw network exceptions, URLs, headers or response bodies.
    throw "El backend no pudo entregar el catálogo de $provider. Revisa sus diagnósticos HTTP antes de publicar."
  }
}
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
  & flutter build apk --release "--dart-define=TOKTIK_API_BASE_URL=$base"
  if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación release.' }
  & python scripts/audit_public_apk.py
  if ($LASTEXITCODE -ne 0) { throw 'El APK no pasó la comprobación de secretos; no lo subas.' }
  Write-Output 'APK verificado: build/app/outputs/flutter-apk/app-release.apk. Las claves privadas permanecen en el backend.'
} finally { Pop-Location }
