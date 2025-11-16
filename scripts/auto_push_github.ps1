<#
自动推送到 GitHub 的 PowerShell 脚本
用法示例：
  .\auto_push_github.ps1 -Message "更新: 修复 bug" -Branch main
说明：推荐先配置好本机的 Git 凭据（Git Credential Manager 或 GitHub CLI `gh auth login`），脚本只执行 git add/commit/push。
#>
param(
    [string]$Message = "Auto commit",
    [string]$Branch = "",
    [string]$Remote = "origin",
    [switch]$IncludeUntracked
)

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "Git 未安装或不可用，请先安装并配置 Git。"
        exit 1
    }

    # 确定 repo 根目录（脚本位于 scripts 子目录）
    $repoRoot = (Get-Item $PSScriptRoot).Parent.FullName
    Set-Location $repoRoot

    # 获取当前分支（如果未提供）
    if ([string]::IsNullOrWhiteSpace($Branch)) {
        $Branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
        if ([string]::IsNullOrWhiteSpace($Branch)) {
            Write-Error "无法检测当前分支，请通过 -Branch 指定分支。"
            exit 1
        }
    }

    Write-Host "Repository: $repoRoot"
    Write-Host "Remote: $Remote    Branch: $Branch"

    # 添加更改
    if ($IncludeUntracked) {
        git add -A
    } else {
        # 仍然使用 -A 来保证变动被捕获（如果需要不同策略可修改此处）
        git add -A
    }

    $status = git status --porcelain
    if ([string]::IsNullOrWhiteSpace($status)) {
        Write-Host "没有未提交的更改。尝试推送远程分支。"
        git push $Remote $Branch
        if ($LASTEXITCODE -ne 0) { Write-Error "推送失败。"; exit $LASTEXITCODE }
        Write-Host "推送完成。"
        exit 0
    }

    # 提交
    git commit -m "$Message"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "提交失败，可能没有要提交的更改或提交被钩子阻止。"
        exit $LASTEXITCODE
    }

    # 推送
    git push $Remote $Branch --follow-tags
    if ($LASTEXITCODE -ne 0) { Write-Error "推送失败。"; exit $LASTEXITCODE }

    Write-Host "提交并推送完成。"
    exit 0
}
catch {
    Write-Error "发生异常： $_"
    exit 1
}
