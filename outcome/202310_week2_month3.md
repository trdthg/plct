# 2023 年 10 月 第二周

2023.10.16 ~ 2023.10.20

## 本周工作

- 参加周三技术分享，openQA 自动化测试框架
- 修改 oerv_tests 测试失败重试策略为重启，调整涉及到的其他相关脚本的路径问题
- oerv_tests 支持通过环境变量运行自定义脚本，解决 rc5 镜像软件源问题
  - <https://gitee.com/yunxiangluo/os-autoinst-distri-openeuler/pulls/4>
- 解决 openQA 多机网络配置，编写 mugen 多机测试代码
  - <https://gitee.com/yunxiangluo/os-autoinst-distri-openeuler/pulls/5>
  - <https://gitee.com/yunxiangluo/os-autoinst-needles-openeuler/pulls/3>
- 排查 mugen 测试运行过程中终端断开，导致测试无法继续运行
  - 测试套运行到 systemd - initrd-clean.service 时，在 pre_test 阶段运行失败，相关命令：

      ```bash
      touch /etc/initrd.release
      systemctl start initrd-cleanup.target
      ```

  - 原因：host 运行的机器为 22.03，需要进一步手动测试
