function Test-ProfilePath {
    $path = [System.IO.Path]::GetDirectoryName($profile)
    if (-not (Test-Path -path $path)) {
        New-Item -path $path -ItemType Directory | Out-Null
    }
}

function Copy-Profile([string] $name) {
    $filename = ""
    if (-not $name) {
        $filename = "profile.ps1"
    }
    else {
        $filename = $name + "_profile.ps1"
    }

    $profileFullPath = (Join-Path ([System.IO.Path]::GetDirectoryName($profile)) $filename)

    Write-Host "Install $name into $profileFullPath."
    Copy-Item -path (Join-Path $PSScriptRoot profile.ps1) -Destination $profileFullPath
}

function Copy-Module([string]$path) {
    $modulePath = $env:PSModulePath.split(";")[0]

    if (-not (Test-Path $modulePath)) {
        New-Item -path $modulePath -itemtype directory | Out-Null
    }

    Write-Host("Copying module from $name into $modulePath.")
    Copy-item -path $path -destination $modulePath -Recurse | Out-Null
}

function Check-Module($module) {
    $name = $module.name
    if (-not (Get-Module -ListAvailable -Name $name)) {
        Write-Warning "Module $name is not installed."

        if ($module.provider) {
            if ($module.provider.type -eq "git") {
                $tmpFolder = "$env:TMP/$($module.name)"
                if (Test-Path -path $tmpFolder) {
                    Remove-Item -Recurse -Force $tmpFolder
                }

                Write-Host "Cloning sources from $($module.provider.repo)"

                $command = "git clone $($module.provider.repo) $tmpFolder"
                if ($module.provider.branch) {
                    $command += " --branch $($module.provider.branch)"
                }

                Invoke-Expression $command

                $moduleSrc = Join-Path $tmpFolder $module.provider.path
                Write-Host "Installing module from $moduleSrc."
                Copy-Module $moduleSrc

                Remove-Item -Recurse -Force $tmpFolder | Out-Null
            }
        }
        else {
            Write-Host "Installing module $name from PowerShell Gallery."
            Start-Process powershell -Verb runAs -ArgumentList "-noprofile Install-Module $name" -Wait
        }
    }
    else {
        Write-Host "Module $name is installed."
    }
}

function Copy-VSCodeProfile([string] $name) {
    if (Test-Path -path $env:APPDATA) {
        # Windows
        $profileFullPath = "$env:APPDATA/Code/User"
        if (Test-Path -path $profileFullPath) {
            Write-Host "Install $name into $profileFullPath."
            Copy-Item -path $name -Destination $profileFullPath
        }
    }
    else {
        Write-Warning "Unsupported OS version."
    }
}

$requirements = Get-Content (Join-Path $PSScriptRoot requirements.json) | ConvertFrom-Json
foreach ($module in $requirements.dependencies.modules) {
    Check-Module($module)
}

Test-ProfilePath

foreach ($profilename in $requirements.profiles) {
   Copy-Profile($profilename)
}

foreach ($profilename in Get-ChildItem (Join-Path $PSScriptRoot ../vscode)) {
    Write-Host $profilename.FullName
    Copy-VSCodeProfile($profilename.FullName)
}

# iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"

