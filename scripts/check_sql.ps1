[CmdletBinding()]
param([string]$Image = 'tricgabay-sqlcheck:pg17', [switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $SkipBuild) {
  docker build -t $Image -f (Join-Path $PSScriptRoot 'sqlcheck/Dockerfile') (Join-Path $PSScriptRoot 'sqlcheck')
  if ($LASTEXITCODE -ne 0) { throw 'SQL parser image build failed.' }
}
docker run --rm --network none --mount "type=bind,source=$repoRoot,target=/workspace,readonly" $Image
if ($LASTEXITCODE -ne 0) { throw 'SQL parser rejected one or more files.' }
