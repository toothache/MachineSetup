if (test-path env:\SkipLoadProfile) {
    return
}


function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}


function Show-Welcome {
    $time = Get-Date
    $psVersion= $host.Version.Major
    $curUser= (Get-ChildItem Env:\USERNAME).Value
    $curComp= (Get-ChildItem Env:\COMPUTERNAME).Value

    $defaultForegroundColor = "Green"

    Write-Host "Greetings, $curUser!" -foregroundColor $defaultForegroundColor
    Write-Host "It is: $($time.ToLongDateString())" -foregroundColor $defaultForegroundColor
    Write-Host "You're running PowerShell version: $psVersion" -foregroundColor $defaultForegroundColor
    if (test-path env:\VSCODE*)
    {
        Write-Host "You're running Powershell inside VS code." -foregroundColor $defaultForegroundColor
    }

    Write-Host "Your computer name is: $curComp" -foregroundColor $defaultForegroundColor
    Write-Host "The host is: $($host.name)" -ForegroundColor $defaultForegroundColor
    Write-Host "Happy scripting!" `n -foregroundColor $defaultForegroundColor
}


function ChangeConsoleTheme()
{
    Import-Module oh-my-posh
    Set-Theme Paradox
}

Import-Module ZLocation
Import-Module posh-git

if (-not (test-path env:\SkipLoadTheme)) {
    ChangeConsoleTheme
}
else {
    Write-Host "Skip changing themes."
}

Show-Welcome;

$curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
if (Test-Administrator) {
    if ($curPath.ToLower() -eq "c:\windows\system32") {
        Set-Location d:\source
    }
} elseif ($curPath.ToLower() -eq $Home.ToLower()) {
    Set-Location d:\source
}


$CONDA_ROOT = "C:\Users\yatengh\Miniconda3"
$Env:CONDA_EXE = "$CONDA_ROOT\Scripts\conda.exe"

Import-Module "$CONDA_ROOT\shell\condabin\Conda.psm1"
conda activate base


# PatchPrompt
Add-CondaEnvironmentToPrompt
