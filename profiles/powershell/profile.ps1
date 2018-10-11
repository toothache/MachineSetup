function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Show-Welcome {
    $time = Get-Date
    $psVersion= $host.Version.Major
    $curUser= (Get-ChildItem Env:\USERNAME).Value
    $curComp= (Get-ChildItem Env:\COMPUTERNAME).Value

    Write-Host "Greetings, $curUser!" -foregroundColor $defaultForegroundColor
    Write-Host "It is: $($time.ToLongDateString())" -foregroundColor $defaultForegroundColor
    Write-Host "You're running PowerShell version: $psVersion" -foregroundColor $defaultForegroundColor
    Write-Host "Your computer name is: $curComp" -foregroundColor $defaultForegroundColor
    Write-Host "Happy scripting!" `n -foregroundColor $defaultForegroundColor
}

function Prompt {
    $origLastExitCode = $LastExitCode

    $prompt = ""
    $prompt += Write-Prompt "$env:USERNAME@" -NoNewline -ForegroundColor $defaultForegroundColor

    $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    if ($curPath.ToLower().StartsWith($Home.ToLower())) {
        $curPath = "~" + $curPath.SubString($Home.Length)
    }

    $curDirectory = [System.IO.Path]::GetFileName($curPath)
    $prompt += Write-Prompt $curDirectory -NoNewline -ForegroundColor $directoryColor

    if (Test-Administrator) { # if elevated
        $prompt += Write-Prompt " [ADMIN]" -ForegroundColor $emphasisColor
    }

    $prompt += Write-Prompt "$(if ($PsDebugContext) {' [DBG]'} else {''})" -NoNewline -ForegroundColor $emphasisColor

    $prompt += Write-VcsStatus

    if (Get-GitStatus -Force) {
        # start new line if there're available git status
        $prompt += Write-Prompt "`n"
    }
    else {
        $prompt += Write-Prompt " "
    }

    $prompt += Write-Prompt "$('>' * ($nestedPromptLevel + 1))" -NoNewline -ForegroundColor $defaultForegroundColor

    $host.UI.RawUI.WindowTitle = "User: $curUser | Current DIR: $((Get-Location).Path)"

    $LastExitCode = $origLastExitCode

    Return " "
}

if (-not (test-path env:\VSCODE_PID)) {
    Import-Module PSConsoleTheme
    Set-ConsoleTheme 'Monokai'

    # PSConsoleTheme overrides color definitions
    $defaultForegroundColor = "DarkGreen"
    $directoryColor = "DarkBlue"
    $emphasisColor = "DarkRed"

    Import-Module posh-Git
    $GitPromptSettings.BranchIdenticalStatusToForegroundColor = "DarkBlue"
    $GitPromptSettings.BranchAheadStatusForegroundColor = "DarkGreen"
    $GitPromptSettings.BranchBehindStatusForegroundColor = "DarkRed"
    $GitPromptSettings.BranchForegroundColor = "DarkYellow"
    $GitPromptSettings.WorkingForegroundColor = "DarkYellow"
}
else {
    $defaultForegroundColor = "Green"
    $directoryColor = "Cyan"
    $emphasisColor = "Red"

    Import-Module posh-Git
    $GitPromptSettings.BranchIdenticalStatusToForegroundColor = "Blue"
    $GitPromptSettings.BranchAheadStatusForegroundColor = "Green"
    $GitPromptSettings.BranchBehindStatusForegroundColor = "Red"
    $GitPromptSettings.WorkingForegroundColor = "Yellow"
}

Show-Welcome;

$curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
if (Test-Administrator) {
    if ($curPath.ToLower() -eq "c:\windows\system32") {
        Set-Location ~\Source
    }
}
elseif ($curPath.ToLower() -eq $Home.ToLower()) {
    Set-Location ~\Source
}
