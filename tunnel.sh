#! /usr/bin/env sh
OPTIND=1
host_port=8892
remote_port=8890

print_help() {
    # Display Help
    echo "Open a tunnel to a specific container on a server"
    echo
    echo "Syntax: [-p|r|h] <ssh-addr> <project-name> [container-name]"
    echo "options:"
    echo "p     The port on the host you want to use for the tunnel, default 8892"
    echo "r     The exposed port on the remote container you want to tunnel to, default 8890"
    echo "h     Print this Help."
    echo
}
while getopts ":hp:r:" option; do
    case $option in
        h) # display Help
            print_help
            exit
            ;;
        p) host_port=$OPTARG ;;
        r) remote_port=$OPTARG ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            print_help
            exit
            ;;
    esac

done
shift $((OPTIND - 1))

[ "${1:-}" = "--" ] && shift

SSH_ADDR=$1
PROJECT=$2
CONTAINER=$3

if test "$SSH_ADDR" == ''; then
   echo "missing required argument ssh-addr"
   print_help
   exit 1
fi

if test "$PROJECT" == ''; then
   echo "missing required argument project-name"
   print_help
   exit 1
fi

if test "$CONTAINER" == ''; then
    CONTAINER="virtuoso"
fi


container_name=$(ssh "$SSH_ADDR" docker ps --filter "label=com.docker.compose.project=$PROJECT" --filter "label=com.docker.compose.service=$CONTAINER" --format "{{.Names}}")
echo "Connecting to $container_name at $SSH_ADDR on port $remote_port for project $PROJECT"
sleep 2
container_ip=$(ssh "$SSH_ADDR" "docker inspect -f '{{range .NetworkSettings.Networks}}{{println .IPAddress}}{{end}}'  $container_name | head -n1")
echo "Got ip $container_ip"
sleep 2
echo "Opening tunnel on port $host_port"
(ssh "$SSH_ADDR" -L "$host_port:$container_ip:$remote_port" -N)
