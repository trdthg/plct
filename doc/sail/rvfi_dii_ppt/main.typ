#import "@preview/grayness:0.1.0": grayscale-image
#import "@preview/touying:0.6.0": *
#import themes.metropolis: *
#import "@preview/chronos:0.2.1"

#import "@preview/numbly:0.1.0": numbly

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [RISC-V RVFI-DII 验证协议介绍],
    subtitle: [RISC-V 常见验证协议，框架介绍],
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

== SAIL MODEL 需要一个更好的 trace/log 输出格式

#image("image.png", height: 90%)

#link("https://github.com/riscv/sail-riscv/issues/545")

== SAIL 目前基于纯文本的日志格式

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1em,
  [
    - SAIL 在运行时使用纯文本打印 trace/log 信息到 stdout
    - 日志主要包括三种类型
      - 寄存器读写
      - 内存读写
      - 正在运行的指令
  ],
  image("image-1.png"),
)

== SAIL Trace 实现方法

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1em,
  grid(
    rows: (0.5fr, 1fr, 1fr),
    row-gutter: 0.5em,
    text("SAIL MODEL 的实现预留了回调接口供用户实现自定义操作, 目前主要用于打印 TRACE"),
    image("image-2.png"),
    image("image-4.png"),
  ),
  image("image-5.png"),
)

== SAIL 缺点

1. 基于文本的日志可能会变得非常大（而二进制格式体积上会小得多）

2. 下游工具(verification, trace-driven simulation)必须编写专门的 parser 处理 SAIL 日志

#image("image-7.png")

3. 日志格式不够稳定, 目前会按需随时更新, 容易出现 break change, 导致下游工具出现 bug (ACT 多次由于 SAIL 日志格式更新出现 bug)

*SAIL 需要一个更好的 trace/log 格式* 用于形式化验证

= RISC-V 现有 Trace 格式浅析

== 六种 Trace 格式

1. RVI E-Trace ("Efficient Trace") From RVI; ratified

  https://github.com/riscv-non-isa/riscv-trace-spec

2. RVI N-Trace ("Nexus Trace") From RVI; ratified

  https://github.com/riscv/tg-nexus-trace

3. RVFI ("RISC-V Formal Verification Interface") From SymbioticEDA

  https://github.com/SymbioticEDA/riscv-formal

4. RVVI ("RISC-V Verification Interface") From Imperas originally (now part of Synopsys), but now public.

  https://github.com/riscv-verification/RVVI

#pagebreak()

5. "Trace Protocol" From Bluespec, Inc. (but ready to contribute this spec to RVI as an open spec)

  https://github.com/user-attachments/files/16931294/2020-03-10_trace-protocol.pdf

6. RVFI-DII ("Risc-V Formal Interface - Direct Instruction Injection") From CTSRD-CHERI

  https://github.com/CTSRD-CHERI/TestRIG

== E-Trace

1. RVI E-Trace ("Efficient Trace") From RVI; ratified

  https://github.com/riscv-non-isa/riscv-trace-spec

  - 重点在于实现高效/高压缩比的控制流追踪
  - 依赖于解码器能够访问原始的 ELF 文件 (用于映射到源代码, 或者分析未追踪的指令序列)
  - 不适合自修改代码/JIT, 因为没有 ELF 文件
  - 不捕获架构状态更新(GPRs, FPRs, CSRs) E-Trace 有一个捕获内存更新的部分

== N-Trace

2. RVI N-Trace ("Nexus Trace") From RVI; ratified

  https://github.com/riscv/tg-nexus-trace

  - IEEE-5001(Nexus) 标准是针对嵌入式处理器开发的一种调试和跟踪标准，它基于JTAG协议，并扩展了JTAG的功能，以支持对嵌入式系统的调试

  类似于 E-Trace，但是主要用于调试

== RVFI / RVFI-DII / RVVI

3. RVFI ("RISC-V Formal Verification Interface") From SymbioticEDA

  - 以每周期指令退休（instruction retirement per cycle）为粒度，输出处理器在每个周期所退休指令的完整状态信息。

6. RVFI-DII ("Risc-V Formal Interface - Direct Instruction Injection") From CTSRD-CHERI

  - 基于 RVFI, 扩展了一个 instruction trace format, 规范化了 execution trace 的数据包格式

4. RVVI ("RISC-V Verification Interface") Used by OpenHWGroup.

  - RVFI 的超集
  - 记录的数据太多, 例如包含了所有的 GPR, FPR, CSR

== Bluespec Trace Protocol


5. "Trace Protocol" From Bluespec, Inc. (but ready to contribute this spec to RVI as an open spec)

  - 二进制格式

  - 字段是可选的，因此可以支持从最小跟踪到详细跟踪

  - 可以捕获所有标准架构状态更新（尚未包含向量）

  - 可以捕获陷阱/终端

  - 可以捕获额外的中间状态

  - 已经应用在 Bluespec 内部多个硬件设计和模拟器实现中

= RVFI-DII 协议介绍及 Sail 实现分析

== RVFI-DII 数据包格式

https://github.com/CTSRD-CHERI/TestRIG/blob/master/RVFI-DII.md

RVFI-DII 由两个数据包结构组成，旨在通过套接字发送。

- 从 vengine 发送到实现的指令跟踪格式 *instruction trace*
- 从实现返回给 vengine 的执行跟踪格式 *execution trace*
  - execution trace 有 V1, V2 两个版本

== TestRIG 随机指令生成的 RISC-V 处理器测试框架

#align(center, image("diagram.svg"))

#pagebreak()

1. 被测设备需要通过 socket 和 VEngine 进行通信
2. fetch 取值从 VEngine 发送的数据包解析获得

== Instruction Packet

#image("image-8.png")

== Execution Packet V1

#image("image-9.png")

== Execution Packet V2

#image("image-10.png")

// 为了压缩数据包大小, 进行了更细粒度的拆分, 将一些字段设置为可选.

== Sail RISC-V 模型实现

1. Fetch from RVFI Instruction Packet

#image("image-11.png", height: 25%)

#pagebreak()

2. Update packet if necessary

#image("image-12.png")

#pagebreak()

3. Return Execution Packet

#image("image-13.png")

= RISC-V 部分验证方案总结

== 测试方法

1. 差分测试
2. 自测

== trace-based

#speaker-note[
  + 都遵循类似的方法, 一个数据源, 被测设备和标准设备同时运行相同的指令, 验证引擎对每一步的执行结果进行比对
]

#slide[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    [

      通过测试执行器，控制待测设备和标准设备单步执行指令，并对比执行后的状态是否保持一致

      - RVFI / RVVI / RVFI-DII / Bluespec

      - Xiangshan difftest

      对实现 (DUT) 的要求

      - 以某种方式支持单步运行
      - 提供适当的接口获取信息
    ],
    [
      #alternatives[
        #image("diagram.svg")
        RVFI-DII
      ][
        #image("image-16.png")
        RVVI
      ][
        #image("image-14.png")
      ]
    ],
  )
]

== result-based

#speaker-note[
  + 自测可以从 trace-based 转换而来
  + You won't see it unless you use `config-common(show-notes-on-second-screen: right)`
]

#grid(
  columns: (0.4fr, 1fr),
  column-gutter: 1em,
  [
    待测设备自行运行 ELF 文件

    - riscv-tests/riscv-vector-tests

  ],
  [
    #image("image-21.png")
  ],
)

== mixed

#grid(
  columns: (0.4fr, 1fr),
  column-gutter: 1em,
  [
    既可以差分测试，也可以自测

    - riscv-arch-tests
    - cvw-arch-verif

  ],
  [
    #alternatives[
      #image("image-20.png")
    ][
      #image("image-22.png")
    ][
      #image("image-15.png")
    ]
  ],
)

= 总结

== 总结

1. 用户对验证中产生的 trace/log 的要求
  - 体积小，压缩率高
  - 捕获足够多的状态，包括陷阱中断，隐式修改等
  - 需要有稳定的接口，避免工具需要频繁变更

2. 各个 RISC-V 开源实现 / 厂商私有实现都需要进行处理器形式化验证，验证方法没有统一标准，协议多样
  - E-Trace/N-Trace
  - RVFI/RVVI/RVFI-DII/Bluespec

#pagebreak()

3. 常见的验证方法包括两类，差分测试或者自测
  - 前者依赖于被侧设备和标准设备需要提供 访问处理器状态 和控制处理器执行 的相关接口
  - 自测测试集一般难以满足复杂场景的测试要求
  - riscv-tests/riscv-vector-tests
  - riscv-arch-tests/cvw-arch-verif

4. Sail 作为 RVI 推动的 Golden Model，目前可以通过日志输出用于 ACT 测试。同时也支持使用 RVFI-DII 协议进行差分测试

5. Sail 目前没有实现单步执行，提供友好的接口，无法方便的集成到广泛的测试框架中

#focus-slide[
  #pad(
    grid(
      columns: (1fr, 1fr),
      column-gutter: 1em,
      [
        THANKS!
      ],
      [
        #image("QRcode_c2-1.jpg", width: 50%)
        #text("欢迎加入 PLCT BJ88(SAIL) P121(ACT) J160(Pydrofoil) 岗位实习", size: 0.5em)
      ],
    ),
    left: 3em,
    right: 3em,
  )
]
