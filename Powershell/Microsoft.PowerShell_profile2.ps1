#oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/stelbent-compact.minimal.omp.json" | Invoke-Expression

#Import-WslCommand "apt", "awk", "emacs", "find", "grep", "head", "less", "ls", "man", "sed", "seq", "ssh", "sudo", "tail", "touch", "vim"

Invoke-Expression (&starship init powershell) #adds starship to pwsh, breaks posh theme tho

#$ENV:STARSHIP_CONFIG = "$HOME\example\non\default\path\starship.toml"
