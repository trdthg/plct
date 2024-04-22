# ruyi GUI 测试

## ubuntu-2204-desktop

### 镜像准备

- 从 ubuntu 官网下载的原始镜像文件得到 `raw.iso`
- 由 qemu-img 命令转换后的镜像文件 `raw.qcow2`

    ```sh
    qemu-img convert -f raw -O qcow2 raw.iso raw.qcow2
    qemu-img resize raw.qcow2 20G
    ```

- cp 得到 `<SCREENSHOT_NAME>.qcow2` 作为快照，用于跳过测试脚本执行的共同时刻

- 为镜像提前设置好用户密码：`virt-customize -a ./raw.qcow2 --root-password password:somepassword`

### qemu 启动

```bash
img=./begin.qcow2

qemu-system-x86_64 \
    -smp 4 -m 4G \
    -enable-kvm \
    -vnc :45 \
    -hda "$img" \
    -snapshot \
    -device virtio-net,netdev=network0 \
    -netdev user,id=network0,hostfwd=tcp::2222-:22 \
    -device virtio-gpu-pci \
    -device qemu-xhci,id=xhci -device usb-tablet,bus=xhci.0 -device usb-kbd \
    -chardev pty,id=charserial0 \
    -serial chardev:charserial0
```
