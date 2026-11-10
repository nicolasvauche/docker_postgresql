param(
    [Parameter(Position = 0)]
    [ValidateSet('init', 'start', 'stop', 'status', 'logs', 'psql', 'check', 'pull', 'backup', 'restore')]
    [string]$Action = 'start',
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CommandArgs = @()
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Docker {
    param([string[]]$DockerArgs)
    & docker @DockerArgs
    if ($LASTEXITCODE -ne 0) { throw "Docker a echoue (code $LASTEXITCODE)." }
}

Push-Location $PSScriptRoot
try {
    if ($Action -ne 'psql' -and $Action -ne 'restore' -and $CommandArgs.Count -gt 0) {
        throw "La commande $Action n'accepte pas d'arguments."
    }
    if ($Action -eq 'restore' -and $CommandArgs.Count -ne 2) {
        throw 'Utilisation : ./dev.ps1 restore backups/fichier.dump nouvelle_base'
    }
    if ($Action -eq 'init') {
        if (Test-Path -LiteralPath .env) {
            Write-Host '.env existe deja : conserve sans modification.'
        } else {
            $bytes = New-Object byte[] 24
            $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
            try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
            $password = [BitConverter]::ToString($bytes).Replace('-', '').ToLowerInvariant()
            $template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '.env.example'))
            $template = $template.Replace('POSTGRES_PASSWORD=', "POSTGRES_PASSWORD=$password")
            [IO.File]::WriteAllText((Join-Path $PSScriptRoot '.env'), $template, [Text.UTF8Encoding]::new($false))
            Write-Host '.env cree avec un mot de passe aleatoire, enregistre dans .env a la ligne POSTGRES_PASSWORD. Vous pouvez adapter la version et le port avant start.'
        }
        return
    }

    $os = & docker info --format '{{.OSType}}'
    if ($LASTEXITCODE -ne 0 -or $os -ne 'linux') { throw 'Demarrez Docker Desktop en mode conteneurs Linux.' }
    $json = & docker compose config --format json
    if ($LASTEXITCODE -ne 0) { throw 'Configuration invalide. Lancez ./dev.ps1 init et verifiez .env.' }
    $config = ($json -join "`n") | ConvertFrom-Json
    $service = $config.services.postgres
    if ($service.image -notmatch '^postgres:([1-9][0-9]+)(\.[0-9]+)?-bookworm$') {
        throw 'POSTGRES_VERSION doit etre une version majeure (16) ou exacte (16.15), sans latest ni prerelease.'
    }
    $dbUser = [string]$service.environment.POSTGRES_USER
    $database = [string]$service.environment.POSTGRES_DB
    switch ($Action) {
        'start' { Invoke-Docker @('compose', 'up', '-d', '--wait', '--wait-timeout', '120', 'postgres') }
        'stop' { Invoke-Docker @('compose', 'down') }
        'status' { Invoke-Docker @('compose', 'ps') }
        'logs' { Invoke-Docker @('compose', 'logs', '-f', '--tail', '100', 'postgres') }
        'pull' { Invoke-Docker @('compose', 'pull', 'postgres') }
        'psql' {
            Invoke-Docker (@('compose', 'exec', 'postgres', 'psql', '-X', '--username', $dbUser, '--dbname', $database, '--set', 'ON_ERROR_STOP=1') + $CommandArgs)
        }
        'check' {
            # TCP verifies authentication as well as SQL, unlike pg_isready alone.
            # Send shell code through stdin to preserve quotes on PowerShell 5.1.
            'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql -X -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -c "SELECT version(), current_database(), current_user;"' |
                & docker compose exec -T postgres sh -se
            if ($LASTEXITCODE -ne 0) { throw "Verification PostgreSQL en echec (code $LASTEXITCODE)." }
        }
        'backup' {
            $id = [Guid]::NewGuid().ToString('N')
            $remote = "/tmp/backup-$id.dump"
            $local = Join-Path $PSScriptRoot ("backups/{0}-{1}.dump" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $id)
            New-Item -ItemType Directory -Force -Path (Join-Path $PSScriptRoot 'backups') | Out-Null
            try {
                Invoke-Docker @('compose', 'exec', '-T', 'postgres', 'pg_dump', '--username', $dbUser, '--dbname', $database, '--format=custom', '--file', $remote)
                # Never pipe a binary dump through Windows PowerShell text redirection.
                Invoke-Docker @('compose', 'cp', "postgres:$remote", $local)
                Write-Host "Sauvegarde creee : $local"
            } finally {
                Invoke-Docker @('compose', 'exec', '-T', 'postgres', 'rm', '-f', $remote)
            }
        }
        'restore' {
            $source = (Resolve-Path -LiteralPath $CommandArgs[0]).Path
            if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw 'Archive introuvable.' }
            $target = $CommandArgs[1]
            if ($target -notmatch '^[a-z][a-z0-9_]{0,62}$') { throw 'Nom de base : 1 a 63 caracteres, minuscules, chiffres et underscores, commencant par une lettre.' }
            $remote = '/tmp/restore-' + [Guid]::NewGuid().ToString('N') + '.dump'
            try {
                Invoke-Docker @('compose', 'cp', $source, "postgres:$remote")
                Invoke-Docker @('compose', 'exec', '-T', 'postgres', 'pg_restore', '--list', $remote)
                # createdb deliberately fails if the target already exists.
                Invoke-Docker @('compose', 'exec', '-T', 'postgres', 'createdb', '--username', $dbUser, '--template=template0', $target)
                Invoke-Docker @('compose', 'exec', '-T', 'postgres', 'pg_restore', '--username', $dbUser, '--dbname', $target, '--no-owner', '--no-privileges', '--single-transaction', '--exit-on-error', $remote)
                Write-Host "Sauvegarde restauree dans $target."
            } finally {
                Invoke-Docker @('compose', 'exec', '-T', 'postgres', 'rm', '-f', $remote)
            }
        }
    }
} finally {
    Pop-Location
}
