param(
    [string]$Arg = ''
)

try {
    $versionCode = [int](git rev-list --count HEAD).Trim()

    $commitHash = (git rev-parse HEAD).Trim()

    # 从 pubspec 读取上游基础版本号（如 2.1.0）
    $baseVersion = $null
    foreach ($line in (Get-Content -Path 'pubspec.yaml' -Encoding UTF8)) {
        if ($line -match '^\s*version:\s*([\d\.]+)') {
            $baseVersion = $matches[1]
            break
        }
    }
    if ($null -eq $baseVersion) {
        throw 'version not found'
    }

    # 本软件版本号 = 上游版本 + 两位序号（2.1.0.01 → 2.1.0.02 → ... → 2.1.0.99 → 2.1.0.100）
    # 根据已有 tag 计算下一个序号，保证单调递增且语义有序
    $maxSeq = 0
    $tagPattern = '^v' + [regex]::Escape($baseVersion) + '\.(\d+)$'
    foreach ($t in (git tag)) {
        if ($t -match $tagPattern) {
            $seq = [int]$matches[1]
            if ($seq -gt $maxSeq) { $maxSeq = $seq }
        }
    }
    $versionName = "$baseVersion.$('{0:D2}' -f ($maxSeq + 1))"

    # pubspec version 保持三段（Dart 不支持 2.1.0.01 四段格式），
    # 完整版本号仅用于产物命名 / pili.name / 更新判断
    $updatedContent = foreach ($line in (Get-Content -Path 'pubspec.yaml' -Encoding UTF8)) {
        if ($line -match '^\s*version:\s*([\d\.]+)') {
            "version: $baseVersion+$versionCode"
        }
        else {
            $line
        }
    }

    $updatedContent | Set-Content -Path 'pubspec.yaml' -Encoding UTF8

    $buildTime = [int]([DateTimeOffset]::Now.ToUnixTimeSeconds())

    $data = @{
        'pili.name' = $versionName
        'pili.code' = $versionCode
        'pili.hash' = $commitHash
        'pili.time' = $buildTime
    }

    $data | ConvertTo-Json -Compress | Out-File 'pili_release.json' -Encoding UTF8

    Add-Content -Path $env:GITHUB_ENV -Value "version=$versionName"
    Add-Content -Path $env:GITHUB_ENV -Value "versionCode=$versionCode"
}
catch {
    Write-Error "Prebuild Error: $($_.Exception.Message)"
    exit 1
}
