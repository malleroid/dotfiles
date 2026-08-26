if type -q container
    container system start
    set -gx CONTAINER_DEFAULT_PLATFORM linux/arm64
end
