FROM scratch
RUN [ "/bin/bash", "gen_debian_rootfs.sh" ]
ADD ./output/rootfs.tar.gz /
CMD ["/bin/bash"]
