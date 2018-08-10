#!/bin/sh

./gen_debian_rootfs.sh
docker-compose create --build
docker-compose push
docker-compose rm -f
docker images -q | xargs docker rmi 2>/dev/null
