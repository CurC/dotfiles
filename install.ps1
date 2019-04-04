#Requires -RunAsAdministrator

Set-StrictMode -version Latest
Set-ExecutionPolicy Bypass
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Write-Error([string]$message) {
    [Console]::ForegroundColor = 'red'
    [Console]::Error.WriteLine($message)
    [Console]::ResetColor()
}

function Write-Warn([string]$message) {
    [Console]::ForegroundColor = 'yellow'
    [Console]::Error.WriteLine($message)
    [Console]::ResetColor()
}

function StowFile([String]$link, [String]$target) {
	$file = Get-Item $link -ErrorAction SilentlyContinue

	if($file) {
		if ($file.LinkType -ne "SymbolicLink") {
			Write-Error "$($file.FullName) already exists and is not a symbolic link"
			return
		} elseif ($file.Target -ne $target) {
			Write-Error "$($file.FullName) already exists and points to '$($file.Target)', it should point to '$target'"
			return
		} else {
			Write-Verbose "$($file.FullName) already linked"
			return
		}
	} else {
	$folder = Split-Path $link
		if(-not (Test-Path $folder)) {
			Write-Verbose "Creating folder $folder"
			New-Item -Type Directory -Path $folder
		}
	}

	Write-Verbose "Creating link $link to $target"
	(New-Item -Path $link -ItemType SymbolicLink -Value $target -ErrorAction Continue).Target
}

function Stow([String]$package, [String]$target) {
	if(-not $target) {
		Write-Error "Could not define the target link folder of $package"
	}

	ls $DotFilesPath\$package | % {
		if(-not $_.PSIsContainer) {
			StowFile (Join-Path -Path $target -ChildPath $_.Name) $_.FullName
		}
	}
}

function Install([String]$package) {
	if(-not ((choco list $package --exact --local-only --limitoutput) -like "$package*")) {
		Write-Verbose "Installing package $package"
		choco install $package -y
	} else {
		Write-Verbose "Package $package already installed"
	}
}

function Unzip([string]$zipfile, [string]$outpath) {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function DownloadFile([string]$url, [string]$target) {
		if(Test-Path $target) {
			Write-Verbose "$target already downloaded"
		} else {
			Write-Verbose "Downloading $url to $target"
			try {
				(New-Object System.Net.WebClient).DownloadFile($url, $target)
			} catch {
				Write-Error $_
			}
		}
}

function SetEnvVariable([string]$target, [string]$name, [string]$value) {
	$existing = [Environment]::GetEnvironmentVariable($name,$target)
	if($existing) {
		Write-Verbose "Environment variable $name already set to '$existing'"
	} else {
		Write-Verbose "Adding the $name environment variable to '$value'"
		[Environment]::SetEnvironmentVariable($name, $value, $target)
	}
}

if(-not $env:HOME) {
	$env:HOME = "$($env:HOMEDRIVE)$($env:HOMEPATH)"
}

$DotFilesPath = Split-Path $MyInvocation.MyCommand.Path
pushd $DotFilesPath
try {
	# ConEmu
    # Stow conemu $env:APPDATA

	Git
    if(!(Test-Path $env:HOME/.gitconfig)) {
        Copy-Item ./git/.gitconfig $env:HOME/.gitconfig
        Copy-Item ./git/.gitignore_global $env:HOME/.gitignore_global
    } else {
        Write-Warn ".gitconfig already exists (cannot symlink since it's not supported in GitExtensions"
    }
    StowFile "$env:HOME\.bash_profile" (Get-Item "bash\.bash_profile").FullName
    StowFile "$env:HOME\.bashrc" (Get-Item "bash\.bashrc").FullName
    StowFile "$env:HOME\.zshrc" (Get-Item "bash\.zshrc").FullName
    StowFile "$env:HOME\antigen.zsh" (Get-Item "bash\antigen.zsh").FullName

    DownloadFile "https://github.com/powerline/fonts/archive/master.zip" "$env:HOME\Downloads\powerline.zip"
    Unzip "$env:HOME\Downloads\powerline.zip" "$env:HOME\Downloads\powerline"

    & "$env:HOME\Downloads\powerline\fonts-master\install.ps1"

    Install 7zip
    Install conemu
    Install dart-sdk
    Install docker-desktop
    Install filezilla
    Install firacode
    Install Firefox
    Install GoogleChrome
    Install msys2
    Install nodejs
    Install paint.net
    Install postman
    Install putty
    Install screentogif
    Install vscode
    Install sql-server-management-studio
    Install spotify

	Add-Content C:\tools\msys64\etc\profile "`ncd $HOME`nsource .bashrc"
	(Get-Content C:\tools\msys64\etc\nsswitch.conf).replace('db_home: cygwin desc',
		'db_home: windows cygwin desc') | Set-Content C:\tools\msys64\etc\nsswitch.conf
	(Get-Content C:\tools\msys64\etc\pacman.conf).replace('# after the header, and they will be used before the default mirrors.',
		"# after the header, and they will be used before the default mirrors.`n`n
		[git-for-windows]`n
		Server = https://wingit.blob.core.windows.net/x86-64"
		) | Set-Content C:\tools\msys64\etc\pacman.conf

} finally {
	popd
}