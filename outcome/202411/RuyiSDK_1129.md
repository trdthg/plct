# RuyiSDK

## 1. 安装 ruyi 包管理器

<https://ruyisdk.org/en/docs/Package-Manager/installation>

```shell=
wget https://github.com/ruyisdk/ruyi/releases/download/0.22.0/ruyi-0.22.0.amd64
chmod +x ruyi-0.22.0.amd64
sudo mv ruyi-0.22.0.amd64 /usr/bin/ruyi
ruyi
```

> 部分发行版也可以直接通过包管理器安装

## 2. ruyisdk 使用案例

### 2.1 使用 ruyi 包管理器极速搭建你的干净开发环境

```shell=
# 安装工具链
ruyi install qemu-user-riscv-upstream gnu-plct

# 创建虚拟环境
ruyi venv -t gnu-plct generic -e qemu-user-riscv-upstream ./venv

# 激活虚拟环境
source ./venv/bin/ruyi-activate

# 检查工具链
# ls ./venv/bin

# 测试
cat <<EOF | riscv64-plct-linux-gnu-gcc -xc -
#include<stdio.h>
int main() {
    printf("Hello World!\n");
    return 0;
}
EOF
file a.out
ruyi-qemu a.out

# 退出虚拟环境 (ruyi-deactivate 是一个在当前 shell 注册的函数)
# ruyi-deactivate
```

### 2.2 轻松切换玄铁工具链，支持厂商拓展指令集

```c=
#include<stdio.h>

const int shift = 1;

int addsl(int a, int b)
{
    int result;
    // rd = rs1 + (rs2 << imm2)
    asm volatile(
        "addsl %[rd], %[rs1], %[rs2], %[imm2]"
        : [rd] "=r"(result)
        : [rs1] "r"(a), [rs2] "r"(b), [imm2] "i"(shift));
        // https://gcc.gnu.org/onlinedocs/gcc/Machine-Constraints.html
    return result;
}

int main() {
    printf("1 + 2 << 1 = %d\n", addsl(1, 2));
    return 0;
}
```

编译命令

```shell=
source ./venv/bin/ruyi-activate
riscv64-plct-linux-gnu-gcc -march=rv64gcxtheadc addsl.c
ruyi-deactivate
```

上游工具链不支持玄铁扩展指令集，我们需要切换厂商工具链

```shell=
ruyi install gnu-plct-xthead qemu-user-riscv-xthead
ruyi venv -t gnu-plct-xthead generic -e qemu-user-riscv-xthead ./venv-xthead
source ./venv-xthead/bin/ruyi-activate
ls ./venv-xthead/bin

riscv64-plctxthead-linux-gnu-gcc -march=rv64gcxtheadc addsl.c
ruyi-qemu a.out
ruyi-deactivate
```

### 2.3 无障碍管理多版本工具链

> For RISC-V conditional branch, the branch targets should be within `+-4K` off pc

```s=
        .text
        .globl  main
main:
        bne     a0, a1, .L1
        .fill   1300, 4, 0x0
.L1:
        ret
        beqz    a0, .L2
        .fill   1300, 4, 0x0
.L2:
        ret
```

使用 LLVM 的汇编器将汇编代码 `long_jump.s` 编译为 `.o` 文件

```shell=
ruyi install llvm-plct
ruyi venv -t llvm-plct generic  --sysroot-from gnu-upstream -e qemu-user-riscv-xthead ./venv-clang
source ./venv-clang/bin/ruyi-activate

llvm-mc-14 -arch=riscv64 -filetype=obj long_jump.s -o long_jump.o
llvm-mc -arch=riscv64 -filetype=obj long_jump.s -o long_jump.o
ruyi-deactivate
```

> commit: <https://github.com/llvm/llvm-project/commit/98117f1a743cbddefa3dd1c678ce01478fa98454>

### 2.4 切换到 clang 并自由组合 sysroot，解决不兼容

在链接过程中起作用，作为交叉编译工具链搜索库文件的根路径

clang 会使用 gnu-toolchain 中的某些库，他们之间也有兼容性的问题

> 对于没有深入了解过 gcc 各项参数，链接器参数，默认被读取的相关环境变量等，很难解决类似问题

```cpp=
// https://godbolt.org/z/vYrefnPYs
template<typename T>
struct S
{
  const int v;
  S<T>& operator=(const S<T>& rhs)
  {
    v = rhs.v;
    return (*this);
  }
};
```

![img](/uploads/upload_75f5a87e0aa775b8b09536c7e248de0c.png)

```shell=
ruyi install llvm-plct
ruyi venv -t llvm-plct generic --sysroot-from gnu-plct -e qemu-user-riscv-upstream ./venv-llvm
ls venv-llvm/bin
ruyi-qemu a.out
```

## 3. 使用 ruyisdk 刷写开发板镜像

刷板子不一定简单

- 个别开发板，例如荔枝派 4A 提供的 emmc [刷写流程复杂](<https://wiki.sipeed.com/hardware/zh/lichee/th1520/lpi4a/4_burn_image.html#Linux-%E7%B3%BB%E7%BB%9F%E6%AD%A5%E9%AA%A4>), 需要安装 fastboot 烧录工具，检查并格式化分区，再分别烧录 3 个镜像

> micropython 可以使用简单的 python 语法入门单片机，极大地降低了单片机的门槛。最大的门槛反而是找固件和烧录

但是 ruyi 提供了命令帮你全自动刷板子

```shell=
The following devices are currently supported by the wizard. Please pick your device:

   1. Allwinner Nezha D1
   2. Canaan Kendryte K230
   3. Canaan Kendryte K230D
   4. Canaan Kendryte K510
   5. Milk-V Duo
   6. Milk-V Duo S
   7. Milk-V Mars
   8. Milk-V Mars CM
   9. Milk-V Meles
  10. Milk-V Pioneer Box
  11. Milk-V Vega
  12. Pine64 Star64
  13. SiFive HiFive Unmatched
  14. Sipeed Lichee Cluster 4A
  15. Sipeed Lichee Console 4A
  16. Sipeed LicheePi 4A
  17. Sipeed Lichee RV
  18. Sipeed LicheeRV Nano
  19. Sipeed Maix-I
  20. Sipeed Tang Mega 138K Pro
  21. StarFive VisionFive
  22. StarFive VisionFive2
  23. WCH CH32V103 EVB
  24. WCH CH32V203 EVB
  25. WCH CH32V208 EVB
  26. WCH CH32V303 EVB
  27. WCH CH32V305 EVB
  28. WCH CH32V307 EVB
  29. WCH CH582F EVB
  30. WCH CH592X EVB
```

我们以荔枝派 4A 刷写 **revyos** 系统为例

## 4. 支持矩阵

### eg1: Arch Linux on LicheePi 4A

对于 Arch Linux, 其只提供一个基本的 rootfs，而非一个能直接刷入的镜像，因此需要手动创建镜像并刷入：

```shell=
sudo dd if=/dev/zero of=rootfs.ext4 bs=1M count=6144
sudo mkfs.ext4 rootfs.ext4
mkdir mnt
sudo mount ./rootfs.ext4 ./mnt

wget https://mirror.iscas.ac.cn/archriscv/images/archriscv-latest.tar.zst
sudo tar -I zstd -xvf archriscv-latest.tar.zst -C mnt/

# lsblk -o NAME,UUID
# export UUID=xxx
```

```shell=
sudo systemd-nspawn -D ./mnt --machine=archriscv

# The following commands are executed inside rootfs
pacman -Syu
pacman -Syu fastfetch
echo "UUID=$UUID /  ext4  defaults  1  1 " >> /etc/fstab
passwd
exit

sudo umount ./mnt
```

```shell=
wget https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/20240720/u-boot-with-spl-lpi4a.bin
wget https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/20240720/boot-lpi4a-20240720_171951.ext4.zst
zstd -d boot-lpi4a-20240720_171951.ext4.zst
sudo fastboot flash ram ./u-boot-with-spl-lpi4a.bin
sudo fastboot reboot
sudo fastboot flash uboot ./u-boot-with-spl-lpi4a.bin
sudo fastboot flash boot boot-lpi4a-20240720_171951.ext4
sudo fastboot flash root rootfs.ext4
```

然后重新启动 LicheePi 4A，能看到 Arch Linux 被启动。

### 根据支持矩阵搭建 Linux WCH 开发环境

官方只提供了基于 Eclipse 平台二次开发的集成 IDE 环境，通过探索，找出了基于 Platform IO 或 Makefile 创造开发环境的方法。

#### Platform IO

Platform IO 有社区人士为其提供了集成开发环境，进行安装后使用：

```shell=
curl -fsSL -o get-platformio.py https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py
python3 get-platformio.py
pio pkg install -g -p https://github.com/Community-PIO-CH32V/platform-ch32v.git
```

```shell=
curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules
cat << EOF | sudo tee -a /etc/udev/rules.d/99-platformio-udev.rules
SUBSYSTEM=="usb", ATTR{idVendor}="1a86", ATTR{idProduct}=="8010", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}="4348", ATTR{idProduct}=="55e0", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}="1a86", ATTR{idProduct}=="8012", GROUP="plugdev"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -a -G dialout $USER
sudo usermod -a -G plugdev $USER
```

```shell=
git clone https://github.com/Community-PIO-CH32V/platform-ch32v.git
cd platform-ch32v/examples/blinky-freertos
pio run
```

#### Makefile

下载工具后，直接用支持矩阵中提供的 Makefile 即可。编写的 Makefile 中涵盖了 prepare make flash 命令。

## 交流讨论

- make 和 ruyisdk 的关系
- 选开发板的依据
- ruyisdk 的灵感，和其他包管理器的区别
- 支持矩阵的状况和测试报告和支持状态
