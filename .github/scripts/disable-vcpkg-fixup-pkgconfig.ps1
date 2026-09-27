param(
    [Parameter(Mandatory = $true)]
    [string]$VcpkgDir
)

$pkgConfigScript = Join-Path $VcpkgDir "scripts/cmake/vcpkg_fixup_pkgconfig.cmake"

if (-not (Test-Path $pkgConfigScript)) {
    throw "vcpkg_fixup_pkgconfig.cmake not found at expected path: $pkgConfigScript"
}

Write-Host "Patching vcpkg_fixup_pkgconfig() to a no-op: $pkgConfigScript"

$scriptBytes = [System.IO.File]::ReadAllBytes($pkgConfigScript)
$hasUtf8Bom = $scriptBytes.Length -ge 3 -and $scriptBytes[0] -eq 0xEF -and $scriptBytes[1] -eq 0xBB -and $scriptBytes[2] -eq 0xBF
$encoding = [System.Text.UTF8Encoding]::new($hasUtf8Bom)
$scriptContent = $encoding.GetString($scriptBytes)
$replacementBlock = "function(vcpkg_fixup_pkgconfig)`nendfunction()`n"

if ($scriptContent -eq $replacementBlock -or $scriptContent -eq $replacementBlock.Replace("`n", "`r`n")) {
    Write-Host "vcpkg_fixup_pkgconfig.cmake already patched."
    return
}

[System.IO.File]::WriteAllText($pkgConfigScript, $replacementBlock, $encoding)

Write-Host "Successfully patched vcpkg_fixup_pkgconfig.cmake."
