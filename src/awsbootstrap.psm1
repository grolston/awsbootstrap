
function Invoke-GitInstall {
    PARAM()
    BEGIN {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
    }# end BEGIN
    PROCESS {
        if(-NOT(Test-GitApp)){
            ## heavily pulled from https://github.com/tomlarse/Install-Git/blob/master/Install-Git/Install-Git.ps1
            ## only run if on a Windows OS
            if (Test-WindowsOS){
                $gitExePath = "$env:ProgramFiles\Git\bin\git.exe"
                foreach ($asset in (Invoke-RestMethod https://api.github.com/repos/git-for-windows/git/releases/latest).assets) {
                    if ($asset.name -match 'Git-\d*\.\d*\.\d*.\d*-64-bit\.exe') {
                        $dlurl = $asset.browser_download_url
                    }
                }# end foreach
                
                if (!(Test-Path $gitExePath -ErrorAction SilentlyContinue)) {
                    Remove-Item -Force $env:TEMP\git-stable.exe -ErrorAction SilentlyContinue
                }# end if   
                try{
                    Invoke-WebRequest -Uri $dlurl -OutFile $env:TEMP\git-stable.exe -ErrorAction Stop
                }
                catch{
                    Write-Error "Failed to download git.exe" -ErrorAction Stop
                }# end try-catch
                try {
                    Start-Process -Wait $env:TEMP\git-stable.exe -ArgumentList /silent -ErrorAction Stop
                    Write-Host "Installation complete!" -ForegroundColor Green
                }
                catch{
                    Write-Error "Failed to install git.exe" -ErrorAction Stop
                }# end try-catch
            }
            else{
                Write-Host "This script is currently only supported on the Windows operating system." 
                Write-Host "If running Linux, use packagement solution to install."
                Write-Host "If running MacOS, use brew and using Xcode command line tools run 'git --version' and you should be prompted to install."
            }
        }
        else {
            Write-Host "Git correctly installed"
        }
    }# end PROCESS
    END {}# end END
}# end Invoke-GitInstall
Export-ModuleMember -Function Invoke-GitInstall

function Set-GitPath {
<#
.Synopsis
   Sets the path for Windows OS for Git.exe installations. Note this
   script requires an elevated session (runas admin).
.DESCRIPTION
   Sets the path for Windows OS Git.exe installations
   looking at $env:PATH checking for "$env:ProgramFiles\Git\cmd"
   to be in the path. This functions requires the session to be
   running under elevated privileges.
.EXAMPLE
   Set-Path
#>
    [CmdletBinding(SupportsShouldProcess=$true, 
                  ConfirmImpact='Medium')]
    PARAM()
    if (Test-WindowsOS){
        ## verify git is installed prior to setting path
        if(Test-GitApp){
            ## git is installed, test if path is set in system path
            if(!(Test-GitPath)){
                if(Test-IsAdmin){
                $GitPath = "$env:ProgramFiles\Git\cmd"
                [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$GitPath", [EnvironmentVariableTarget]::Machine)
                }
                else {
                    Write-Warning "To set path you will need to run session as admin"
                    Write-Warning "Path not set for Git installation"
                }
            }
            else {
                Write-Host "Git Path already set"
            }
        }
        else
        {
            Write-Warning "Cannot set path until Git is installed. Please run Invoke-GitInstall"
        }
    }# end if Windows OS
    else {
        Write-Host "Set-GitPath is only applicable to Windows OS."
    }
}# end Set-GitPath
Export-ModuleMember -Function Set-GitPath

function Test-GitApp {
<#
.Synopsis
   Test if git application is installed on windows.
.DESCRIPTION
   Checks to see if git is installed under ProgramFiles\Git\cmd which
   is the typical universal install location. The test is to see if git
   can be used via commandline in a common use-case scenario. If git is
   not installed as described, the test will return a false boolean
.EXAMPLE
   Set-Path
#>
    [CmdletBinding(SupportsShouldProcess=$true, 
                  ConfirmImpact='Medium')]
    PARAM()
    # Tests the Installation of Git
    if (Test-WindowsOS){
        Write-Verbose "System identified as Windows OS."
        $GitPath = "$env:ProgramFiles\Git\cmd"
        if(!(Test-Path -Path "$GitPath\git.exe" -ErrorAction SilentlyContinue)){
            return $false
        }
        else {
            return $true
        }# end if
    }# end if IsWindows
    else {
        ## leverage command -v to see if git is installed on Linux or Mac
        if(!(Invoke-Command -scriptblock {command -v git} -ErrorAction SilentlyContinue)){
            return $false
        }
        else {
            return $true
        }
    }# end elseif Linux or Mac OS
}# end Test-GitApp

function Test-GitPath {
    ## Only for Windows do we need to check
    [CmdletBinding(SupportsShouldProcess=$true, 
                  ConfirmImpact='Medium')]
    PARAM()

    ## run only on Windows OS
    if (Test-WindowsOS){
        $GitPath = "$env:ProgramFiles\Git\cmd"
        if(($env:Path).Contains($GitPath)){
            return $true
        }
        else {
            return $false
        }# end if env:Path
    }
    else {
        ## system in either Linux or Mac
        ## and path is not an issue
        return $true
    }# end if-else
}# end Test-GitPath

function Test-GitInstallation {
    BEGIN {}# end BEGIN
    PROCESS {
        if(!(Test-GitApp)) {
                Write-Warning "Git application not installed, please run Invoke-GitInstall to setup Git.exe"
                return $false  
        }# end if
           
        if(!(Test-GitPath)){
            if(Test-WindowOS){ 
                Write-Warning "Git application not found under env:PATH, please run Set-GitPath to complete Git configuration"
                return $false
            }
        }
        return $true
    }# end PROCESS
    END {}# end END
}# end Test-GitInstallation

function Test-IsAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}# end Test-IsAdmin

function Test-WindowsOS {
    if ((!($IsLinux) -AND (!($IsMacOS)))){
        return $true
    }
    else {
        return $false
    }# end if-else
}# end Test-WindowsOS
