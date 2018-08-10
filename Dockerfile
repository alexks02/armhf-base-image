FROM scratch
[ "sh", "gen_debian_rootfs.sh", "run" ]
ADD ./output/rootfs.tar.gz /
CMD ["/bin/bash"]
