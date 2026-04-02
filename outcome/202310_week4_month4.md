# 2023 年 11 月第 1 周

- 完成 ruyisdk openQA 初步代码[commit](https://gitee.com/yan-mingzhu/os-autoinst-distri-openeuler/compare/d115e620c1ec65fb6d1df09fae2e7e8dde2b9650...d44cba23fbee4db3e393abde3ee8cfd54d96a1ce)
- 测试 ruyisdk 在 oerv2309 运行情况。目前二进制只为 x86 构建，ruyusdk 已经编写了为 riscv 打包的相关代码，但未实际发包
- openQA 接入 openEuler x86 gnome 镜像，cloud 镜像。编写用例，添加 needle 支持不同系统运行 bootloader，重启，登录等初始化流程
- 调研 riscv-test 测试用例的编译，运行，流程。测试测试用例基本结构，运行成功判定方法
- 调研 ruyisdk 可执行文件依赖第三方库情况，依赖 git。ruyisdk 打包的二进制对不同发行版支持情况