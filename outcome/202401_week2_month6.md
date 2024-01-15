# 本周工作

## ruyi

调研：[基于 VSCode 以任一个 demo 走通 RUST RISC-V 交叉编译和运行过程](https://github.com/ruyisdk/pmd/issues/7)

部分进展：[文档](../doc/ruyi/vscode-rust.md)

## autotest

github: <https://github.com/trdthg/t-autotest>

自动化测试框架本周工作

- cli 模块 (提供命令行工具入口进程)
  - Feature
    - `needle.rs`: 提供 needle 加载，比较等方法，用于屏幕比较
- console 模块 (负责和机器终端交互)
  - ssh
  - serial
    - Feature
      - 支持不间断读取出口输出，包括系统启动 (重启) 时的 systemd 输出 (见下方日志)
  - vnc
- binding 模块 (负责测试脚本对接)
  - js (从 quickjs 切换至 rquickjs)
    - Feature
      - api
        - sleep: 为脚本提供统一的 sleep 实现
        - get_env: 获取 `config.toml` 定义的环境变量
        - serial_write_string: 调用 serial 在主 session 写入字符串
        - assert_screen: 调用 vnc 断言屏幕
        - check_screen: 调用 vnc 比较屏幕
        - mouse_click: 调用 vnc 鼠标点击
        - mouse_move: 调用 vnc 移动鼠标
        - mouse_hide: 调用 vnc 隐藏鼠标
- config 模块 (提供测试，命令行 需要的通用配置文件解析)
  - Feature
    - env: 添加环境变量，同 `get_env` 一起使用
    - needle_dir: needle 文件夹位置

树莓派串口交互，测试 ruyi 参考 (部分)：

```txt
    ���|B�n�lscc���nl[    0.000000] Booting Linux on physical CPU 0x0
[    0.000000] Linux version 6.1.21-v7+ (dom@buildbot) (arm-linux-gnueabihf-gcc-8 (Ubuntu/Linaro 8.4.0-3ubuntu1) 8.4.0, GNU ld (GNU Binutils for Ubuntu) 2.34) #1642 SMP Mon Apr  3 17:20:52 BST 2023
[    0.000000] CPU: ARMv7 Processor [410fd034] revision 4 (ARMv7), cr=10c5383d
[    0.000000] CPU: div instructions available: patching division code
[    0.000000] CPU: PIPT / VIPT nonaliasing data cache, VIPT aliasing instruction cache
[    0.000000] OF: fdt: Machine model: Raspberry Pi 3 Model B Rev 1.2
[    0.000000] random: crng init done
[    0.000000] Memory policy: Data cache writealloc
[    0.000000] Reserved memory: created CMA memory pool at 0x1ec00000, size 256 MiB
[    0.000000] OF: reserved mem: initialized node linux,cma, compatible id shared-dma-pool
[    0.000000] Zone ranges:
[    0.000000]   DMA      [mem 0x0000000000000000-0x000000003b3fffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000000000000-0x000000003b3fffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000000000000-0x000000003b3fffff]
[    0.000000] percpu: Embedded 17 pages/cpu s36884 r8192 d24556 u69632
[    0.000000] B[    0.000000] Inode-cache hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 680924K/970752K available (10240K kernel code, 1452K rwdata, 2900K rodata, 1024K init, 613K bss, 27684K reserved, 262144K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=4, Nodes=1
[    0.000000] ftrace: allocating 34800 entries in 103 pages
[    0.000000] ftrace: allocated 102 pages with 4 groups
[    0.000000] trace event string verifier disabled
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000]  Rude variant of Tasks RCU enabled.
[    0.000000]  Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] NR_IRQS: 16, nr_irqs: 16, preallocated irqs: 16
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] arch_timer: cp15 timer(s) running at 19.20MHz (phys).
[    0.000000] clocksource: arch_sys_counter: mask: 0xffffffffffffff max_cycles: 0x46d987e47, max_idle_ns: 440795202767 ns
[    0.000001] sched_clock: 56 bits at 19MHz, resolution 52ns, wraps every 4398046511078ns
[    0.000018] Switching to timer-based delay loop, resolution 52ns
[    0.000370] Console: colour dummy device 80x30
[    0.000985] printk: console [t[    0.003274] CPU0: thread -1, cpu 0, socket 0, mpidr 80000000
[    0.004121] cblist_init_generic: Setting adjustable number of callback queues.
[    0.004158] cblist_init_generic: Setting shift to 2 and lim to 1.
[    0.004288] cblist_init_generic: Setting shift to 2 and lim to 1.
[    0.004444] Setting up static identity map for 0x100000 - 0x10003c
[    0.004596] rcu: Hierarchical SRCU implementation.
[    0.004620] rcu:     Max phase no-delay instances is 1000.
[    0.005325] smp: Bringing up secondary CPUs ...
[    0.006205] CPU1: thread -1, cpu 1, socket 0, mpidr 80000001
[    0.007122] CPU2: thread -1, cpu 2, socket 0, mpidr 80000002
[    0.007972] CPU3: thread -1, cpu 3, socket 0, mpidr 80000003
[    0.008074] smp: Brought up 1 node, 4 CPUs
[    0.008153] SMP: Total of 4 processors activated (153.60 BogoMIPS).
[    0.008180] CPU: All CPU(s) started in HYP mode.
[    0.008199] CPU: Virtualization extensions available.
[    0.008909] devtmpfs: initialized
[    0.023686] VFP support v0.3: implementor 41 architecture 3 part 40 variant 3 rev 4
[    0.023912] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.023965] futex hash table entries: 1024 (order: 4, 65536 bytes, linear)
[    0.033846] pinctrl core: initialized pinctrl subsystem
[    0.035012] NET: Registered PF_NETLINK/PF_ROUTE protoco-03-17T10:52:42, variant start
[    0.080072] raspberrypi-firmware soc:firmware: Firmware hash is 82f3750a65fadae9a38077e3c2e217ad158c8d54
[    0.122509] kprobes: kprobe jump-optimization is enabled. All kprobes are optimized if possible.
[    0.128130] bcm2835-dma 3f007000.dma: DMA legacy API manager, dmachans=0x1
[    0.129826] SCSI subsystem initialized
[    0.130072] usbcore: registered new interface driver usbfs
[    0.130152] usbcore: registered new interface driver hub
[    0.130220] usbcore: registered new device driver usb
[    0.130455] usb_phy_generic phy: supply vcc not found, using dummy regulator
[    0.130636] usb_phy_generic phy: dummy supplies not allowed for exclusive requests
[    0.130918] pps_core: LinuxPPS API ver. 1 registered
[    0.130943] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.130993] PTP clock support registered
[    2.010273] clocksource: Switched to clocksource arch_sys_counter
[    2.107172] VFS: Disk quotas dquot_6.6.0
[    2.107287] VFS: Dquot-cache hash table entries: 1024 (order 0, 4096 bytes)
[    2.107458] FS-Cache: Loaded
[    2.107825] CacheFiles: Loaded
[    2.117238] NET: Registered PF_INET protocol family
[    2.117533] IP ide[    2.121807] RPC: Registered named UNIX socket transport module.
[    2.121836] RPC: Registered udp transport module.
[    2.121858] RPC: Registered tcp transport module.
[    2.121878] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    2.123498] hw perfevents: enabled with armv7_cortex_a7 PMU driver, 7 counters available
[    2.126583] Initialise system trusted keyrings
[    2.126850] workingset: timestamp_bits=14 max_order=18 bucket_order=4
[    2.136041] zbud: loaded
[    2.138423] NFS: Registering the id_resolver key type
[    2.138480] Key type id_resolver registered
[    2.138503] Key type id_legacy registered
[    2.138641] nfs4filelayout_init: NFSv4 File Layout Driver Registering...
[    2.138670] nfs4flexfilelayout_init: NFSv4 Flexfile Layout Driver Registering...
[    2.139954] Key type asymmetric registered
[    2.139982] Asymmetric key parser 'x509' registered
[    2.140173] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 247)
[    2.140208] io scheduler mq-deadline registered
[    2.140232] io scheduler kyber registered
[    2.145130] simple-framebuffer 3eaa9000.framebuffer: framebuffer at 0x3eaa9000, 0x151800 bytes
[    2.1[    2.208784] usbcore: registered new interface driver smsc95xx
[    2.211395] dwc_otg: version 3.00a 10-AUG-2012 (platform bus)
[    2.941945] Core Release: 2.80a
[    2.944432] Setting default values for core params
[    2.946949] Finished setting default values for core params
[    3.149725] Using Buffer DMA mode
[    3.152219] Periodic Transfer Interrupt Enhancement - disabled
[    3.154705] Multiprocessor Interrupt Enhancement - disabled
[    3.157192] OTG VER PARAM: 0, OTG VER FLAG: 0
[    3.159734] Dedicated Tx FIFOs mode
[    3.162754]
[    3.162761] WARN::dwc_otg_hcd_init:1074: FIQ DMA bounce buffers: virt = 9ed04000 dma = 0xded04000 len=9024
[    3.169868] FIQ FSM acceleration enabled for :
[    3.169868] Non-periodic Split Transactions
[    3.169868] Periodic Split Transactions
[    3.169868] High-Speed Isochronous Endpoints
[    3.169868] Interrupt/Control Split Transaction hack enabled
[    3.181152]
[    3.181158] WARN::hcd_init_fiq:457: FIQ on core 1
[    3.185233]
[    3.185237] WARN::hcd_init_fiq:458: FIQ ASM at 807c4360 length 36
[    3.189203]
[    3.189208] WARN::hcd_init_fiq:497: MPHI regs_base at[    3.215112] usb usb1: SerialNumber: 3f980000.usb
[    3.217999] hub 1-0:1.0: USB hub found
[    3.220222] hub 1-0:1.0: 1 port detected
[    3.223275] usbcore: registered new interface driver usb-storage
[    3.225616] mousedev: PS/2 mouse device common for all mice
[    3.230204] sdhci: Secure Digital Host Controller Interface driver
[    3.232454] sdhci: Copyright(c) Pierre Ossman
[    3.234935] sdhci-pltfm: SDHCI platform and OF driver helper
[    3.239000] ledtrig-cpu: registered to indicate activity on CPUs
[    3.241702] hid: raw HID events driver (C) Jiri Kosina
[    3.244116] usbcore: registered new interface driver usbhid
[    3.246398] usbhid: USB HID core driver
[    3.252390] Initializing XFRM netlink socket
[    3.254683] NET: Registered PF_PACKET protocol family
[    3.256994] Key type dns_resolver registered
[    3.259933] Registering SWP/SWPB emulation handler
[    3.262790] registered taskstats version 1
[    3.264992] Loading compiled-in X.509 certificates
[    3.267927] Key type .fscrypt registered
[    3.270100] Key type fscrypt-provisioning registered
[    3.283507] uart-pl011 3f201000.serial: cts_event_workaround enabled
[    3.285785] 3f201000.serial: ttyAMA0 at MMIO 0x3f201000 (irq = 114, base_baud = 0) is a PL011 rev2
[    3.291443] bcm2835-aux-uart 3f[    3.850285] mmc-bcm2835 3f300000.mmcnr: mmc_debug:0 mmc_debug2:0
[    3.853845] usb 1-1: New USB device strings: Mfr=0, Product=0, SerialNumber=0
[    3.856420] mmc-bcm2835 3f300000.mmcnr: DMA channel allocated
[    3.861950] hub 1-1:1.0: USB hub found
[    4.009249] mmc1: new high speed SDIO card at address 0001
[    4.014708] hub 1-1:1.0: 5 ports detected
[    4.020525] sdhost: log_buf @ 3fbff30d (ded07000)
[    4.410294] usb 1-1.1: new high-speed USB device number 3 using dwc_otg
[    4.461608] mmc0: sdhost-bcm2835 loaded - DMA enabled (>1)
[    4.591422] of_cfs_init
[    4.596771] of_cfs_init: OK
[    4.602807] usb 1-1.1: New USB device found, idVendor=0424, idProduct=ec00, bcdDevice= 2.00
[    4.616590] usb 1-1.1: New USB device strings: Mfr=0, Product=0, SerialNumber=0
[    4.623765] mmc0: host does not support reading read-only switch, assuming write-enable
[    4.632745] smsc95xx v2.0.0
[    4.640569] mmc0: new high speed SDHC card at address 59b4
[    4.652089] mmcblk0: mmc0:59b4 00000 7.48 GiB
[    4.661937]  mmcblk0: p1 p2
[    4.667945] mmcblk0: mmc0:59b4 00000 7.48 GiB
[    4.761999] SMSC LAN8700 usb-001:003:01: attached PHY driver (mii_bus:phy_addr=usb-001:003:01, i[    5.699707] Segment Routing with IPv6
[    5.706239] In-situ OAM (IOAM) with IPv6
[    5.805594] systemd[1]: systemd 247.3-7+rpi1+deb11u2 running in system mode. (+PAM +AUDIT +SELINUX +IMA +APPARMOR +SMACK +SYSVINIT +UTMP +LIBCRYPTSETUP +GCRYPT +GNUTLS +ACL +XZ +LZ4 +ZSTD +SECCOMP +BLKID +ELFUTILS +KMOD +IDN2 -IDN +PCRE2 default-hierarchy=unified)
[    5.839224] systemd[1]: Detected architecture arm.
[    5.865587] systemd[1]: Set hostname to <raspberrypi>.
[    6.996826] systemd[1]: Queued start job for default target Multi-User System.
[    7.044144] systemd[1]: Created slice system-getty.slice.
[    7.057214] systemd[1]: Created slice system-modprobe.slice.
[    7.070061] systemd[1]: Created slice system-serial\x2dgetty.slice.
[    7.083477] systemd[1]: Created slice system-systemd\x2dfsck.slice.
[    7.096398] systemd[1]: Created slice User and Session Slice.
[    7.108305] systemd[1]: Started Dispatch Password Requests to Console Directory Watch.
[    7.122647] systemd[1]: Started Forward Password Requests to Wall Directory Watch.
[    7.137451] systemd[1]: Set up automount Arbitrary Executable File Formats File System Automount Point.
[    7.156569] systemd[1]: Reached target Local Encrypted Volumes.
[    7.169275] systemd[1]: Reached target Paths.
[    7.179984] systemd[1]: R[    7.294387] systemd[1]: Listening on udev Kernel Socket.
[    7.306484] systemd[1]: Condition check resulted in Huge Pages File System being skipped.
[    7.370733] systemd[1]: Mounting POSIX Message Queue File System...
[    7.387839] systemd[1]: Mounting RPC Pipe File System...
[    7.404871] systemd[1]: Mounting Kernel Debug File System...
[    7.422165] systemd[1]: Mounting Kernel Trace File System...
[    7.435282] systemd[1]: Condition check resulted in Kernel Module supporting RPCSEC_GSS being skipped.
[    7.460415] systemd[1]: Starting Restore / save the current clock...
[    7.478930] systemd[1]: Starting Set the console keyboard layout...
[    7.498063] systemd[1]: Starting Create list of static device nodes for the current kernel...
[    7.523088] systemd[1]: Starting Load Kernel Module configfs...
[    7.542141] systemd[1]: Starting Load Kernel Module drm...
[    7.560197] systemd[1]: Starting Load Kernel Module fuse...
[    7.583682] systemd[1]: Condition check resulted in Set Up Additional Binary Formats being skipped.
[    7.604731] systemd[1]: Starting File System Check on Root Device...
[    7.640570] systemd[1]: Starting Journal Service...
[    7.669829] fuse: init (API version 7.37)
[    7.682698] systemd[1]: Starting Load Kernel Modules...
[    7.711771] systemd[1]: Starting Coldplug All udev Devices...
[    7.749131] systemd[    8.016146] systemd[1]: Started File System Check Daemon to report status.
[    8.035501] systemd[1]: Starting Apply Kernel Variables...
[    8.053654] systemd[1]: Started Journal Service.

Raspbian GNU/Linux 11 raspberrypi ttyS0

raspberrypi login: pi
Password:
Linux raspberrypi 6.1.21-v7+ #1642 SMP Mon Apr  3 17:20:52 BST 2023 armv7l

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Sun Jan 14 15:21:37 GMT 2024 on ttyS0
pi@raspberrypi:~$ echo 1; echo EJFAL23vQqk2JcBTF1z1q
1
EJFAL23vQqk2JcBTF1z1q
pi@raspberrypi:~$ whoami; echo Ti-yimOo-awRdBnelTNfg
pi
Ti-yimOo-awRdBnelTNfg
pi@raspberrypi:~$ sleep 3; echo Lkgi_qlL2T1Zd0N4KFpi@raspberrypi:~$ curl baidu.com; echo ULtVVdR84yqXgzfZbBTXa
<html>
<meta http-equiv="refresh" content="0;url=http://www.baidu.com/">
</html>
ULtVVdR84yqXgzfZbBTXa
pi@raspberrypi:~$ ping -c 3 baidu.com; echo zULPEkcB9eKmemvxTWksm
PING baidu.com (110.242.68.66) 56(84) bytes of data.
64 bytes from 110.242.68.66 (110.242.68.66): icmp_seq=1 ttl=54 time=9.83 ms
64 bytes from 110.242.68.66 (110.242.68.66): icmp_seq=2 ttl=54 time=14.6 ms
64 bytes from 110.242.68.66 (110.242.68.66): icmp_seq=3 ttl=54 time=12.8 ms

--- baidu.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 9.832/12.399/14.598/1.963 ms
zULPEkcB9eKmemvxTWksm
pi@raspberrypi:~$ curl "https://mirror.iscas.ac.cn/ruyisdk/ruyi/testing/ruyi.arm64.20231211" --output ruyi; echo gzKz6jYf2Fx1LZKllTICI
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  9.9M  100  9.9M    0     0  4196k      0  0:00:02  0:00:02 --:--:-- 4196k
gzKz6jYf2Fx1LZKllTICI
pi@raspberrypi:~$ chmod +x ./ruyi; echo oe2Pc-bu4FGZfQgmVsa3U
oe2Pc-bu4FGZfQgmVsa3U
pi@raspberrypi:~$ export PATH=$PATH:$(pwtmpfs           5.0M  4.0K  5.0M   1% /run/lock
/dev/mmcblk0p1  255M   51M  205M  20% /boot
tmpfs            93M     0   93M   0% /run/user/1000
PO9_qrDTxK-X4_tc9anJP
pi@raspberrypi:~$
folder/test1

# you can also choose the pre-release snapshot version
# ruyi extract coremark --prerelease
ruyi extract coremark

# customize and build
. /ruyitestfolder/venv2/bin/ruyi-activate
sed -i 's/^Hgcc^H/riscv64-plctxthead-linux-gnu-gcc/g' linux64/core_portme.mak
make PORT_DIR=linux64 link
# check the resulting coremark.exe
file coremark.exe
# coremark.exe: ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-riscv64xthead-lp64d.so.1, BuildID[sha1]=d9510c5fef107e2c56b40547a02f1488471dd2d2, for GNU/Linux 4.15.0, with debug_info, not stripped
ruyi-deactivate
popd
rm -rf /ruyite; echo gU5lMZYBYHU-cyUSw9asw
pi@raspberrypi:~$ ruyi install gnu-plct gnu-plct-xthead
-bash: /home/pi/ruyi: cannot execute binary file: Exec format error
pi@raspberrypi:~$ ruyi venv -t gnu-plct milkv-duo /ruyitestfolder/venv1
-bash: /home/pi/ruyi: cannot execute binary file: Exec format error
pi@raspberrypi:~$ ruyi venv -t gnu-plct-xthead sipeed-lpi4a /ruyitestfolder/venv2
-bash: /home/pi/ruyi: cannot execute binary file: Exec format error
pi@raspberrypi:~$
pi@raspberrypi:~$ # test pre-packaged demos
pi@raspberrypi:~$ mkdir /ruyitestfolder/test1
mkdir: cannot create directory ‘/ruyitestfolder/test1’: No such file or directory
pi@raspberrypi:~$ pushd /ruyitestfolder/test1
-bash: pushd: /ruyitestfolder/test1: No such file or directory
pi@raspberrypi:~$
pi@raspberrypi:~$ # you can also choose the pre-release snapshot version
pi@raspberrypi:~$ # ruyi extract coremark --prerelease
pi@raspberrypi:~$ ruyi extract coremark
-bash: /home/pi/ruyi: cannot execute binary file: Exec format error
pi@raspberrypi:~$
pi@raspberrypi:~$ # customize and build
pi@raspberrypi:~$ . /ruyitestfolder/venv2/bin/ruyi-activate
-bash: /ruyitestfolder/venv2/bin/ruyi-activapi@raspberrypi:~$ # coremark.exe: ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-riscv64xthead-lp64d.so.1, BuildID[sha1]=d9510c5fef107e2c56b40547a02f1488471dd2d2, for GNU/Linux 4.15.0, with debug_info, not stripped
pi@raspberrypi:~$ ruyi-deactivate
-bash: ruyi-deactivate: command not found
pi@raspberrypi:~$ popd
-bash: popd: directory stack empty
pi@raspberrypi:~$ rm -rf /ruyitestfolder/test1
pi@raspberrypi:~$
pi@raspberrypi:~$ # test with any source repo convenient for you
pi@raspberrypi:~$ # here zlib-ng is used as an example
pi@raspberrypi:~$ # note zlib-ng's RVV code can't be built with the gnu-plct-xthead toolchain package
pi@raspberrypi:~$ git clone https://github.com/zlib-ng/zlib-ng.git /ruyitestfolder/zlib-ng --depth 1
-bash: git: command not found
pi@raspberrypi:~$ mkdir /ruyitestfolder/test2
mkdir: cannot create directory ‘/ruyitestfolder/test2’: No such file or directory
pi@raspberrypi:~$ pushd /ruyitestfolder/test2
-bash: pushd: /ruyitestfolder/test2: No such file or directory
pi@raspberrypi:~$ . /ruyitestfolder/venv1/bin/ruyi-activate
-bash: /ruyitestfolder/venv1/bin/ruyi-activate: No such file or directory
pi@raspberrypi:~$ cmake /ruyitestfolder/zlib-ng -G Ninja -DCMAKE_C_COMPILER=riscv64-plct-linux-gnu-gcc -DCMAKE_INSTALL_PREFIX=/ruyitestfolder/venv1/sysroot -DCMAKE_C_FLAGS="-O2 -pipe -g" -DZLIB_COMPAT=ON -DWITH_GTEST=OFF
-bash: cmake: command not found
pi@raspberrypi:~$ ninja
-bash: ninja: command not found
pi@raspberrypi:~$ ninja install
-bash: ninja: command not found
pi@raspberrypi:~$ # check the sysroot
pi@raspberrypi:~$ ls /ruyitestfolder/venv1/sysroot/include
ls: cannot access '/ruyitestfolder/venv1/sysroot/include': No such file or directory
pi@raspberrypi:~$
pi@raspberrypi:~$ ruyi-deactivate
-bash: ruyi-deactivate: command not found
pi@raspberrypi:~$ popd
-bash: popd: directory stack empty
pi@raspberrypi:~$ rm -rf /ruyitestfolder/test2
pi@raspberrypi:~$ ; echo gU5lMZYBYHU-cyUSw9asw%
```
