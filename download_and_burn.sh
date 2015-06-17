wget -N http://jenkins.netmodule.intranet/view/ZE7000/job/ze7000-release/lastSuccessfulBuild/artifact/images/ze7000-image-ze7000-zynq7.tar.bz2
wget -N http://jenkins.netmodule.intranet/view/ZE7000/job/ze7000-boot-release/lastSuccessfulBuild/artifact/ready_to_test/ze7000_boot.bin 
sudo ./install-sd.sh /dev/sdd ze7000_boot.bin ze7000-image-ze7000-zynq7.tar.bz2
