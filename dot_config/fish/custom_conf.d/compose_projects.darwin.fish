# Bring the compose project in a directory up or down, starting the Docker engine first:
#
#   compose-project-up   ~/ghq/github.com/owner/repo web sidekiq
#   compose-project-up   ~/ghq/github.com/owner/repo
#   compose-project-down ~/ghq/github.com/owner/repo

set -q docker_engine_timeout; or set -g docker_engine_timeout 180

function __compose_project_wait_for_engine --description 'Launch Docker Desktop and block until the engine responds'
    docker info >/dev/null 2>&1; and return 0

    echo "compose-project: starting Docker Desktop, waiting up to $docker_engine_timeout""s..."
    open -ga Docker; or return 1

    set -l waited 0
    while not docker info >/dev/null 2>&1
        if test $waited -ge $docker_engine_timeout
            echo "compose-project: Docker engine did not come up in $docker_engine_timeout""s" >&2
            return 1
        end
        sleep 2
        set waited (math $waited + 2)
    end
end

function __compose_project_ready --description 'Check docker and the project directory, then wait for the engine'
    if not type -q docker
        echo "compose-project: docker not found" >&2
        return 1
    end

    if not test -d "$argv[1]"
        echo "compose-project: no such directory: $argv[1]" >&2
        return 1
    end

    __compose_project_wait_for_engine
end

function compose-project-up --description 'Bring up the given services, or every service, of a compose project'
    if test (count $argv) -eq 0
        echo "usage: compose-project-up <project-dir> [service...]" >&2
        return 2
    end

    set -l project $argv[1]
    set -l services $argv[2..]

    __compose_project_ready "$project"; or return 1

    echo "compose-project: up $project" $services
    pushd "$project"; or return 1
    docker compose up -d $services
    set -l result $status
    popd
    return $result
end

function compose-project-down --description 'Stop and remove the containers of a compose project, orphans included'
    if test (count $argv) -ne 1
        echo "usage: compose-project-down <project-dir>" >&2
        return 2
    end

    set -l project $argv[1]

    __compose_project_ready "$project"; or return 1

    echo "compose-project: down $project"
    pushd "$project"; or return 1
    docker compose down --remove-orphans
    set -l result $status
    popd
    return $result
end
