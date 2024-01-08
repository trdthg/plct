# 本周工作

## autotest

github: <https://github.com/trdthg/t-autotest>

自动化测试框架本周工作

- cli 模块 (提供命令行工具入口进程)
  - Feature
    - autotest: 提供命令行入口：`autotest -f <config.toml> -c <case.js>`
- console 模块 (负责和机器终端交互)
  - ssh
    - Feature
      - connect: 支持 private_key, password 登录
      - exec_global: 交互式运行脚本
      - exec_seperate: 在单独 session 运行命令
      - read_global_until: 等待匹配的文本
  - serial
    - Feature
      - connect: 支持 password 登录
      - exec_global: 交互式运行脚本
  - vnc
    - Feature
      - connect: 提供 vnc 连接，登录
      - pool: 启动事件循环
- binding 模块 (负责测试脚本对接)
  - js (基于 quickjs 完成 JS 测试脚本运行)
    - Feature
      - api
        - assert_script_run_ssh_global: 调用 ssh 在主 session 执行脚本
        - assert_script_run_ssh_seperate: 调用 ssh 在分离 session 执行脚本
        - assert_script_run_serial_seperate: 调用 ssh 在主 session 执行脚本
- config 模块 (提供测试，命令行 需要的通用配置文件解析)
- util 模块 (工具库)

完整配置参考：

```toml
log_dir = "testresult"
[console]

[console.ssh]
enable           = true
host             = "127.0.0.1"
port             = 22
username         = ""
auth.type        = "PrivateKey"
auth.password    = ""
auth.private_key = ""

[console.serial]
enable     = true
auto_login = false
# username    = "username"
# password    = "password"
serial_file = "/dev/ttyUSB0"
bund_rate   = 115200

[console.vnc]
enable   = false
host     = "127.0.0.1"
port     = 5900
password = ""
```

js 测试脚本参考：

```js
assert_script_run_ssh_seperate("whoami", 12000);
assert_script_run_ssh_global("w -h", 12000);

const a = () => {
    assert_script_run_ssh_global("tty", 6000);
    // assert_screen("//", 600);
}
a()

assert_script_run_ssh_seperate("sleep 3", 12000);

assert_script_run_serial_global("tty", 12000);
```
