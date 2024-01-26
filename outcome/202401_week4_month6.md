# 本周工作

## ruyi

### 调研

- 调研 [基于 VSCode 以任一个 demo 走通 RUST RISC-V 交叉编译和运行过程](https://github.com/ruyisdk/pmd/issues/7): [文档](../doc/ruyi/vscode-rust.md)
- 完成 lldb 调试器和 gdb 调试器调研，文档同上
- 附带基于 vscode 远程调试树莓派 (arm), 文档同上

- 调研开发板操作系统支持情况：文档 (../doc/ruyi/board-os-support.md)

## [autotest](https://github.com/trdthg/t-autotest)

自动化测试框架本周工作

### Release

- 下载地址：<https://github.com/trdthg/t-autotest/releases>

- v0.2.0-rc2
- v0.2.0-rc1
- v0.1.0

### Feature

- 新增 api
  - assert_script_run_global: 自动根据 console 选择 serial 或者 ssh 交互，遇到错误抛出错误
  - script_run_global: 同上，运行命令，返回值不为 0 不处理
  - write_string_global: 同上，超时不处理
  - wait_string_global: 同上，等待输出

### 测试用例开发

#### poineerbox(debian)

- 宿主机：wiondows
- 测试方法：ssh
- 测试工具版本：v0.2.0

#### VF2(ubuntu)

- 宿主机：arch
- 测试方法：serial
- 测试工具版本：v0.2.0-rc2
