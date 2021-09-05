if status is-interactive
    # Commands to run in interactive sessions can go here
    set -U fish_greeting ""

    # alias btrfortune='fortune -a -s | head -n 1 | figlet | lolcat'
    # alias fortunecow='fortune -a -s | head -n 1 | cowsay | lolcat'
    
    alias ls='ls --color=always -rthla'
    alias matrix='unimatrix -f -l ocCgGkS -s 96'
    alias clock='tty-clock -sct -C 4'
    alias pipes='pipes -p 5 -R -t 1 -r 0'
    #colorscript -r
end
