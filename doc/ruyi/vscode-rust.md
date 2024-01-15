# vscode rust 插件调研

## 安装

插件名称：rust-analyzer

插件下载地址：<https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer>

> 注意该插件可能和 [官方插件](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust) 产生冲突，后者已经不再维护

插件安装完成后会自动下载 rust-analyzer 二进制文件

注意事项：

1. rust-analyzer 需要标准库的源代码。如果源代码不存在，rust-analyzer 将尝试自动安装它。若要手动添加源，请运行以下命令：

    ```bash
    rustup component add rust-src
    ```

    > 只有最新的稳定标准库源代码才被正式支持与 rust-analyzer 一起使用。如果使用的是较旧的工具链，rust-analyzer 可能无法理解 Rust 源代码。需要更新工具链或使用与工具链兼容的旧版本的 rust-analyzer。
    `{ "rust-analyzer.server.extraEnv": { "RUSTUP_TOOLCHAIN": "stable" } }`

2. 仅支持两个最新版本的 VS Code

3. 如果 vscode 插件自动下载的插件在某些发行版 (不受支持的平台) 无法正常运行，可以手动下载或者编译获取 rust-analyzer 二进制文件，并路径添加到 `settings.json`：`{ "rust-analyzer.server.path": "~/.local/bin/rust-analyzer-linux" }`

## 如何进行 RISC-V Rust 的开发、编译、调试、运行

### 工程管理

rust-analyzer 插件几乎不提供任何直接的按钮，只有编译，调试，运行测试 ![Alt text](image.png)

工程管理完全依赖于命令行

cargo new <progect_name>

### 如何使用插件

rust-analyzer 会自动检查项目目录下的 `Cargo.toml` 文件运行代码静态检查

包含所有代码补全，高亮，跳转等功能

### 编译

对于 riscv target 项目的编译，有两种方式

- 添加配置文件 (.cargo/config.toml) 指定 target

    ```toml
    [build]
    target = "riscv64gc-unknown-linux-gnu"
    ```

    之后直接运行 `cargo build`

- 在命令行添加参数 `cargo build --target riscv64gc-unknown-linux-gnu`

### 调试

> (如何设断点单步跟踪调试？（可以是交叉调试）)
> 如何进行交叉调试？（目标运行在 qemu 和 riscv 开发板，分别如何调试？）

对于 x86 平台，vscode 插件可以调试 rust 程序，依赖于 [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb)

对于 riscv 平台，该插件

> CodeLLDB supports AArch64, ARM, AVR, MSP430, **RISCV**, X86 architectures and may be used to debug on embedded platforms via remote debugging.

## 运行

> 怎么集成 qemu 并在 qemu 中运行程序验证程序
