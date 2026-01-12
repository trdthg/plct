#import "@preview/grayness:0.1.0": grayscale-image
#import "@preview/touying:0.6.0": *
#import themes.metropolis: *
#import "@preview/chronos:0.2.1"

#import "@preview/numbly:0.1.0": numbly

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [ONNX 格式介绍],
    author: [Mingzhu Yan],
    date: datetime.today(),
  ),
)

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

= Outline <touying:hidden>

#outline(title: none, indent: 1em, depth: 1)

= Pytorch 手写数字识别

== 神经网络

#image("assets/image.png")

== 训练并保存快照

#image("assets/image-1.png")

== Pytorch 默认模型格式 .pth


#grid(
  columns: (1fr, 1fr),
  column-gutter: 1em,
  image("assets/image-2.png"),
  [

    model.pth

    - 是个压缩包, 里面是序列化后的 python 字典
    - 可以将其转换为 json 可读格式

  ],
)

== 使用 Pytorch 运行 .pth 模型

#image("assets/image-4.png")

- pth 不存储实际执行顺序
- pth 不存储每一个层该如何执行

想要执行, 必须使用 pytorch, 并构建相同的网络结构 (minst-demo/pytorch_run.py)

= 导出为 onnx 并使用 onnxruntime 运行

== 通用的模型格式

#grid(
  columns: (1fr, 1fr),
  column-gutter: 1em,
  [
    #grid(
      rows: (1fr, 1fr),
      row-gutter: 1em,
      [
        - ONNX 不依赖据具体的深度学习框架
        - 基于 protobuf, 支持多种编程语言
        - 存储执行顺序
        - 定义了算子集, 和算子的行为, 需要由具体的 runtime 实现

        任何实现了 ONNX 的运行时均可以运行 ONNX 模型

      ],
      [
        #image("assets/image-8.png"),
      ]
    )
  ],
  [
    #image("assets/image-7.png")],
)

== pth 转换为 onnx 并用 onnxruntime 运行

#image("assets/image-3.png")

= ONNX 格式

== protobuf 定义

ONNX 的格式使用 protobuf 定义

https://github.com/onnx/onnx/blob/main/onnx/onnx.proto

#image("assets/image-5.png")

= Python 手动构建 onnx 模型

== Python 手动构建 onnx 模型

#image("assets/image-6.png")

== onnx 对算子的描述

https://onnx.ai/onnx/operators/

#pagebreak()
