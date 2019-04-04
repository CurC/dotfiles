# Plagiarized from: https://github.com/christianrondeau/dotfiles

In Powershell:
```
cd ~/
Set-ExecutionPolicy RemoteSigned -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# Restart console
choco install git putty -y
# Restart console
git clone https://github.com/crtschin/dotfiles $env:HOMEDRIVE$env:HOMEPATH/dotfiles
cd dotfiles
~/install.ps1
```

To install: https://medium.com/@borekb/zsh-via-msys2-on-windows-3964a943b1ce