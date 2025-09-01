#import "@preview/grayness:0.1.0": grayscale-image
#import "@preview/touying:0.6.0": *
#import themes.metropolis: *
#import "@preview/chronos:0.2.1"

#import "@preview/numbly:0.1.0": numbly

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [SAIL-MODEL 如何攻克 RVSC-V 可配置性],
    subtitle: [基于自定义 JSON 的可配置性模板生成与配置合规验证方法],
    author: [Mingzhu Yan],
    date: datetime.today(),
    institution: [PLCT Lab],
  ),
)

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

= Outline <touying:hidden>

#outline(title: none, indent: 1em, depth: 1)

= 背景

== riscv 丰富的可配置性

1. 数十个扩展指令集
2. 不同扩展的依赖/兼容关系
3. 未定义行为
4. spec 不同版本
5. 不同的 profile (RVA22, RVA23 ...)

== sail-riscv 的目标

SAIL-MODEL 项目是对 RISC-V 指令集架构的精确描述

- SAIL-MODEL 使用 SAIL 语言编写
- SAIL 是一个领域特定语言, 具有专门为编写指令集设计的语法
- SAIL 语言可以被编译为 C 语言, 再借助 gcc/clang 编译为可执行文件

SAIL-MODEL 的目标是实现*完全的可配置性*

= 方法

== sail 的 config 语法

SAIL 内置了特殊语法与 JSON 配置文件交互

#image("image.png")

#image("image-1.png")

> 为了实现任意精度整数, sail 的 cJSON 代码被修改过, 将所有的数字都视为字符串解析

== 配置模板生成

#image("image-2.png")

https://github.com/riscv/sail-riscv/pull/1151


#grid(
  columns: (1fr, 1fr),
  column-gutter: 1em,
  image("image-3.png"), image("image-4.png"),
)

#image("image-5.png")

== schema 自动生成

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1em,
  image("image-8.png"), image("image-9.png"),
)

`sail --output-schema schema.json example.sail`

#image("image-6.png")

== schema 验证方案

验证方案选择依据

1. 许可证
2. 使用难度
3. 构建
4. 复杂度

#image("image-10.png")

基于 C 库的验证方案

- https://github.com/tristanpenman/valijson : valijson 依赖于一个具体的工作 json 库实现, cJSON 未被支持
- https://github.com/danielaparker/jsoncons : header-only 但不是单文件, 支持 CBOR 等其他格式处理

基于调用外部工具的验证方案

- https://github.com/santhosh-tekuri/boon : 需要用户自行在本地安装 boon

// = 结果

// == sail-riscv config 使用例

= 展望

== 自动生成验证代码

schema validator 无法完全满足我们的配置需求

- ELEN：单个元素的最大位数
  - 必须是 2 的幂
  - ELEN ≥ 2*3
- VLEN：向量寄存器的位数
  - 必须是 2 的幂
  - VLEN ≥ ELEN
  - VLEN ≤ 2*16

#pagebreak()

最终方案是修改 sail 编译器，自动生成验证代码

#image("image-11.png")

sail 的 constraint 语法可以为多个类型变量施加类型约束

// == 与 UDB 同步配置项

// TODO
