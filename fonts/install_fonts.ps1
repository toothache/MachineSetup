[CmdletBinding(SupportsShouldProcess)]

$FontName = "Meslo"
$FontsDownloadDir = Join-Path (Get-Location) "download_fonts"

# New-Item -ItemType Directory $FontsDownloadDir

function ListFonts() {
    $master = Invoke-WebRequest "https://api.github.com/repos/ryanoasis/nerd-fonts/branches/master" -UseBasicParsing |
        ConvertFrom-Json

    $patchedFonts = Invoke-WebRequest $master.commit.commit.tree.url -UseBasicParsing |
        ConvertFrom-Json |
        ForEach-Object { $_.tree } |
        Where-Object { $_.path -eq "patched-fonts" }
    
    $fonts = Invoke-WebRequest $patchedFonts.url -UseBasicParsing |
        ConvertFrom-Json |
        ForEach-Object { $_.tree } |
        Where-Object { $_.type -eq "tree" }

    return $fonts
}

function ListFontVariants() {
    param(
        $Font
    )

    return Invoke-WebRequest "$($Font.url)?recursive=true" -UseBasicParsing |
        ConvertFrom-Json |
        ForEach-Object { $_.tree } |
        Where-Object { $_.type -eq "blob" }
}

function FilterFont() {
    param(
        $Font,
        $Extension = ".ttf",
        $Includes = @("Complete", "Windows Compatible"),
        $Excludes = @("Font Awesome", "Font Linux", "Octicons", "Pomicons", "Nerd Font.*Mono")
    )

    $path = $Font.path
    $name = Split-Path $path -Leaf

    if (-Not $path.EndsWith($Extension)) {
        return $False
    }

    $ok = $True
    foreach ($include in $Includes) {
        if (-Not ($name.Contains($include))) {
            $ok = $False
            break
        }
    }

    foreach ($exclude in $Excludes) {
        if ($name -match "^.*$exclude.*$") {
            $ok = $False
            break
        }
    }

    return $ok
}

ListFonts |
    Where-Object { $_.path -eq $FontName } |
    ForEach-Object { ListFontVariants $_ } |
    Where-Object { FilterFont $_ } |
    ForEach-Object -Parallel {
    ForEach-Object {
        $Font = $_
        $FontDirectory = $FontsDownloadDir

        $filename = Split-Path $Font.path -Leaf
        $fontpath = Join-Path $FontDirectory $filename
        
        Write-Host "Downloading font: $filename"

        $blob = Invoke-WebRequest $Font.url -UseBasicParsing |
            ConvertFrom-Json

        if ($blob.encoding -ne "base64") {
            Write-Error "Unexpected error. Blob content should be encoded with Base64."
        }
        
        $bytes = [Convert]::FromBase64String($blob.content)
        [IO.File]::WriteAllBytes($fontpath, $bytes)
    }

$fontFiles = Get-ChildItem $FontsDownloadDir -Filter "*.ttf"

$fonts = $null
foreach ($fontFile in $fontFiles) {
    if (!$fonts) {
        $shellApp = New-Object -ComObject shell.application
        $fonts = $shellApp.NameSpace(0x14)
    }
    $fonts.CopyHere($fontFile.FullName)
}

