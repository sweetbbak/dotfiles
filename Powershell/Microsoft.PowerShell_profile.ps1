#Import Oh-My-Posh
#oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/stelbent-compact.minimal.omp.json" | Invoke-Expression
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/catpushino.omp.json" | Invoke-Expression

#Icons
Import-Module -Name Terminal-Icons

#Syntax

#PS Read line
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
#Set-PSReadLineOption -BellStyle None
#Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

#for posh predictive text
Set-PredictiveTextOption -RemoveCondaTabExpansion
Install-PredictiveText

#Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory "Ctrl+r"

#Alias
Set-Alias vim nvim
Set-Alias vi nvim
Set-Alias ll ls
Set-Alias g git
Set-Alias grep findstr
Set-Alias tig 'C:\Program Files\Git\usr\bin\tig.exe'
Set-Alias less 'C:\Program Files\Git\usr\bin\less.exe'

#Functions

function charm {
    Param($cats)
    cat $cats | gum pager
}

function eip {
    curl -s http://ifconfig.me
}
#change dir to nvim config file
function config/nvim {
Set-Location 'C:\Users\User\AppData\Local\nvim' #this is equivalent to ~./config/nvim
}

function config/nvimdata {
    Set-Location 'C:\Users\User\AppData\Local\nvim'
    }

#which
function which ($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

#Key handler that creates double quotes like intellisense in VS code
Set-PSReadLineKeyHandler -Chord '"',"'" `
                         -BriefDescription SmartInsertQuote `
                         -LongDescription "Insert paired quotes if not already on a quote" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($line.Length -gt $cursor -and $line[$cursor] -eq $key.KeyChar) {
        # Just move the cursor
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
    else {
        # Insert matching quotes, move cursor to be in between the quotes
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)" * 2)
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
    }
}

# Create Menu of Directories to select from, uses PSmenu module
function cdx {
     $dir = menu (Invoke-Expression "dir -dir")
     Invoke-Expression "cd $dir"
     }

# powershell completion for oh-my-posh                           -*- shell-script -*-

function __oh-my-posh_debug {
    if ($env:BASH_COMP_DEBUG_FILE) {
        "$args" | Out-File -Append -FilePath "$env:BASH_COMP_DEBUG_FILE"
    }
}

filter __oh-my-posh_escapeStringWithSpecialChars {
    $_ -replace '\s|#|@|\$|;|,|''|\{|\}|\(|\)|"|`|\||<|>|&','`$&'
}

Register-ArgumentCompleter -CommandName 'oh-my-posh' -ScriptBlock {
    param(
            $WordToComplete,
            $CommandAst,
            $CursorPosition
        )

    # Get the current command line and convert into a string
    $Command = $CommandAst.CommandElements
    $Command = "$Command"

    __oh-my-posh_debug ""
    __oh-my-posh_debug "========= starting completion logic =========="
    __oh-my-posh_debug "WordToComplete: $WordToComplete Command: $Command CursorPosition: $CursorPosition"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CursorPosition location, so we need
    # to truncate the command-line ($Command) up to the $CursorPosition location.
    # Make sure the $Command is longer then the $CursorPosition before we truncate.
    # This happens because the $Command does not include the last space.
    if ($Command.Length -gt $CursorPosition) {
        $Command=$Command.Substring(0,$CursorPosition)
    }
    __oh-my-posh_debug "Truncated command: $Command"

    $ShellCompDirectiveError=1
    $ShellCompDirectiveNoSpace=2
    $ShellCompDirectiveNoFileComp=4
    $ShellCompDirectiveFilterFileExt=8
    $ShellCompDirectiveFilterDirs=16

    # Prepare the command to request completions for the program.
    # Split the command at the first space to separate the program and arguments.
    $Program,$Arguments = $Command.Split(" ",2)

    $RequestComp="$Program __complete $Arguments"
    __oh-my-posh_debug "RequestComp: $RequestComp"

    # we cannot use $WordToComplete because it
    # has the wrong values if the cursor was moved
    # so use the last argument
    if ($WordToComplete -ne "" ) {
        $WordToComplete = $Arguments.Split(" ")[-1]
    }
    __oh-my-posh_debug "New WordToComplete: $WordToComplete"


    # Check for flag with equal sign
    $IsEqualFlag = ($WordToComplete -Like "--*=*" )
    if ( $IsEqualFlag ) {
        __oh-my-posh_debug "Completing equal sign flag"
        # Remove the flag part
        $Flag,$WordToComplete = $WordToComplete.Split("=",2)
    }

    if ( $WordToComplete -eq "" -And ( -Not $IsEqualFlag )) {
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __oh-my-posh_debug "Adding extra empty parameter"
        # We need to use `"`" to pass an empty argument a "" or '' does not work!!!
        $RequestComp="$RequestComp" + ' `"`"'
    }

    __oh-my-posh_debug "Calling $RequestComp"
    # First disable ActiveHelp which is not supported for Powershell
    $env:OH_MY_POSH_ACTIVE_HELP=0

    #call the command store the output in $out and redirect stderr and stdout to null
    # $Out is an array contains each line per element
    Invoke-Expression -OutVariable out "$RequestComp" 2>&1 | Out-Null

    # get directive from last line
    [int]$Directive = $Out[-1].TrimStart(':')
    if ($Directive -eq "") {
        # There is no directive specified
        $Directive = 0
    }
    __oh-my-posh_debug "The completion directive is: $Directive"

    # remove directive (last element) from out
    $Out = $Out | Where-Object { $_ -ne $Out[-1] }
    __oh-my-posh_debug "The completions are: $Out"

    if (($Directive -band $ShellCompDirectiveError) -ne 0 ) {
        # Error code.  No completion.
        __oh-my-posh_debug "Received error from custom completion go code"
        return
    }

    $Longest = 0
    $Values = $Out | ForEach-Object {
        #Split the output in name and description
        $Name, $Description = $_.Split("`t",2)
        __oh-my-posh_debug "Name: $Name Description: $Description"

        # Look for the longest completion so that we can format things nicely
        if ($Longest -lt $Name.Length) {
            $Longest = $Name.Length
        }

        # Set the description to a one space string if there is none set.
        # This is needed because the CompletionResult does not accept an empty string as argument
        if (-Not $Description) {
            $Description = " "
        }
        @{Name="$Name";Description="$Description"}
    }


    $Space = " "
    if (($Directive -band $ShellCompDirectiveNoSpace) -ne 0 ) {
        # remove the space here
        __oh-my-posh_debug "ShellCompDirectiveNoSpace is called"
        $Space = ""
    }

    if ((($Directive -band $ShellCompDirectiveFilterFileExt) -ne 0 ) -or
       (($Directive -band $ShellCompDirectiveFilterDirs) -ne 0 ))  {
        __oh-my-posh_debug "ShellCompDirectiveFilterFileExt ShellCompDirectiveFilterDirs are not supported"

        # return here to prevent the completion of the extensions
        return
    }

    $Values = $Values | Where-Object {
        # filter the result
        $_.Name -like "$WordToComplete*"

        # Join the flag back if we have an equal sign flag
        if ( $IsEqualFlag ) {
            __oh-my-posh_debug "Join the equal sign flag back to the completion value"
            $_.Name = $Flag + "=" + $_.Name
        }
    }

    if (($Directive -band $ShellCompDirectiveNoFileComp) -ne 0 ) {
        __oh-my-posh_debug "ShellCompDirectiveNoFileComp is called"

        if ($Values.Length -eq 0) {
            # Just print an empty string here so the
            # shell does not start to complete paths.
            # We cannot use CompletionResult here because
            # it does not accept an empty string as argument.
            ""
            return
        }
    }

    # Get the current mode
    $Mode = (Get-PSReadLineKeyHandler | Where-Object {$_.Key -eq "Tab" }).Function
    __oh-my-posh_debug "Mode: $Mode"

    $Values | ForEach-Object {

        # store temporary because switch will overwrite $_
        $comp = $_

        # PowerShell supports three different completion modes
        # - TabCompleteNext (default windows style - on each key press the next option is displayed)
        # - Complete (works like bash)
        # - MenuComplete (works like zsh)
        # You set the mode with Set-PSReadLineKeyHandler -Key Tab -Function <mode>

        # CompletionResult Arguments:
        # 1) CompletionText text to be used as the auto completion result
        # 2) ListItemText   text to be displayed in the suggestion list
        # 3) ResultType     type of completion result
        # 4) ToolTip        text for the tooltip with details about the object

        switch ($Mode) {

            # bash like
            "Complete" {

                if ($Values.Length -eq 1) {
                    __oh-my-posh_debug "Only one completion left"

                    # insert space after value
                    [System.Management.Automation.CompletionResult]::new($($comp.Name | __oh-my-posh_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")

                } else {
                    # Add the proper number of spaces to align the descriptions
                    while($comp.Name.Length -lt $Longest) {
                        $comp.Name = $comp.Name + " "
                    }

                    # Check for empty description and only add parentheses if needed
                    if ($($comp.Description) -eq " " ) {
                        $Description = ""
                    } else {
                        $Description = "  ($($comp.Description))"
                    }

                    [System.Management.Automation.CompletionResult]::new("$($comp.Name)$Description", "$($comp.Name)$Description", 'ParameterValue', "$($comp.Description)")
                }
             }

            # zsh like
            "MenuComplete" {
                # insert space after value
                # MenuComplete will automatically show the ToolTip of
                # the highlighted value at the bottom of the suggestions.
                [System.Management.Automation.CompletionResult]::new($($comp.Name | __oh-my-posh_escapeStringWithSpecialChars) + $Space, "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
            }

            # TabCompleteNext and in case we get something unknown
            Default {
                # Like MenuComplete but we don't want to add a space here because
                # the user need to press space anyway to get the completion.
                # Description will not be shown because that's not possible with TabCompleteNext
                [System.Management.Automation.CompletionResult]::new($($comp.Name | __oh-my-posh_escapeStringWithSpecialChars), "$($comp.Name)", 'ParameterValue', "$($comp.Description)")
            }
        }

    }
}



$global:lastRender = Get-Date  
$printableChars = [char[]] (0x20..0x7e + 0xa0..0xff)
$printableChars + "Tab" | ForEach-Object {
    Set-PSReadLineKeyHandler -Key $_ `
        -BriefDescription ValidatePrograms `
        -LongDescription "Validate typed program's existance in path variable" `
        -ScriptBlock {
        param($key, $arg)   

        if ( $key.Key -ne [System.ConsoleKey]::Tab) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($key.KeyChar)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext($key)
        } 

        if (((get-date) - $global:lastRender).TotalMilliseconds -le 50) {
            return
        }

        $ast = $null; $tokens = $null ; $errors = $null; $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)  
        $token = $tokens[0]
        if ([string]::IsNullOrEmpty($token.Text.Trim())) {
            return
        }  

        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)
        $cursorPosX = $host.UI.RawUI.CursorPosition.X
        $cursorPosY = $host.UI.RawUI.CursorPosition.Y
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor)

        $tokenLength = ($token.Extent.EndOffset - $token.Extent.StartOffset)
 
        $color = "Red"
        if ((Get-Command $token -ErrorAction SilentlyContinue)) {
            $color = "Green"
        } 

        $sX = $cursorPosX
        $Y = $cursorPosY
        $eX = ($cursorPosX + $tokenLength)
        $nextLine = $false

        $painted = 0
        $bufSize = $host.UI.RawUI.BufferSize.Width
        while ($painted -ne $tokenLength) {            
            $scanXEnd = $eX
            if ($eX -gt $bufSize) {
                $scanXEnd = $bufSize
                $eX = $eX - $bufSize
                $nextLine = $true
            } 
            $finalRec = New-Object System.Management.Automation.Host.Rectangle($sX, $Y, $scanXEnd, $Y)            
            $finalBuf = $host.UI.RawUI.GetBufferContents($finalRec)
            for ($xPosition = 0; $xPosition -lt ($scanXEnd - $sX); $xPosition++) {
                $bufferItem = $finalBuf.GetValue(0, $xPosition)      
                $bufferItem.ForegroundColor = $color          
                $finalBuf.SetValue($bufferItem, 0, $xPosition)   
                $painted++      
            }
            $coords = New-Object System.Management.Automation.Host.Coordinates $sX , $Y
            $host.ui.RawUI.SetBufferContents($coords, $finalBuf)
            if ($nextLine) {
                $sX=0
                $Y++
                $nextLine = $false
            }
        }
        $global:lastRender = get-date
    }
}

