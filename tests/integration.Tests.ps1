param([string]$Version = '16')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('docker-postgresql-test-' + [Guid]::NewGuid().ToString('N'))
$variables = @('COMPOSE_PROJECT_NAME', 'COMPOSE_FILE', 'POSTGRES_VERSION', 'POSTGRES_PORT', 'POSTGRES_USER', 'POSTGRES_DB', 'POSTGRES_PASSWORD')
$saved = @{}
foreach ($name in $variables) {
    $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    Remove-Item "Env:$name" -ErrorAction SilentlyContinue
}
function Assert-Sql([string]$Database, [string]$Query, [string]$Expected) {
    $actual = & docker compose exec -T postgres psql -X -U app -d $Database -At -v ON_ERROR_STOP=1 -c $Query
    if ($LASTEXITCODE -ne 0 -or ($actual -join "`n") -ne $Expected) { throw "SQL inattendu : $actual (attendu : $Expected)" }
}
New-Item -ItemType Directory -Path $testRoot | Out-Null
Push-Location $testRoot
try {
    foreach ($file in @('compose.yaml', 'dev.ps1', '.env.example')) { Copy-Item (Join-Path $root $file) $testRoot }
    New-Item -ItemType Directory -Path docker/init -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $testRoot 'docker/init/01-test.sql'), "CREATE TABLE init_probe (id integer);`n")
    $env:COMPOSE_PROJECT_NAME = 'pg-test-' + [Guid]::NewGuid().ToString('N')
    $env:POSTGRES_VERSION = $Version
    $env:POSTGRES_PORT = '0'
    & ./dev.ps1 init
    $initial = [IO.File]::ReadAllText((Join-Path $testRoot '.env'))
    if ($initial -notmatch 'POSTGRES_PASSWORD=[a-f0-9]{48}') { throw 'Mot de passe aleatoire absent.' }
    & ./dev.ps1 init
    if ([IO.File]::ReadAllText((Join-Path $testRoot '.env')) -cne $initial) { throw 'init a modifie .env.' }
    & docker compose config --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Compose invalide.' }
    & ./dev.ps1 start
    $checkOutput = & ./dev.ps1 check
    if (($checkOutput -join "`n") -notmatch 'PostgreSQL [0-9]+\.') { throw 'check ne retourne pas la version du serveur.' }
    $checkOutput | Write-Host
    Assert-Sql app 'SELECT current_setting(''server_version_num'')::integer / 10000;' ($Version.Split('.')[0])
    Assert-Sql app 'INSERT INTO init_probe VALUES (42) RETURNING id;' "42`nINSERT 0 1"
    & ./dev.ps1 stop
    & ./dev.ps1 start
    Assert-Sql app 'SELECT id FROM init_probe;' '42'
    & ./dev.ps1 backup
    $dump = @(Get-ChildItem backups/*.dump)
    if ($dump.Count -ne 1 -or $dump[0].Length -eq 0) { throw 'Sauvegarde absente ou vide.' }
    & ./dev.ps1 restore $dump[0].FullName restored
    Assert-Sql restored 'SELECT id FROM init_probe;' '42'
    $rejected = $false
    try { & ./dev.ps1 restore $dump[0].FullName restored } catch { $rejected = $true }
    if (-not $rejected) { throw 'La restauration aurait du refuser une base existante.' }
    Assert-Sql restored 'SELECT id FROM init_probe;' '42'
    $env:POSTGRES_VERSION = 'latest'
    $rejected = $false
    try { & ./dev.ps1 start } catch { $rejected = $true }
    if (-not $rejected) { throw 'Le tag latest aurait du etre refuse.' }
    $env:POSTGRES_VERSION = $Version
    Write-Host "Tests PostgreSQL $Version reussis : init, SQL, persistance, sauvegarde, restauration et refus des entrees invalides."
} finally {
    $env:POSTGRES_VERSION = $Version
    & docker compose down --volumes --remove-orphans
    $cleanupCode = $LASTEXITCODE
    Pop-Location
    foreach ($name in $variables) {
        if ($null -eq $saved[$name]) { Remove-Item "Env:$name" -ErrorAction SilentlyContinue }
        else { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
    }
    # Only remove the unique temporary directory created by this test.
    $resolvedTest = [IO.Path]::GetFullPath($testRoot)
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if ($resolvedTest.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolvedTest -Leaf) -like 'docker-postgresql-test-*' -and $cleanupCode -eq 0) {
        Remove-Item -LiteralPath $resolvedTest -Recurse -Force
    }
    if ($cleanupCode -ne 0) { throw "Nettoyage Docker incomplet. Dossier de test conserve : $testRoot" }
}
