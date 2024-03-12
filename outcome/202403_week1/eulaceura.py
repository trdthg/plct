import logging
import time
import pyautotest

config = """
machine    = "alicloud"
arch       = "x86_64"
os         = "ubuntu"
log_dir    = "testresults-pytest-eulaceura"
needle_dir = "needles"

[env]
RUYI_BINARY_DOWNLOAD_LINK = "https://mirror.iscas.ac.cn/ruyisdk/ruyi/testing/ruyi.arm64.20231211"

[console]

[console.serial]
enable      = true
serial_file = "/dev/pts/0"
bund_rate   = 115200

auto_login = false
username   = "eula"
password   = "ceura"

[console.ssh]
enable = false
host = ""
port     = 22
username   = ""

[console.ssh.auth]
type = "Password"
password = ""

[console.vnc]
enable = false
host           = ""
port           = 5900
password       = ""
"""

def main():
    FORMAT = "%(levelname)s %(name)s %(asctime)-15s %(filename)s:%(lineno)d %(message)s"
    logging.basicConfig(format=FORMAT)
    logging.getLogger().setLevel(logging.NOTSET)

    os = subprocess.Popen(["bash", "-c", '''
    qemu-system-riscv64 \
        -nographic \
        -smp 4 -m 4G \
        -machine virt -bios fw_payload_oe_uboot_2304.bin \
        -device virtio-blk-device,drive=hd0 \
        -drive file=Eulaceura.riscv64-23H1-Server_vm2.qcow2,id=hd0,format=qcow2 \
        -device virtio-net-device,netdev=usernet \
        -netdev user,id=usernet,hostfwd=tcp::2222-:22 \
        -device virtio-gpu-pci -device qemu-xhci -device usb-tablet -device usb-kbd \
        -chardev pty,id=charserial0 \
        -serial chardev:charserial0
    '''],stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = process.communicate()
    time.sleep(1)

    pattern = re.compile(r"(/dev/pts/\d+)")
    output = output.decode()
    match = pattern.search(output)
    pts_file = match.group(0)

    print("match: ", output)
    print("match: ", pts_file)
    os.terminate()
    return

    logging.info("starting driver")

    driver = pyautotest.Driver(config=config)

    logging.info(driver)
    try:

        # may need logout
        time.sleep(10)
        res = driver.write_string("\x04\n")

        # wait login prompt
        driver.wait_string_ntimes("login:", 1, 1000 * 60 * 2)
        time.sleep(10)

        res = driver.write_string("eula\n")
        # wait password prompt
        driver.wait_string_ntimes("Password:", 1, 1000 * 60 * 2)
        res = driver.write_string("ceura\n")

        # wait login success
        driver.wait_string_ntimes("Last login", 1, 1000 * 60 * 2)
        time.sleep(3)

        # work
        res = driver.script_run_global("whoami", 5 * 1000)
        logging.info(f"res: {res}")

        res = driver.script_run_global("ls", 5 * 1000)
        logging.info(f"res: {res}")
    except Exception as e:
        logging.info("e", e)

    # ssh_driver = driver.new_ssh()
    # ssh_driver.assert_script_run("whoami", 5 * 1000)

    driver.stop()
    os.terminate()

if __name__ == "__main__":
    main()
