
if command -v 'docker-compose' &> /dev/null; then
    alias dc='sudo docker-compose'
else
    alias dc='sudo docker compose'
fi
alias docker-ip="sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"
alias dockers="sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"

# Docker linux containers
alpine-create()
{
    docker rmi azalea/alpine
    docker run -it --name alpine-init --hostname alpine alpine \
        /bin/sh -c 'apk add zsh bash git curl wget tar zstd python3 && bash <(curl -sL hydev.org/zsh)'
    docker commit alpine-init azalea/alpine
    docker rm alpine-init
}
alias alpine="docker start -ai alpine"
alias alpine-init="docker run -it --name alpine --hostname alpine azalea/alpine zsh"

alias psqlt+="docker run --rm -dit --name psql-test --hostname psql -e POSTGRES_HOST_AUTH_METHOD=trust postgres && echo 'Created'"
alias psqlt-="docker stop psql-test && echo 'Deleted'"
alias psqlt='psql -h $(docker-ip psql-test) -p 5432 -U postgres'