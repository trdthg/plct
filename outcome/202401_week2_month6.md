# 本周工作

## ruyi

- 调研 [基于 VSCode 以任一个 demo 走通 RUST RISC-V 交叉编译和运行过程](https://github.com/ruyisdk/pmd/issues/7): [文档](../doc/ruyi/vscode-rust.md)
- 完成 lldb 调试器和 gdb 调试器调研，文档同上
- 附带基于 vscode 远程调试树莓派 (arm), 文档同上

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
