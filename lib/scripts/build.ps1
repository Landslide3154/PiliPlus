param(
    [string]$Arg = '',
    [string]$UpstreamBase = ''
)

try {
    $versionCode = [int](git rev-list --count HEAD).Trim()

    $commitHash = (git rev-parse HEAD).Trim()

    # 从 pubspec 读取主版本号（如 2.1.6）
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

    # 上游补丁版：上游用四段 tag 发补丁（2.1.6 → 2.1.6.1 → 2.1.6.2），
    # 本 fork 版本 = 上游同主版本的最新 tag + 一个构建序号（2.1.6.2 → 2.1.6.2.1 → 2.1.6.2.2）。
    $upstreamRepo = 'https://github.com/bggRGjQaUbCoE/PiliPlus.git'
    $versionBase = $baseVersion
    if ([string]::IsNullOrWhiteSpace($UpstreamBase)) {
        $refs = git ls-remote --tags --refs $upstreamRepo 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "cannot read upstream tags ($upstreamRepo); pass -UpstreamBase to override"
        }
        $basePattern = '^' + [regex]::Escape($baseVersion) + '(\.\d+)*$'
        $maxUpstream = $null
        foreach ($ref in $refs) {
            if ($ref -match '^[0-9a-f]+\s+refs/tags/(.+)$') {
                $tag = $matches[1]
                if ($tag -match $basePattern) {
                    try { $v = [version]$tag } catch { continue }
                    if ($null -eq $maxUpstream -or $v -gt $maxUpstream) { $maxUpstream = $v }
                }
            }
        }
        if ($null -eq $maxUpstream) {
            throw "upstream has no tag for $baseVersion"
        }
        $versionBase = $maxUpstream.ToString()
    } else {
        $versionBase = $UpstreamBase
    }

    # 本软件版本号 = 上游 tag + 构建序号（2.1.6.2.1 → 2.1.6.2.2 → ...），按已有 tag 取下一个号
    $maxSeq = 0
    $tagPattern = '^v' + [regex]::Escape($versionBase) + '\.(\d+)$'
    foreach ($t in (git tag)) {
        if ($t -match $tagPattern) {
            $seq = [int]$matches[1]
            if ($seq -gt $maxSeq) { $maxSeq = $seq }
        }
    }
    $versionName = "$versionBase.$($maxSeq + 1)"

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
