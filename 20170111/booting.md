setenv ethact dwmac.bf060000; setenv ipaddr 10.10.10.2; setenv gatewayip 10.10.0.1; setenv serverip 10.10.10.1;

setenv fdt_addr_f 0x85d00000; setenv kernel_addr_f 0x81000000;

tftp 0x81000000 uImage0801.gz

tftp 0x85d00000 baikal_tclient.dtb

setenv rootpath /srv/jessie/

setenv bootargs ${bootargs} ip=10.10.10.2:10.10.10.1:10.10.10.1:255.255.255.0::eth1:off:

setenv nfsargs 'setenv bootargs ${bootargs} root=/dev/nfs video=sm750fb:1920x1080-32@60:24bit:nohwc rw rootwait nfsroot=${serverip}:${rootpath}'

setenv nfs_boot 'run flash_load_fdt; run nfsargs addtty addmisc addip addhw addboard; bootm 0x81000000 - 0x85D00000'

run nfs_boot

