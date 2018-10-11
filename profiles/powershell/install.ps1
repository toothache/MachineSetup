function Test-ProfilePath {
    $path = [System.IO.Path]::GetDirectoryName($profile)
    if (-not (Test-Path -path $path)) {
        New-Item -path $path -ItemType Directory | Out-Null
    }
}

function Copy-Profile([string] $name) 
{
    $filename = ""
    if (-not $name) {
        $filename = "profile.ps1"
    }
    else {
        $filename = $name + "_profile.ps1"
    }

    $profileFullPath = (Join-Path ([System.IO.Path]::GetDirectoryName($profile)) $filename)

    Write-Host "Install profile.ps1 into $profileFullPath."
    Copy-Item -path profile.ps1 -Destination $profileFullPath
}

function Check-Module([string] $name) {
    if (-not (Get-Module -ListAvailable -Name $name)) {
        Write-Warning "Module $name is not installed."
        Write-Host "Installing module $name..."
        Start-Process powershell -Verb runAs -ArgumentList "-noprofile Install-Module $name" -Wait
    }
    else {
        Write-Host "Module $name is installed."
    }
}

$requirements = Get-Content .\requirements.json | ConvertFrom-Json
foreach ($module in $requirements.dependencies.modules) {
    Check-Module($module)
}

Test-ProfilePath

foreach ($profilename in $requirements.profiles) {
    Copy-Profile($profilename)
}