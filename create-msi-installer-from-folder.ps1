param(
  [Parameter(Mandatory=$True)]
  [string]$Path,
  [Parameter(Mandatory=$True)]
  [string]$Product,
  [Parameter(Mandatory=$True)]
  [string]$Version,
  [Parameter(Mandatory=$True)]
  [string]$executable,
  [string]$UpgradeGUID,
  [string]$Manufacturer = "Ed-IT Solutions MSI Creator",
  [string]$Contact = "System Administrator",
  [string]$HelpLink = "http://www.example.com",
  [string]$AboutLink = "http://www.example.com",
  [string]$DownloadLink = "http://www.example.com"
)

function step{
  param(
    [Parameter(Mandatory=$True)]
    [string]$message
  )

  $stars = "*" * 60

  $msg = "*" + (" " * (29 - ($message.Length / 2))) + $message + " " * (29 - ($message.Length / 2)) + "*"

  Write-Host $stars
  Write-Host $msg
  Write-Host $stars
}

step -message "Starting Package Creator"

if(!$UpgradeGUID){
  Write-Host "No UpgradeGUID Provided"
  $UpgradeGUID = New-Guid
  Write-Host "To upgrade this package in the future use this guid:"
  $UpgradeGUID
}

$ProjectGUID = New-Guid

Write-Host "Product GUID $ProjectGUID"


step -message "Creating Installer.wixproj"

[xml]$installer = Get-Content "$PSScriptRoot\source\installer.wixproj"

$installer.Project.PropertyGroup[0].OutputName = "$Product ($Version)"
$installer.Project.PropertyGroup[0].ProjectGuid = "$ProjectGUID"
$installer.Project.PropertyGroup[0].ProductVersion = $Version
$installer.Project.PropertyGroup[1].DefineConstants = "Debug;HarvestPath=$Path;ProductVersion=$Version"
$installer.Project.PropertyGroup[2].DefineConstants = "HarvestPath=$Path;ProductVersion=$Version"
$installer.Project.Target[0].HeatDirectory.Directory = $Path



#$installer.ProductName = "$Product ($Version)"

$installer.Save("$PSScriptRoot\build\installer.wixproj")

step -message "Creating Product.wxs"

[xml]$productwxs = Get-Content "$PSScriptRoot\source\product.wxs"

$productwxs.Wix.Product.Name = $Product
$productwxs.Wix.Product.Version = $Version
$productwxs.Wix.Product.Manufacturer = $Manufacturer
$productwxs.Wix.Product.UpgradeCode = $UpgradeGUID

$productwxs.Wix.Product.Directory.Directory[0].Directory.Name = $Product
$productwxs.Wix.Product.Directory.Directory[0].Directory.Component.File.Source = "$Path\$Executable"
$productwxs.Wix.Product.Directory.Directory[1].Component.Shortcut.Name = $Product
$productwxs.Wix.Product.Directory.Directory[1].Component.Shortcut.Description = $Product
$productwxs.Wix.Product.Directory.Directory[1].Component.Shortcut.Target = "[INSTALLDIR]$Executable"
$productwxs.Wix.Product.Directory.Directory[1].Component.RegistryValue.Key = "Software\$Product"

$productwxs.Wix.Product.Icon.SourceFile = "$Path\$Executable"

$productwxs.Wix.Product.Feature.Title = $Product

$productwxs.Wix.Product.Property[0].Value = $Contact
$productwxs.Wix.Product.Property[1].Value = $HelpLink
$productwxs.Wix.Product.Property[3].Value = $AboutLink
$productwxs.Wix.Product.Property[4].Value = $DownloadLink



$productwxs.Save("$PSScriptRoot\build\product.wxs")

step -message "Create Transform"

[xml]$transform = Get-Content "$PSScriptRoot\source\transform.xslt"

$transform.stylesheet.key.match = "wix:Component[contains(wix:File/@Source, '$Executable')]"

$transform.Save("$PSScriptRoot\build\transform.xslt")

step -message "Running WIX"

& "C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" "$PSScriptRoot\build\installer.wixproj"

step -message "Complete!"

Write-Host "Your MSI Has been built."
Write-Host "Find it at $PSScriptRoot\build\Deploy\Release\$Product ($Version).msi"
Write-Host "Your Upgrade GUID is $UpgradeGUID"