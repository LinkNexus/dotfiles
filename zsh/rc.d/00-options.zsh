setopt AUTOCD
setopt NUMERIC_GLOB_SORT

# Free up ^S/^Q, which XON/XOFF flow control would otherwise swallow
stty -ixon
bindkey -r '^S'
