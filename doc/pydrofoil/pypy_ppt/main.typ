#import "@preview/touying:0.6.0": *
#import themes.metropolis: *

#import "@preview/numbly:0.1.0": numbly

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [Pydrofoil 分享],
    subtitle: [PyPy meta-tracing JIT],
    author: [Mingzhu Yan],
    date: datetime.today(),
    institution: [PLCT Lab],
  ),
)

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

= Outline <touying:hidden>

#outline(title: none, indent: 1em, depth: 1)

= 介绍

== Pydrofoil

#grid(
  rows: (1.8fr, 1fr),
  [
    #image("image-7.png")
  ],
  [
    #grid(
      columns: (1fr, 1fr),
      [
        #image("image-10.png")
      ],
      [
        #image("image-11.png")
      ],
    )
  ],
)

== Pydrofoil

#grid(
  rows: (1fr, 1fr),
  [
    #image("image-9.png")
  ],
  [
    #image("image-8.png")
  ],
)

== PyPy meta-tracing JIT

#grid(
  rows: (1fr, 2fr),
  [
    #image("image-14.png")
  ],
  [

    - *目标* 在 PyPy 项目（一种 Python 语言实现）中针对一些动态语言（包括 Python) 的解释器程序引入 JIT 编译技术

      > _从普通解释器生成自带 JIT 的解释器_

    - *要解决的问题* tracing JIT 可以加速热点代码，但是将 tracing JIT 直接应用于一个字节码解释器程序，会导致非常有限的加速甚至完全*没有加速*

    - *方法* 展开字节码调度循环引导 tracing JIT 编译器提高字节码解释器的速度

      > _需要编写一个解释器, 并且依赖作者的少量提示_

  ],
)

= PYPY 项目

== 背景

- 动态语言的发展迅速，使用广泛，但是常常 *性能较差*

  - JavaScript 正越来越多地被用于实现运行在浏览器中的全规模应用程序

  - 其他动态语言（如 Ruby、Perl、Python、PHP）则用于许多服务器领域，以及与网络无关的领域

- 对加速动态语言解释器性能的研究很多，但是 *加速技术的实际应用少*

  - 编译器固有的复杂性

  - 编写即时编译器困难

  - 动态语言的特性

- PyPy 项目在寻找一种*一般性的方法来简化动态语言的实现*

== PYPY 项目

#image("image-13.png")

#image("image-12.png")

== PYPY 项目

- PyPy 项目是一个可以编写动态语言灵活实现的环境。要使用 PyPy 实现动态语言，*必须用 RPython 编写该语言的解释器*

- RPython ("Restricted Python") 是 Python 的一个子集，特点是可以进行类型推断

  - 使用 RPython 编写的解释器可以借助 PyPy 的 translation toolchain 转换为各种目标环境，如 C/Posix、JVM 等

  - 通过用高级语言编写虚拟机，使语言的实现不受内存管理策略、线程模型或对象布局等低级细节的影响。这些特性在翻译过程中会自动添加

- 与常见的 JIT 不同，PyPy 的 tracing JIT *追踪的是解释器的执行*，而不是用户程序的执行

== RPython 翻译过程

- 首先进行控制流图构建和类型推断

- 然后经过一系列中间表示转换，最终得到可执行文件

  - 第一个转换步骤使 Python 对象模型的细节转换为中间表示

  - 后续步骤引入垃圾收集和其他低级细节

> 这种程序的内部表示也用作 tracing JIT 的输入

= TRACING JIT COMPILERS

== Tracing JIT 介绍

- tracing 优化技术最初是由 Dynamo 项目探索，目的是在运行时动态优化机器代码。其技术随后成功用于实现 Java 虚拟机的 JIT 编译器

- 随后发现，tracing JIT 是一种相对简单的方法，可以为动态语言实现 JIT 编译器

- 该技术也被 Mozilla 的 TraceMonkey JavaScript 虚拟机使用，并已尝试用于 Adobe 的 Tamarin ActionScript 虚拟机

== tracing JIT 特点

- tracing JIT 建立在以下基本假设之上：

  1. 程序运行的大部分时间都在循环中

  2. 同一个循环的多次迭代很可能会采取相似的代码路径

- tracing JIT 的基本方法：

  *只为循环中的热点路径生成机器码，剩下的部分解释执行*

  > 然而 *常见的循环已经经过了高度优化*，包括应用了激进的内联等

== 常规的 tracing JIT 流程

通常情况下带有 tracing JIT 的虚拟机在运行一个程序时会经过多个阶段

1. 解释执行/性能分析

  - 一开始解释执行，通过*轻量级的性能分析*统计出哪些循环执行的最频繁

  > 性能分析可以通过统计跳转指令（仅包括 backward jump）次数实现

2. 追踪热点代码

  - 当定位到热点代码后，解释器会进入 tracing mode，持续记录所有运行的指令，直到遇到热点循环

  - 被记录的信息称为 trace，它包含一系列的指令，以及实际的操作数和结果

  - 为了判断何时满足热点循环，tracing 会反复检查解释器是否处于程序中之前曾经到达过的位置
3. 代码生成和执行

== tracing JIT 示例

#grid(
  columns: (1fr, 1fr),
  // 创建两列，每列宽度为1fr（即等宽）
  column-gutter: 1em,
  // 设置列间距为1em
  [
    #image("image.png", width: 100%) // 插入图片，宽度设置为100%
  ],
  [
    #text(size: 1.2em)[
      - `strange_sum` 循环
      - `f` 分支
    ]
  ],
)

== trace 示例

首先是解释执行，当性能分析器发现 strange_sum 中的 while 循环被频繁执行时，tracing JIT 将开始追踪该循环的执行，形成 trace

#grid(
  columns: (1fr, 1fr),
  // 创建两列，每列宽度为1fr（即等宽）
  column-gutter: 1em,
  // 设置列间距为1em
  [
    #image("image.png") // 插入图片，宽度设置为100%
  ],
  [
    #image("image (1).png")
  ],
)



== 将 tracing JIT 应用于解释器

PyPy 的 traceing JIT 是不寻常的，因为它不是应用于用户程序，而是应用于运行用户程序的解释器

*术语*


- language interpreter（使用 RPython 编写的语言解释器）
- tracing interpreter（追踪语言解释器的解释器，PyPy 框架）
- user program （用户程序）
- user loops（用户程序中的循环）
- interpreter loops (语言解释器中的解释执行循环)

（假设语言是基于字节码的）

== tracing interpreter 示例

#grid(
  columns: (1fr, 1fr),
  // 创建两列，每列宽度为1fr（即等宽）
  column-gutter: 1em,
  // 设置列间距为1em
  [
    #image("image (2).png")
  ],
  [
    > 一个简单的字节码解释器（带有一些寄存器和一个 a）

    对于 tracing interpreter 来说，最常见的热点循环是 *bytecode dispatch loop*

    对一些简单的解释器来说， 这甚至可能是唯一的热点循环
  ],
)

== tracing interpreter trace 示例

#grid(
  rows: (8fr, 1fr),
  column-gutter: 1em,
  // 设置列间距为1em
  [
    #grid(
      columns: (3fr, 1fr, 3fr),
      // 创建两列，每列宽度为1fr（即等宽）
      column-gutter: 1em,
      // 设置列间距为1em
      [
        #image("image (2).png")
      ],
      [
        ```
        DECR_A
        DECR_A
        DECR_A
        DECR_A
        DECR_A
        ```

      ],
      [

        ```
        while true {
          a -= 1;
        }
        ```

        #image("image (4).png")
        Const(7) => DECR_A

        循环分支断言分支几乎每次都成功
      ],
    )
  ],
  [

  ],
)

== 字节码解释执行示例

#grid(
  rows: (8fr, 1fr),
  column-gutter: 1em,
  // 设置列间距为1em
  [
    #grid(
      columns: (1fr, 1fr, 1fr),
      // 创建两列，每列宽度为1fr（即等宽）
      column-gutter: 1em,
      // 设置列间距为1em
      [
        #image("image (2).png")
      ],
      [
        #image("image (3).png")

        计算 a 的平方
      ],
      [
        ```
        function (a) {
          i = a;
          while i != 0 {
            i -= 1;
            res += a;
          }
          return a;
        }
        ```
        #image("image (4).png")

        循环分支断言分支几乎每次都失败
      ],
    )
  ],
  [

  ],
)

== meta-tracing JIT 的优化

1. 同时追踪多个 opcode，高效地展开 dispatch loop （理想情况下，展开的大小应开等同于 user loop 的大小）

2. 当 PC 多次出现相同值，则意味着用户程序出现了循环，因为 JIT 无法知道哪些变量存储了 PC，所以用户需要标记这些变量

== 按照 PC 展开 user loop

#grid(
  columns: (1fr, 1fr, 1fr),
  // 创建两列，每列宽度为1fr（即等宽）
  column-gutter: 1em,
  // 设置列间距为1em
  [
    #image("image-4.png")
  ],
  [
    #image("image-3.png")
  ],
  [
    不再按照 opcode 分支判断热点，而是按照 PC 的变化追踪整个循环运行的所有字节码
  ],
)

== 标记 PC

#grid(
  columns: (1fr, 1fr),
  // 创建两列，每列宽度为1fr（即等宽）
  column-gutter: 1em,
  // 设置列间距为1em
  [
    #image("image-2.png")
  ],
  [
    对变量的分类
    - greens 为 PC 相关的值
    - reds 为其他

    方法
    - jit_merge_point 在循环的开头调用
    - can_enter_jit 需要在 PC 修改为更早的值之前调用

      - 这里决定是否要展开 profiling
      - 当 PC 与之前调用 can_enter_jit() 时的 PC 相同时，则意味着循环闭合
  ],
)

== 对结果的优化

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1em,
  [
    #image("image-5.png")
  ],
  [
    - 引入常量折叠，PC 和 opcode 等绿色变量通常可以折叠
    - RPython 中的字符串类型时不变量，也可以折叠
  ],
)


= IMPLEMENTATION ISSUES

== 实现遇到的问题

- 如果真的解释执行 RPython 编写的语言解释器，这种双重解释的开销将无比巨大，所以 RPython 被编译为 C 运行

- 为了识别循环，并接入 JIT，最终的可执行文件嵌入了两个版本的语言解释器

  - 一个是机器代码版本，用于首次解释执行用户程序，进行性能分析，没有性能优化

  - 另一个是字节码版本，启动 trace 模式后，Tracing 解释器为了记录下完整的操作流，而不得不去“解释执行”整个语言解释器
  所以 tracing 本身是昂贵的，它会产生双重解释的开销

- 条件守卫失败的回退可能是一个复杂的过程，如果失败的函数堆栈很深，重建语言解释器，恢复状态，并从该点重新执行很困难

= 评估

== 示例程序计算 10000000 的平方

#image("image-6.png")

== 简单 python 程序对比 CPython

#image("image (5).png")

= 相关工作

== 相关工作

- DynamoRIO 实现了同样的解释器循环展开, 但是它的 tracing 是基于汇编的, 因此受到了诸多限制
  - 无法获得解释器的高级信息
  - 需要更多的提示信息, 汇编层级无法辨别字符串等信息
  - 无法实现分配移除等高级优化

- 将解释器片段组合在一起, 将热点机器代码序列拼接在一起, 可以大大减轻调度开销 (这里 PyPy 通过内联 + 常量折叠已经大幅优化了调度开销)

- dynamic partial evaluation

= 总结

== 总结

优化结果在小型解释器上的效果很好

下一步工作

- 通过逃逸分析移除堆分配
- 优化 Frame Objects
