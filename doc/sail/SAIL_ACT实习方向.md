# SAIL / ACT

## 相关的仓库

- sail-riscv https://github.com/riscv/sail-riscv
- sail https://github.com/rems-project/sail
- ACT  https://github.com/riscv-non-isa/riscv-arch-test/tree/act4
- isla https://github.com/rems-project/isla litmus-tests-riscv https://github.com/litmus-tests/litmus-tests-riscv/

## 资料/工具

- [RISC-V 指令集参考官网](https://riscv.org/technical/specifications/)
- [RISC-V 扩展开发状态](https://riscv.atlassian.net/wiki/spaces/HOME/pages/16154861/RISC-V+Specs+Under+Development)
- [sail 语言手册](https://alasdair.github.io/manual.html)
- [vscode 插件](https://marketplace.visualstudio.com/items?itemName=TimHutt.sail-vscode)
- [ACT 开发指南](https://github.com/riscv-non-isa/riscv-arch-test/blob/act4/docs/DeveloperGuide.md)

## 可选任务

- 为 sail-riscv / sail 开发新的功能支持，例如未实现的扩展指令集等，可参考仓库现有/已合并 PR
- 为 ACT 开发新的测试支持，例如未实现的扩展指令集，可参考仓库现有/已合并 PR
- 修复仓库现有 issue，潜藏的 bug 等
- 参考 isla 和 litmus-tests-riscv 做一些 RISCV 形式化验证方面的研究
- 也欢迎分享其他想法

## 考核要求

- 时间 1-2 周
- 提交 PR
  - 必须通过 CI, 除非由 lean/rocq 导致
  - 保证一定的代码质量
  - 不能太简单，例如修复 typo 等
  - 注意确保不要和当仓库其他 PR 功能撞车
  - 如果 PR 质量不合格，则视为考核失败
- PR 提交后，还需要一个做一个技术报告
  - 时间固定每周三下午 3 点，腾讯会议，准备 PPT, 时长 30 分钟左右
  - 可以讲基础知识，问题背景，思维过程，难点，解决方法
