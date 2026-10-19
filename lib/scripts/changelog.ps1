param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$Source = 'CHANGELOG.md',
    [string]$Output = 'changelog_body.md'
)

$ErrorActionPreference = 'Stop'

# 从 CHANGELOG.md 里取 "## v{版本}" 到下一个二级标题之间的内容，作为 Release 说明。
# 应用内「检查更新」直接展示 release body，所以这份说明就是用户看到的更新日志。
$body = $null
if (Test-Path -Path $Source) {
    $lines = Get-Content -Path $Source -Encoding UTF8
    $heading = '^##\s+v?' + [regex]::Escape($Version) + '\s*$'
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $heading) {
            $start = $i + 1
            break
        }
    }
    if ($start -ge 0) {
        $section = New-Object System.Collections.Generic.List[string]
        for ($j = $start; $j -lt $lines.Count; $j++) {
            if ($lines[$j] -match '^##\s') { break }
            $section.Add($lines[$j])
        }
        $body = ($section -join "`n").Trim()
    }
}

if ([string]::IsNullOrWhiteSpace($body)) {
    Write-Host "section for v$Version not found in $Source, fallback to default body"
    $body = "自动构建版本 v$Version`n提交: $env:GITHUB_SHA"
}

$text = $body + "`n"
[System.IO.File]::WriteAllText(
    (Join-Path (Get-Location) $Output),
    $text,
    (New-Object System.Text.UTF8Encoding($false))
)
Write-Host "changelog written to $Output"
