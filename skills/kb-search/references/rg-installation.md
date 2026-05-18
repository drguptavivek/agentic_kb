# ripgrep Installation Reference

Use this only when `rg` / ripgrep is missing.

## macOS

Preferred:

```bash
brew install ripgrep
```

If Homebrew is missing, install Homebrew first from https://brew.sh, then run the command above.

## Verify

```bash
rg --version
```

## Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install ripgrep
```

## Fedora

```bash
sudo dnf install ripgrep
```

## Arch Linux

```bash
sudo pacman -S ripgrep
```

## Windows

Use this only when Windows/PowerShell is relevant:

```powershell
winget install BurntSushi.ripgrep.MSVC
```

Alternatives:

```powershell
choco install ripgrep
scoop install ripgrep
```

