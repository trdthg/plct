#import "@preview/grayness:0.1.0": grayscale-image
#import "@preview/touying:0.6.0": *
#import themes.metropolis: *
#import "@preview/chronos:0.2.1"
#import "@preview/pinit:0.2.2": *

#import "@preview/numbly:0.1.0": numbly
#import "@preview/zh-kit:0.1.0": *

#show: doc => setup-base-fonts(
  doc,
  cjk-serif-family: ("LXGW WenKai", "霞鹜文楷", "宋体"), // 优先使用霞鹜文楷 SC
  cjk-sans-family: ("LXGW WenKai", "霞鹜文楷", "宋体"),
  first-line-indent: 0em, // 设置首行缩进为2个字符宽度
)
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [RISC-V 模拟器运行用户程序的几种方法],
    subtitle: [],
    author: [Mingzhu Yan],
    date: datetime.today(),
  ),
  config-common(
    new-section-slide-fn: none,
  ),
)

// Useful functions
#let crimson = rgb("#c00000")
#let greybox(..args, body) = rect(fill: luma(95%), stroke: 0.5pt, inset: 0pt, outset: 10pt, ..args, body)
#let redbold(body) = {
  set text(fill: crimson, weight: "bold")
  body
}
#let blueit(body) = {
  set text(fill: blue)
  body
}

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show heading: set text(weight: "regular")
#show heading: set block(above: 1.4em, below: 1em)
#show heading.where(level: 1): set text(size: 1.5em)

#set heading(offset: 0)
// #set text(size: 20pt, font: "", ligatures: false)

#title-slide()
// #import "@preview/typst-font-table:0.1.0"
// #show: font-table.with()
= Outline <touying:hidden>

#outline(title: none, indent: 1em, depth: 1)

= 运行用户程序

在 X86 架构的 linux 或者 bsd 上直接运行一个 RISC-V 架构的使用了 printf 的可执行文件


- 系统调用
- HTIF 协议
- Semihosting

= 系统调用

== qemu user

#grid(
  columns: (1fr, 1fr),
  [
    #grid(
      rows: (1fr, 3fr),
      [
        qemu-user 可以轻松在 x86-64 系统上运行一个其他架构的用户程序
      ],
      [
        #image("/assets/image.png")
      ],
    )
  ],
  [

    #image("assets/image-22.png")

    #image("assets/image-21.png")
  ],
)


= 基于 HTIF 协议

== HTIF 协议


#grid(
  rows: (1fr, 2fr),
  [
    https://github.com/Timmmm/htif_spec/releases/download/v0.0.1/htif-0.0.1.pdf

    - HTIF consists of two separate 8-byte MMIO devices: tohost and fromhost.
  ],
  [
    #image("assets/image-3.png")
  ],
)


== tohost

#grid(
  rows: (1fr, 1fr, 1fr),
  [
    Devices

    - 0 Syscalls
    - 1 Console
  ],
  [
    #image("assets/image-4.png")
  ],
)


#grid(
  columns: (1fr, 1fr),
  [
    #image("assets/image-5.png")
  ],
  [
    #image("assets/image-6.png")
  ],
)

#image("assets/image-7.png")

== spike 运行用户程序

#grid(
  columns: (1fr, 1fr),
  [
    Spike 也实现了基于 HTIF 的系统调用

    #image("assets/image-11.png")

    一般使用 spike 运行用户程序需要配合 riscv-pk (代理内核), riscv-pk 实现了基本的 trap_handler, 可以将标准的 linux 系统调用转换为 htif 格式的 syscall

    spike riscv-pk hello.elf
  ],
  [
    #image("assets/image-8.png")
  ],
)

== pk 到 spike

#grid(
  rows: (1fr, 4fr),
  [
    riscv-pk 会使用 htif 协议实现的 syscall 实现真实的系统调用
  ],
  [
    #grid(
      columns: (1fr, 1fr),
      [
        #image("assets/image-9.png")
      ],
      [
        #image("assets/image-10.png")
      ],
    )
  ],
)


== nanoprint


#grid(
  rows: (1fr, 4fr),
  [
    https://github.com/charlesnicholson/nanoprintf
  ],
  [
    #image("assets/image-2.png")
  ],
)

== sail-model 使用 nanoprint

#image("assets/image-1.png")

== 基于 htif 的缺点

- 系统调用数量众多
- 难以同时兼顾不同的操作系统

- FreeBSD System Calls Table https://alfonsosiciliano.gitlab.io/posts/2021-01-02-freebsd-system-calls-table.html

- Linux kernel syscall tables https://syscalls.mebeim.net/?table=riscv/64/rv64/latest

== FreeBSD System Calls Table

#image("assets/image-12.png")

== Linux kernel syscall tables

#image("assets/image-13.png")

= 基于 Semihosting Extension

仅仅支持部分常见的系统调用

- Spec https://github.com/riscv-non-isa/riscv-semihosting
- Gem5 实现 https://github.com/gem5/gem5/blob/stable/src/arch/generic/semihosting.cc
- QEMU 实现 https://github.com/qemu/qemu/blob/master/semihosting/syscalls.c#L153

必须链接到 picolibc https://github.com/picolibc/picolibc


== Semihosting

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1em,
  [
    - HTIF 提供了两个 MMIO 设备
    - Semihosting 则是特殊的指令序列

    #image("assets/image-19.png")

    #image("assets/image-15.png")
    #image("assets/image-20.png")
  ],
  [
    #image("assets/image-14.png")
  ],
)


== Semihosting

#grid(
  columns: (1fr, 2fr),
  [
    #image("assets/image-16.png")
  ],
  [
    #image("assets/image-17.png")
  ],
)


```
riscv64-unknown-elf-gcc --specs=/path/to/picolibc.specs --oslib=semihost hello.c
```

= 总结

1. 系统调用翻译
2. HTIF 协议
3. Semihosting

完整的用户空间仿真需要

1. System call translation
2. POSIX signal handling
3. Threading

- https://www.qemu.org/docs/master/user/main.html
