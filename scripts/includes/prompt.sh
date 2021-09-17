# Bash PS1 (Not updated)
PS1='\n\[\e[m\][\[\e[35m\]\D{%y-%m-%d} \t\[\e[m\]] [\[\e[34m\]\h\[\e[m\]] [\[\e[33m\]\u\[\e[m\]] \[\e[37m\]\w \n\[\e[m\]$ '

# ZSH
DEFAULT_USER="hykilpikonna"
PROMPT=$(color "&n&5%D{%a %m-%d %H:%M}&r | &1%m&r |")
# Shows a cat if I'm hykilpikonna
if [[ "$USER" != "$DEFAULT_USER" ]]; then
    PROMPT=$(color "$PROMPT &e%n&r")
else
    PROMPT=$(color "$PROMPT 🐱")
fi
PROMPT=$(color "$PROMPT &r%~&n> ")
