# 本周工作

## qtrvsim

- [PR108 状态更新：已合并](https://github.com/cvut/qtrvsim/pull/108)

## eulaceura

## autotest

- ci
  - [PR16](https://github.com/trdthg/t-autotest/pull/16) 自动构建 python whl 安装包，更新文档
- bug fix
  - [PR21](https://github.com/trdthg/t-autotest/pull/21) 支持串口热插拔

## ruyi

- 调研 ruyi device provision 命令自动化测试可行性
  - 命令在 (荔枝派 4A, revyOS) 环境下测试可用，[日志](./202403_week4/success.log)
  - 需要解决如下问题
    - 荔枝派 4A 烧录需要按住 boot 在上电，自动按下 boot 键并自动上电
    - 烧录完需要重启
    - 重复烧录需要重新插一线，否则 fastboot 会报错[日志](./202403_week4/success.log)
  - 其他：ruyi device provision 下载镜像阶段不需要 root 权限，在 dd 阶段会使用 sudo 命令拿的权限。即使 ruyi 本身是以 root 身份运行，或者 shell 环境已经有 root 权限，这对于 "no new privileges" flag is set 的环境不可用

## dynamoRIO
