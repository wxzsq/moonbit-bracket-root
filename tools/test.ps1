param(
  [ValidateSet('js')][string]$Target = 'js',
  [switch]$Demo
)
$ErrorActionPreference = 'Stop'
$taskProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$toolchainRoot = Join-Path $PSScriptRoot 'moon-20260921'
$moonExe = Join-Path $toolchainRoot 'bin\moon.exe'
if (-not (Test-Path -LiteralPath $moonExe)) { throw 'Project-local MoonBit toolchain is missing. Read tools/TOOLCHAIN.md.' }
$runName = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$runRoot = Join-Path $taskProjectRoot ('build-runs\' + $runName)
New-Item -ItemType Directory -Path (Join-Path $runRoot 'tmp') -Force | Out-Null
$oldMoonHome = $env:MOON_HOME
$oldTemp = $env:TEMP
$oldTmp = $env:TMP
$oldPath = $env:PATH
try {
  $env:MOON_HOME = $toolchainRoot
  $env:TEMP = Join-Path $runRoot 'tmp'
  $env:TMP = $env:TEMP
  $env:PATH = (Join-Path $toolchainRoot 'bin') + ';' + $oldPath
  & $moonExe -C $taskProjectRoot --target-dir (Join-Path $runRoot 'test') test --target $Target --frozen --deny-warn 2>&1 | Tee-Object -FilePath (Join-Path $runRoot 'test.log')
  if ($LASTEXITCODE -ne 0) { throw "MoonBit tests failed; retained logs: $runRoot" }
  if ($Demo) {
    & $moonExe -C $taskProjectRoot --target-dir (Join-Path $runRoot 'demo') run --target $Target --frozen cmd/main 2>&1 | Tee-Object -FilePath (Join-Path $runRoot 'demo.log')
    if ($LASTEXITCODE -ne 0) { throw "MoonBit demo failed; retained logs: $runRoot" }
  }
  Write-Output "Retained build and logs: $runRoot"
} finally {
  $env:MOON_HOME = $oldMoonHome
  $env:TEMP = $oldTemp
  $env:TMP = $oldTmp
  $env:PATH = $oldPath
}
