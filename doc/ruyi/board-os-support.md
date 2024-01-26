# 开发板系统支持情况调研

## M5Stack STAMP-C3

- FreeRTOS: 有官方支持 <https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32c3/api-reference/system/freertos_idf.html>
- RT-Thread: <https://github.com/RT-Thread/rt-thread/blob/master/bsp/ESP32_C3/README_ZH.md>
- Zephyr: <https://docs.zephyrproject.org/latest/boards/riscv/esp32c3_devkitm/doc/index.html>
- ThreadX: 有官方支持，但是仅限于 xtensa 架构，不支持 riscv 架构的 C3 开发板，相关讨论间：<https://esp32.com/viewtopic.php?t=19593#p123591>
- HuaWei Lite OS: 推测不支持，官方有文档：<https://gitee.com/LiteOS/LiteOS/blob/master/targets/ESP32/README_QEMU_CN.md>, 但是只提到 ESP32, 并未说明是什么架构，另一篇使用 QEMU 模拟运行的[文档](https://gitee.com/LiteOS/LiteOS/blob/master/targets/ESP32/README_QEMU_CN.md)使用的是是 `qemu-system-xtensa`, 故推测不支持 riscv

## ITE IT82XX2 series

- Zephyr: 有官方支持 <https://docs.zephyrproject.org/latest/boards/riscv/it82xx2_evb/doc/index.html>
- FreeRTOS: 未知，ITE 官方几乎没有任何文档，只有[开发板手册](https://www.ite.com.tw/uploads/product_download/IT82302_A_V0.3.1_20230317.pdf), 但是只提到了某几个引脚可以用于 FreeRTOS

## ITE IT8XXX2 series

- 同上，[开发板手册](https://www.ite.com.tw/uploads/product_download/IT82202_A_V0.3.1_20230317.pdf)

## Microchip M2GL025 Mi-V

- FreeRTOS: 有官方支持 <https://www.freertos.org/zh-cn-cmn-s/RTOS-RISC-V-SoftConsole-Renode-SiFive.html>
- Zephyr: 有官方支持 <https://docs.zephyrproject.org/latest/boards/riscv/m2gl025_miv/doc/index.html>

## Microchip mpfs_icicle

- FreeRTOS: MCU 似乎支持，有相关的官方代码示例 <https://onlinedocs.microchip.com/pr/GUID-46081D71-4DF0-4E02-8253-CC33B7E6C196-en-US-4/index.html?GUID-37BE593D-6954-4D99-832E-FE9B10F1EC6E>
- Zephyr: 有官方支持 <https://docs.zephyrproject.org/latest/boards/riscv/mpfs_icicle/doc/index.html>
