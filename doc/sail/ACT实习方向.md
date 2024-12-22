# ACT

## 相关的仓库

- ACT 测试
  - [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test) 主仓库，包含测试用例，riscv-ctg（测试生成器），riscv-isac（覆盖率提取工具）三部分
  - [riscof](https://github.com/riscv-software-src/riscof) 测试执行器
- [sail-riscv (基于 sail 语言编写的 riscv 模拟器)](https://github.com/riscv/sail-riscv)
- [spike 模拟器](https://github.com/riscv-software-src/riscv-isa-sim)

> 注意原本 riscv-ctg 和 riscv-isac 位于单独的仓库，现在均已合并到 riscv-arch-test 仓库，[旧 riscv-ctg](https://github.com/riscv-software-src/riscv-ctg), [旧 riscv-isac](https://github.com/riscv-software-src/riscv-isac)

## 资料/工具

- 官方资料
  - act 文档请参考：[doc/README](https://github.com/riscv-non-isa/riscv-arch-test/blob/dev/doc/README.adoc) 和 README
  - 测试格式规范 <https://github.com/riscv-non-isa/riscv-arch-test/blob/dev/spec/TestFormatSpec.adoc>
  - ctg 文档 <https://riscv-ctg.readthedocs.io>
  - isac 文档 <https://riscv-isac.readthedocs.io/>
  - riscof 文档 <https://riscof.readthedocs.io>
  - [贡献指南](https://github.com/riscv-non-isa/riscv-arch-test/blob/dev/CONTRIBUTION.md)，同时注意 github pr 模板的内容
  - [riscv 指令集参考官网](https://riscv.org/technical/specifications/)
  - [riscv 工具链]
- 其他
  - [公开报告](https://space.bilibili.com/296494084/search/video?keyword=act)
  - [旧公开报告，可能已过时](https://www.bilibili.com/video/BV12Z4y1c74c?spm_id_from=333.788.videopod.episodes&vd_source=ca52b9789e5bf99cb693669e740b5c5d&p=14)

## 可选任务

- 为 act 开发新的功能支持，例如实现未实现的指令集等，可参考仓库现有/已合并 PR
- 修复 act 现有 issue，潜藏的 bug 等
- 如果 issue 是上游 sail-riscv 或者 spike 模拟器导致，也可以尝试修复

## 考核要求

- 时间 2 周
- 提交 PR
  - 必须通过 CI
  - 保证一定的代码质量
  - 不能太简单，例如修复 typo 等
  - 注意不要当前 PR 功能重复
- PR 提交后，还需要一个 PPT 形式的技术报告。可以讲难点，你的思维过程，解决方法
  - 如果 PR 质量不合格，则视为考核失败
