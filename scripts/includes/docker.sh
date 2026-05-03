if command -v 'docker-compose' &> /dev/null; then
    alias dc='docker-compose'
else
    alias dc='docker compose'
fi

if [[ $OSTYPE != 'darwin'* && $EUID -ne 0 ]]; then
    alias docker="sudo docker"
    alias docker-compose="sudo docker-compose"
fi

alias docker-ip="docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"
alias dockers="docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"

docker-compose-path() 
{
    if [[ -z $1 ]]; then
        echo "Usage: docker-compose-path <container-name>"
        return 1
    fi

    docker inspect "$1" | grep "com.docker.compose.project.working_dir"
}
