param(
    [Parameter(Mandatory = $true)]
    [string]$SourceVcpkgDir,

    [Parameter(Mandatory = $true)]
    [string]$TargetVcpkgDir
)

if (-not (Test-Path $SourceVcpkgDir)) {
    throw "Pinned vcpkg checkout not found at expected path: $SourceVcpkgDir"
}

$targetRoot = Split-Path -Parent $TargetVcpkgDir
$mutexInput = [System.Text.Encoding]::UTF8.GetBytes($TargetVcpkgDir)
$mutexHash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash($mutexInput)).Replace("-", "")
$mutex = [System.Threading.Mutex]::new($false, "Global\ezvcpkg-stage-$mutexHash")

if (-not $mutex.WaitOne([TimeSpan]::FromMinutes(5))) {
    throw "Timed out waiting to stage vcpkg tree at $TargetVcpkgDir"
}

try {
    New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null

    if (Test-Path $TargetVcpkgDir) {
        Remove-Item -Recurse -Force $TargetVcpkgDir
    }

    Copy-Item -LiteralPath $SourceVcpkgDir -Destination $targetRoot -Recurse -Force

    if (-not (Test-Path (Join-Path $TargetVcpkgDir "scripts/cmake/vcpkg_fixup_pkgconfig.cmake"))) {
        throw "Failed to stage vcpkg tree at expected path: $TargetVcpkgDir"
    }

    & "$PSScriptRoot\disable-vcpkg-fixup-pkgconfig.ps1" -VcpkgDir $TargetVcpkgDir
}
finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
