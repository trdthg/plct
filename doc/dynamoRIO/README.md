# dynamoRIO

## 构建

`cmake ..` 默认构建 Release, 如果需要 Debug, 可以使用 `cmake -DDEBUG=ON ..`

```bash
# Install dependencies for Ubuntu 15+.  Adjust this command as appropriate for
# other distributions (in particular, use "cmake3" for Ubuntu Trusty).
sudo apt-get install cmake g++ g++-multilib doxygen git zlib1g-dev libunwind-dev libsnappy-dev liblz4-dev
# Get sources and initialize the submodules.
git clone --recurse-submodules -j4 https://github.com/DynamoRIO/dynamorio.git
# Make a separate build directory.  Building in the source directory is not
# supported.
cd dynamorio && mkdir build && cd build
# Generate makefiles with CMake.  Pass in the path to your source directory.
cmake ..
# Build.
make -j
# Run echo under DR to see if it works.  If you configured for a debug or 32-bit
# build, your path will be different.  For example, a 32-bit debug build would
# put drrun in ./bin32/ and need -debug flag to run debug build.
./bin64/drrun echo hello world
hello world
```

## 测试

```bash
cmake -DBUILD_TESTS=ON ../dynamorio
make -j
make test
```

## 交叉编译

参考文档 AArch 交叉编译：

```bash
sudo apt-get install g++-aarch64-linux-gnu
cmake -DCMAKE_TOOLCHAIN_FILE=../dynamorio/make/toolchain-arm64.cmake ../dynamorio
```

实际运行时会遇到 ZLIB not found

```txt
CMake Error at ext/drsyms/CMakeLists.txt:228 (message):
  zlib not found but required to build drsyms_static on Linux
```

安装 zlib `sudo apt-get install pkg-config zlib1g zlib1g-dev` 后依然无效，经过查询 `/usr/lib` 下确实有 `zlib.so`

添加构建参数：`-DZLIB_INCLUDE_DIR=/usr/include -DZLIB_LIBRARY=/usr/lib` 再次测试，cmake 提示 WARNING:

```txt
CMake Warning:
  Manually-specified variables were not used by the project:

    CMAKE_TOOLCHAIN_FILE
```

`make -j` 依然报错：

```txt
undefined reference to symbol 'inflate'
```

经过调查，此错误的出现依然和 ZLIB 有关

尝试按照 `ci-riscv.yaml` 文件里的方式安装环境

```bash
sudo apt-get update
sudo apt-get -y install doxygen vera++ cmake crossbuild-essential-riscv64 git  \
    qemu-user qemu-user-binfmt
sudo add-apt-repository 'deb [trusted=yes arch=riscv64] http://deb.debian.org/debian sid main'
apt download libunwind8:riscv64 libunwind-dev:riscv64 liblzma5:riscv64 \
    zlib1g:riscv64 zlib1g-dev:riscv64 libsnappy1v5:riscv64 libsnappy-dev:riscv64 \
    liblz4-1:riscv64 liblz4-dev:riscv64
mkdir ../extract
for i in *.deb; do dpkg-deb -x $i ../extract; done
for i in include lib; do sudo rsync -av ../extract/usr/${i}/riscv64-linux-gnu/ /usr/riscv64-linux-gnu/${i}/; done
sudo rsync -av ../extract/usr/include/ /usr/riscv64-linux-gnu/include/
if test -e "../extract/lib/riscv64-linux-gnu/"; then \
    sudo rsync -av ../extract/lib/riscv64-linux-gnu/ /usr/riscv64-linux-gnu/lib/; \
fi
```

add-app-repository 缺少一项依赖可以安装以下包解决：

```bash
sudo apt-get install software-properties-common
```

运行最后会报一个 GPG error, 但是对后续步骤无影响

```bash
$ sudo add-apt-repository 'deb [trusted=yes arch=riscv64] http://deb.debian.org/debian sid main'
Repository: 'deb [arch=riscv64 trusted=yes] http://deb.debian.org/debian sid main'
Description:
Archive for codename: sid components: main
More info: http://deb.debian.org/debian
Adding repository.
Press [ENTER] to continue or Ctrl-c to cancel.
Found existing deb entry in /etc/apt/sources.list.d/archive_uri-http_deb_debian_org_debian-jammy.list
Adding deb entry to /etc/apt/sources.list.d/archive_uri-http_deb_debian_org_debian-jammy.list
Found existing deb-src entry in /etc/apt/sources.list.d/archive_uri-http_deb_debian_org_debian-jammy.list
Adding disabled deb-src entry to /etc/apt/sources.list.d/archive_uri-http_deb_debian_org_debian-jammy.list
Get:1 http://deb.debian.org/debian sid InRelease [198 kB]                                       
Get:2 http://security.ubuntu.com/ubuntu jammy-security InRelease [110 kB]                                 
Hit:3 http://archive.ubuntu.com/ubuntu jammy InRelease                                                    
Get:4 http://archive.ubuntu.com/ubuntu jammy-updates InRelease [119 kB]                   
Get:5 http://security.ubuntu.com/ubuntu jammy-security/restricted amd64 Packages [1,894 kB]         
Ign:1 http://deb.debian.org/debian sid InRelease         
Hit:6 http://archive.ubuntu.com/ubuntu jammy-backports InRelease
Get:7 http://security.ubuntu.com/ubuntu jammy-security/main amd64 Packages [1,522 kB]
Fetched 3,844 kB in 7s (591 kB/s)                                                                                                    
Reading package lists... Done
W: GPG error: http://deb.debian.org/debian sid InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 0E98404D386FA1D9 NO_PUBKEY 6ED0E7B82643E131
```

经过安装后，编译成功

## 运行测试集

携带部分测试用参数编译：

```bash
cmake -DCMAKE_TOOLCHAIN_FILE=../dynamorio/make/toolchain-riscv64.cmake -DBUILD_TESTS=ON -DBUILD_TOOLS=ON -DBUILD_SAMPLES=ON ../dynamorio
```

由于测试机并没有全部移植到 riscv 下，这里只按照 ci 运行一部分已适配的测试：

手动运行 ctest 测试

```bash
ctest -L RUNS_ON_QEMU
```

按照 ci 方法测试：


```bash
DYNAMORIO_CROSS_AARCHXX_LINUX_ONLY=yes QEMU_LD_PREFIX=/usr/riscv64-linux-gnu/ ./suite/runsuite_wrapper.pl automated_ci 64_only
```

测试运行结束后会在当前目录生成 `result.txt`, 示例如下：

```txt
==================================================
RESULTS

aarch64-debug-internal: skipped (cross-compile configuration unavailable)
aarch64-release-external: skipped (cross-compile configuration unavailable)
WARNING: maximum warning/error limit hit for debug-internal-64!
  Manually verify whether it succeeded.
debug-internal-64: all 10 tests passed
WARNING: maximum warning/error limit hit for riscv64-debug-internal!
  Manually verify whether it succeeded.
riscv64-debug-internal: 0 tests passed, **** 2 tests failed: ****
	code_api|tool.drcachesim.simple 
	code_api|tool.drcacheoff.simple 
WARNING: maximum warning/error limit hit for riscv64-release-external!
  Manually verify whether it succeeded.
riscv64-release-external: build status **UNKNOWN**; no tests for this build

```

## 参考

- [comment](https://github.com/ruyisdk/ruyi/issues/50#issuecomment-1903791638)
- [build](https://dynamorio.org/page_building.html)
- [test](https://dynamorio.org/page_test_suite.html)
