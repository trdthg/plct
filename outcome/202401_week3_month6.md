# 本周工作

## ruyi

### 调研

- 调研 [基于 VSCode 以任一个 demo 走通 RUST RISC-V 交叉编译和运行过程](https://github.com/ruyisdk/pmd/issues/7): [文档](../doc/ruyi/vscode-rust.md)
- 完成 lldb 调试器和 gdb 调试器调研，文档同上
- 附带基于 vscode 远程调试树莓派 (arm), 文档同上

## autotest

github: <https://github.com/trdthg/t-autotest>

自动化测试框架本周工作

### Feature

- console 模块 (负责和机器终端交互)
  - ssh, serial 优化，使用 event loop 处理事件交互
- binding 模块 (负责测试脚本对接)
  - js
    - api
      - xxx_assert_script_run: 增加命令返回值判断，如果不为 0, 则会 panic
      - xxx_script_run: 只运行命令，不处理返回值
      - xxx_write_string: 只输入一段字符串，不包含控制字符
- ci (github action)
  - `test.yaml`: 提交代码或 pr 时运行 cargo check, test, fmt, clippy, build(linux)
  - `build.yaml`: 自动分发 linux, macos, windows 三平台二进制文件。下载地址：<https://github.com/trdthg/t-autotest/releases>

### BugFix

- 修复 windows 无法正常编译

### 示例
