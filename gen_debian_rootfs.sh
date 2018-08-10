#!/bin/bash

#
# Preparation
#

export LC_ALL=C
export LANG=C
export DEBIAN_FRONTEND=noninteractive

THIS_SCRIPT=`echo $0 | sed "s/^.*\///"`
SCRIPT_PATH=`echo $0 | sed "s/\/${THIS_SCRIPT}$//"`
real_pwd=`pwd`
real_pwd=`realpath ${real_pwd}`
output_dir=${real_pwd}/output
work_dir=${real_pwd}/_build_tmp

if [ $EUID -ne 0 ]; then
  echo "this tool must be run as root"
  exit 1
fi

if [ -d $work_dir ]; then
    echo "Working directory $work_dir exist, please remove it before run this script"
    exit 1
fi


#
# Debian parameters
#

deb_mirror="http://ftp.us.debian.org/debian"
deb_release="stable"
rootfs="${work_dir}/rootfs"
architecture="armhf"


#
# 1st stage
#

mkdir -p $work_dir
mkdir -p $output_dir
mkdir -p $rootfs
debootstrap --foreign --arch $architecture --variant=minbase $deb_release $rootfs $deb_mirror


#
# 2nd stage
#

chroot $rootfs /debootstrap/debootstrap --second-stage

cat << EOF > ${rootfs}/etc/apt/sources.list
deb $deb_mirror $deb_release main contrib non-free
EOF

echo "bsms" > ${rootfs}/etc/hostname

cat << EOF > ${rootfs}/etc/resolv.conf
nameserver 8.8.8.8
EOF


#
# 3rd stage
#

mount -t proc proc ${rootfs}/proc
mount -o bind /dev/ ${rootfs}/dev/
mount -o bind /dev/pts ${rootfs}/dev/pts

cat << EOF > ${rootfs}/debconf.set
console-common console-data/keymap/policy select Select keymap from full list
console-common console-data/keymap/full select en-latin1-nodeadkeys
EOF

cat << EOF > ${rootfs}/third-stage
#!/bin/bash
rm -rf /debootstrap
debconf-set-selections /debconf.set
rm -f /debconf.set
apt-get update
apt-get -y install locales console-common curl wget
rm -f /third-stage
EOF

chmod +x ${rootfs}/third-stage
chroot ${rootfs} /third-stage


#
# Cleanup
# 

cat << EOF > ${rootfs}/cleanup
#!/bin/bash
rm -rf /root/.bash_history
apt-get clean -y
apt-get autoclean -y
apt-get autoremove -y
rm -f cleanup
EOF

chmod +x ${rootfs}/cleanup
chroot ${rootfs} /cleanup


#
# Reduce size by delete some files and umount filesystems
#

mkdir -p ${work_dir}/tmp
cp -R ${rootfs}/usr/share/locale/en\@* ${work_dir}/tmp/ && rm -rf ${rootfs}/usr/share/locale/* && mv ${work_dir}/tmp/en\@* ${rootfs}/usr/share/locale/
rm -rf ${rootfs}/var/cache/debconf/*-old && rm -rf ${rootfs}/var/lib/apt/lists/* && rm -rf ${rootfs}/usr/share/doc/*
umount ${rootfs}/proc
umount ${rootfs}/dev/pts
umount ${rootfs}/dev/


#
# Generate rootfs tar-ball
#

rm -rf $output_dir/rootfs.tar.gz
cd ${rootfs}
tar -zcvf ${output_dir}/rootfs.tar.gz *


#
# Remove work dir and exit
#

rm -rf ${work_dir}
echo "..."
echo "PROFIT!"
