# Docker setup.
if has docker-compose
    alias dc docker-compose
else
    alias dc 'docker compose'
end

if test (id -u) -ne 0
    alias docker 'sudo docker'
    alias docker-compose 'sudo docker-compose'
end
alias docker-ip "docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"
alias dockers "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"

function docker-compose-path --description 'Show docker compose working directory for a container'
    if test (count $argv) -eq 0
        echo 'Usage: docker-compose-path <container-name>'
        return 1
    end

    docker inspect "$argv[1]" | grep 'com.docker.compose.project.working_dir'
end
