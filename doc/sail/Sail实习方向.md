# Sail

## 相关的仓库

- [sail-riscv (基于 sail 语言编写的 riscv 模拟器)](https://github.com/riscv/sail-riscv)
- [sail 语言](https://github.com/rems-project/sail)
- [ACT 测试](https://github.com/riscv-non-isa/riscv-arch-test)
  - [riscv-ctg 测试生成器](https://github.com/riscv-software-src/riscv-ctg)
  - [RISC-V 测试框架](https://github.com/riscv-software-src/riscof)
  - [RISCV ISA 覆盖率提取工具](https://github.com/riscv-software-src/riscv-isac)
  - [riscof 测试执行器](https://github.com/riscv-software-src/riscof)

## 资料/工具

- [riscv 指令集参考官网](https://riscv.org/technical/specifications/)
- [sail 语言手册](https://alasdair.github.io/manual.html)
- [vscode 插件](https://marketplace.visualstudio.com/items?itemName=TimHutt.sail-vscode)
- [公开报告](https://space.bilibili.com/296494084/search/video?keyword=sail)

## 可选任务

- 为 sail-riscv 开发新的功能支持，例如实现未实现的指令集等，可参考仓库现有/已合并 PR
- 修复仓库现有 issue，潜藏的 bug 等
- 如果 issue 是上游 sail 语言导致，或者是 sail bug 引起下游 ACT 测试出现问题，也可以尝试修复
- 参考 sail_riscv 的 prover_snapshots 文件夹做一些 RISCV 形式化验证方面的研究，sail 语言目前有 coq, lem, 和正在开发的 lean 等后端

## 考核要求

- 时间 2 周
- 提交 PR
  - 必须通过 CI
  - 保证一定的代码质量
  - 不能太简单，例如修复 typo 等
  - 注意不要当前 PR 功能重复
- PR 提交后，还需要一个 PPT 形式的技术报告。可以讲难点，你的思维过程，解决方法
  - 如果 PR 质量不合格，则视为考核失败
