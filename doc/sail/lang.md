# Sail

## 1 语言简介

Sail 是一种用于描述处理器的指令集架构 (ISA) 语义的语言。

- Sail 旨在提供一种工程师友好、类似供应商伪代码的语言来描述指令语义。
- 它本质上是一种一阶命令式语言，但对数值类型和位向量长度具有轻量级依赖类型，这些类型和位向量长度使用 Z3 自动检查。

资源：

- [手册 (pdf)](https://github.com/rems-project/sail/blob/sail2/manual.pdf)
- [手册的 tex 格式源代码 + 示例代码](https://github.com/rems-project/sail/tree/sail2/doc)

### 为什么用 sail

供应商通常使用 白话文、表格和伪代码 来描述其 ISA 的行为。

但是不同供应商的伪代码在精确程度上各不相同：

- 对于 x86，Intel 伪代码只是暗示性的，嵌入了一些白话文。而 AMD 的只是白话文。
- 对于 IBM Power，有详细的伪代码，最近变成机器处理的。
- 对于 ARM，有详细的伪代码，最近变成了机器处理的。
- 对于 MIPS，有相当详细的伪代码。

sail 要实现的目标

- 支持对真实世界 ISA 语义的精确定义
- 容易，对熟悉现有供应商伪代码的人可以轻松掌握，Sail 的风格与 ARM 和 IBM Power 使用的伪代码相似 (语法差异很小);
- 提供将顺序 ISA 语义 (sequential ISA semantics) 与已开发的松弛内存并发模型 (elaxed-memory
concurrency models) 相结合所必需的结构
- 提供一个富有表现力的类型系统，可以静态检查这些规范中出现的位向量长度和索引，检测错误并支持代码生成，具有类型推断功能，最大程度地减少所需的类型注释
- 支持运行，对架构进行自动化完整仿真
- 支持自动生成 定理证明器定义，用于对 ISA 规范进行机械化推理
- 尽可能减少代码生成和理论定义生成

### Sail spec

> TODO: 这是规范是什么？干什么用的？

Sail spec 通常会定义：

- 机器指令的抽象语法类型 (AST)
- 将二进制值转换为 AST 值的解码函数
- 描述每个指令在运行时的行为方式的执行函数
- 所需的任何辅助函数和类型

给定这样的规范后，Sail 实现可以对其进行类型检查并生成：

- 完全类型注释的定义 (定义的深度嵌入) 的内部表示形式，可由 Sail 解释器执行。这些都用 Lem(一种类型、函数和关系定义的语言，可以编译成 OCaml 和各种定理证明器) 表示。Sail 解释器还可用于分析指令定义 (或部分执行的指令)，以确定其潜在的寄存器和内存占用。

- 定义的浅层嵌入 (也在 Lem 中)，可以更直接地执行或转换为定理代码。目前，这是针对 Isabelle/HOL 或 HOL4 的，尽管 Sail 依赖类型应该支持生成惯用的 Coq 定义 (直接而不是通过 Lem)。
- 直接将规范的编译版本编译到 OCaml 中。
- 规范的高效可执行版本，编译成 C 代码。

### 不足

Sail 目前不支持指令的汇编语法描述，也不支持指令与指令 AST 或二进制描述之间的映射，尽管这是我们计划添加的内容。

## 2 快速入门

我们通过 RISC-V 模型中的一个小例子来介绍 Sail 的基本功能，该模型仅包含两个指令：`add immediately` 和 `load double`。

> TODO: 添加对顺序的简单解释
> 这里定义了默认顺序，并且引入了 Sail prelude.

```ocaml
default Order dec
$include <prelude.sail>
```

Sail 的 prelude 非常少，Sail 规范通常会建立在它的基础上。一些 Sail 规范源自预先存在的伪代码，这些伪代码已经使用了特定的习惯用语——我们的 Sail ARM 规范使用 ZeroExtend 和 SignExtend 镜像一份 ASL 代码，而我们的 MIPS 和 RISC-V 规范使用 EXTZ 和 EXTS 来实现相同的功能。因此，在此示例中，我们将零扩展 (ZeroExtend) 和符号扩展 (SignExtend) 函数定义为：

> TODO: 解释这两个拓展，解释这里的语法，是什么语言

```ocaml
val EXTZ : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)

function EXTZ(m, v) = sail zero extend(v, m)

val EXTS : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)

function EXTS(m, v) = sail sign extend(v, m)
```

现在，我们定义一个整数类型同义词 xlen，在本例中，该同义词将等于 64。Sail 支持对常规类型和整数 (类比 C++ 中的常量泛型，但这里更具表现力) 的定义。我们还为长度为 xlen 的位向量 (bit vector) 创建类型 xlenbits。

> TODO: 解释语法

```ocaml
type xlen : Int = 64

type xlen_bytes : Int = 8

type xlenbits = bits(xlen)
```

在此示例中，我们还为长度为 5 的位向量引入了一个类型同义词，它表示寄存器。

```ocaml
type regbits = bits(5)
```

现在，我们设置一些基本的架构状态：

```ocaml
(* 首先为程序计数器 PC 和下一个程序计数器 nextPC 创建一个 xlenbit 类型的寄存器。 *)
register PC : xlenbits
register nextPC : xlenbits

(* 我们将通用寄存器定义为 32 个 xlenbits 位向量的向量。 *)
(* 在此示例中，dec 关键字并不重要，但 Sail 支持两种不同的(bit)vectors *)
(* - inc 最高有效位为零 *)
(* - dec 最低有效位为为零。 *)
register Xs : vector(32, dec, xlenbits)


(* 然后，我们为寄存器定义一个 getter 和 setter，确保对零寄存器进行特殊处理 *)
(* (在 RISC-V 中，寄存器 0 始终硬编码为 0) *)
val rX : regbits -> xlenbits

function rX(r) =
    match r {
        0b00000 => EXTZ(0x0),
        _ => Xs[unsigned(r)]
    }

val wX : (regbits, xlenbits) -> unit

function wX(r, v) =
    if r != 0b00000 then {
        Xs[unsigned(r)] = v;
    }

(* 最后，我们将读取(rX)和写入(wX)函数都重载为简单的 X。 *)
(* 这允许我们将寄存器写入为 X(r)= value，并将寄存器读取为 value = X(r) *)
(* Sail 支持灵活的临时重载 (ad-hoc overloading)，是表达式第一公民的语言，目的是允许类似伪代码的定义。 *)
overload X = {rX, wX}
```

> TODO: 啥内置函数？
我们还给出了一个用于读取内存的函数 MEMr，这个函数只指向我们在其他地方定义的内置函数。

```ocaml
val MEMr = monadic {lem: "MEMr", coq: "MEMr", _: "read_ram"}: forall 'n 'm, 'n >= 0.
(int('m), int('n), bits('m), bits('m)) -> bits(8 * 'n)
```

在定义架构规范时，将指令语义分解为多个单独的函数 (解码 (甚至可能在多个阶段) 为自定义的中间数据类型并执行解码指令) 很常见，

但是，通常希望将这些函数和数据类型的各个相关部分组合在一起，因为它们通常可以在 ISA 参考手册中找到。为了支持这一点，Sail 支持分散的定义。

首先，我们给出 execute 和 decode 函数的类型，以及 ast union:

> TODO: scattered union ast 是什么东西

```ocaml
enum iop = {RISCV_ADDI, RISCV_SLTI, RISCV_SLTIU, RISCV_XORI, RISCV_ORI, RISCV_ANDI}

scattered union ast

val decode : bits(32) -> option(ast)

val execute : ast -> unit
```

现在，我们提供了 `add-immediate` 的 ast 类型子句，以及它的 `execute` 和 `decode` 子句。

解码函数的定义：直接对表示指令的位向量进行模式匹配

Sail 支持向量串联模式 (vector concatenation patterns)(@ 是向量串联运算符)，并使用已提供的类型 (例如 bits 和 regbits) 以正确的方式解构向量。

我们使用 `EXTS` 函数来对其参数进行符号扩展。

> TODO: 代码看不懂

```ocaml
union clause ast = ITYPE : (bits(12), regbits, regbits, iop)

function clause decode imm : bits(12) @ rs1 : regbits @ 0b000 @ rd : regbits @ 0b0010011
    = Some(ITYPE(imm, rs1, rd, RISCV_ADDI))

function clause execute (ITYPE (imm, rs1, rd, RISCV_ADDI)) =
    let rs1_val = X(rs1) in
    let imm_ext : xlenbits = EXTS(imm) in
    let result = rs1_val + imm_ext in
    X(rd) = result
```

接着是对 `load-double` 指令做同样的事情：

```ocaml
union clause ast = LOAD : (bits(12), regbits, regbits)

function clause decode imm : bits(12) @ rs1 : regbits @ 0b011 @ rd : regbits @ 0b0000011
    = Some(LOAD(imm, rs1, rd))

function clause execute(LOAD(imm, rs1, rd)) =
    let addr : xlenbits = X(rs1) + EXTS(imm) in
    let result : xlenbits = read mem(addr, sizeof(xlen_bytes)) in
    X(rd) = result
```

最后，我们定义解码函数的回退情况。请注意，分散函数中的子句将按照它们在文件中出现的顺序进行匹配。

## 3 使用 Sail

## 4 语法

### 4.1 函数

在 Sail 中，函数分为两部分

- 先使用 val 关键字编写函数的类型签名
- 然后使用 function 关键字定义函数的主体

在本小节中，我们手动实现 sail 标准库提供的 `replicate_bits` 函数。

参数：number, bitvector
功能：复制 bitvector n 次

```ocaml
val my_replicate_bits : forall 'n 'm, ('m >= 1 & 'n >= 1). (int('n), bits('m)) -> bits('n * 'm)
```

Sail 中函数类型的一般语法如下：
    `val name : forall type variables , constraint . ( type1 , . . . , type2 ) -> return type`

`replicate_bits` 函数的实现如下：

```ocaml
function my_replicate_bits(n, xs) = {
    ys = zeros(n * length(xs));
    foreach (i from 1 to n) {
        ys = ys << length(xs);
        ys = ys | zero_extend(xs, length(ys))
    };
    ys
}
```

函数声明的一般语法为：
    `function name ( argument1 , . . . , argumentn ) = expression`

> 此示例的代码在 Sail Repo 的 `doc/examples/my_replicate_bits.sail`。

如果想要测试，你可以使用 `-i` 选项以交互方式调用 Sail，在命令行上传递上述文件。输入 `my_replicate_bits(3, 0xA)` 将逐步执行上述函数，并最终返回结果 `0xAAA`. 在交互式解释器中输入 `:run` 将导致对表达式进行完全计算，而不是单步执行。

Sail 允许在表达式中直接使用类型变量，因此上面的内容可以重写为

```ocaml
function my_replicate_bits_2(n, xs) = {
    ys = zeros('n * 'm);
    foreach (i from 1 to n) {
        ys = (ys << 'm) | zero_extend(xs, 'n * 'm)
    };
    ys
}
```

> 这种写法简洁明了，但应谨慎使用。发生的情况是，Sail 将尝试使用周围范围内可用的适当大小的表达式 (在本例中为 n 和 length(xs)) 来重写类型变量。如果没有找到合适的表达式来轻易重写这些类型变量，则将自动添加其他函数参数以在运行时传递此信息。

函数也可以有隐式参数，例如，下面我们实现了一个零扩展函数，该函数可以从调用上下文中隐式获取其结果 bits 的长度：

```ocaml
val extz : forall 'n 'm, 'm >= 'n. (implicit('m), bits('n)) -> bits('m)

function extz(m, xs) = zero_extend(xs, m)
```

隐式参数始终是整数，并且它们必须首先出现在函数类型签名中的任何其他参数之前。

### 4.2 Map

Map 是 Sail 的一项功能，它允许简洁地表达 ISA 规范中常见的值之间的双向关系：例如，枚举类型的位表示形式或指令 AST 的汇编语言字符串表示形式。

它们的定义与函数类似，具有 val-spec 和 definition。目前，它们仅适用于单态类型。

`val name : type1 <-> type2`
`mapping name = { pattern <-> pattern , pattern <-> pattern , . . . }`

简写：`mapping name : type1 <-> type2 = { pattern <-> pattern , pattern <-> pattern , . . . }`

来自 RISC-V model 的一个例子：

```ocaml
mapping size_bits : word_width <-> bits(2) = {
    BYTE <-> 0b00,
    HALF <-> 0b01,
    WORD <-> 0b10,
    DOUBLE <-> 0b11
}
```

只需像调用函数一样调用映射即可使用映射：类型推断将确定映射的运行方向。(这导致了映射两侧的类型必须不同的限制)。

```ocaml
let width : word_width = size_bits(0b00);
let width : bits(2) = size_bits(BYTE);
```

映射是通过在编译时将它们转换为前向和后向函数以及一些辅助函数来实现的。

使用 val-spec 声明映射后，可以通过手动定义这些函数来实现它，而不是如上所述定义映射。这些函数及其类型包括：

```ocaml
val name_forwards : type_1 -> type_2
val name_backwards : type_2 -> type_1
val name_forwards_matches : type_1 -> bool
val name_backwards_matches : type_2 -> bool
```

### 4.3 数值类型

Sail 有三种基本数值类型：int, nat 和 range。

- int 是任意精度的数学整数
- nat 是任意精度的自然数
- range('n, 'm) 是介于 In-kinded 类型变量 'n 和 'm 之间的非独占范围。

int('o) 类型是一个整数，正好等于 int-kinded 类型变量 'n，即 int('o) = range('o，'o)。

如果满足下图中总结的规则 (通过约束求解)，这些类型可以互换使用。

![numberic_type](./assets/numberic_type.png)

请注意，bit 不是数值类型 (即它不是 range(0, 1)。这是有意为之的，否则可以编写像 `(1: bit) + 5` 这样的表达式，最终等于 `6: range(5, 6)`。这种从位到其他数值类型的隐式转换是非常不可取的。位类型本身是具有成员 bitzero 和 bitone 的双元素类型。

### 4.4 向量类型

Sail 具有内置类型向量，它是固定长度向量的多态类型。例如，我们可以定义一个由三个整数组成的向量 v，如下所示：

```ocaml
let v : vector(3, dec, int) = [1, 2, 3]
```

vector 类型的第一个参数是表示向量长度的数值表达式，最后一个参数是向量元素的类型。但第二个参数是什么？Sail 允许两种不同类型的向量排序 - 增加 (inc) 和减少 (dec)。下面显示了位向量 `0b10110000` 的这两个排序。

![vector_order.png](./assets/vector_order.png)

对于递增 (位) 向量，索引为 0 处是最有效位，索引向最低有效位增加。而对于递减 (位) 向量，最低有效位的索引为 0，索引从最高有效位减少到最低有效位。因此，增加索引有时称为 "最高有效位为零" 或 MSB0，而减少索引有时称为 "最低有效位为零" 或 LSB0。虽然这种向量排序对位向量最有意义 (通常称为位排序)，但在 Sail 中，它适用于所有向量。可以使用以下命令设置默认顺序

```ocaml
default Order dec
```

这通常应该在规范的开头完成。大多数架构都坚持约定或约定，但 Sail 也允许在向量顺序上多态的函数，如下所示：

```ocaml
val foo : forall ('a : Order). vector(8, 'a, bit) -> vector(8, 'a, bit)
```

**Bitvector Literals** Sail 中的位向量字面量写为 `0xhex string` 或 `0bbinary string`，例如 0x12FE 或 0b1010100。十六进制文字的长度始终是位数的四倍，二进制字符串的长度始终是确切的位数，因此 0x12FE 的长度为 16，而 0b1010100 的长度为 7。

**访问和更新向量** 可以使用 `vector[index]` 对向量进行索引：

```ocaml
let v : vector(4, dec, int) = [1, 2, 3, 4]
let a = v[0]
let b = v[3]
```

上面例子中 A = 4，B = 1(注意，v 是 dec)。默认情况下，Sail 将静态检查越界，如果无法证明所有此类向量访问都有效，则会引发类型错误。

**切片** 可以使用 `vector[index_msb .. index_lsb]` 表示法对向量进行切片。索引总是首先给出最接近 MSB 的索引，因此我们将递减位向量 v 的低 32 位视为 `v[31 .. 0]`，将递增位向量的高 32 位视为 `v[0 .. 31]`，即递减向量的索引顺序减少，而递增向量的索引顺序增加。

**更新向量索引** 可以使用 `[vector with index = expression]` 表示法更新向量索引。类似地，可以使用 `[vector with index_msb .. index_lsb = expression]` 更新向量的子范围，其中索引的顺序与上面描述的增加和减少向量的顺序相同。

这些表达式实际上只是几个内置函数的语法糖，即 `vector_access`、`→` 、`vector_subrange`、`vector_update` 和 `vector_update_subrange`。

### 4.5 List 类型

除了向量之外，Sail 还具有 list 作为内置类型。例如：

```ocaml
let l : list(int) = [|1, 2, 3|]
```

构造运算符是 `::`，所以上面等价于：

```ocaml
let l : list(int) = 1 :: 2 :: 3 :: [||]
```

模式匹配可用于解构列表，参见第 4.7 节。

### 4.6 其他类型

Sail 也有一个 string 和 real 类型。实数类型用于对任意实数进行建模，因此可以通过将浮点输入映射到实数，对实数执行算术运算，然后映射回适当精度的浮点值来指定浮点指令。

### 4.7 模式匹配

与大多数函数式语言一样，Sail 支持通过 match 关键字进行模式匹配。例如：

```ocaml
let n : int = f();
match n {
    1 => print("1"),
    2 => print("2"),
    3 => print("3"),
    _ => print("wildcard")
}
```

match 关键字接受一个表达式，然后根据表达式的值进行分支。每个情况都采用 `pattern => expression` 的形式，用逗号分隔。从上到下依次检查，当第一个模式匹配时，计算其表达式。

> Sail 中的 match 目前没有检查其 exhaustiveness (穷尽，彻底) —— 毕竟我们可以对要匹配的数值变量设置任意的约束，这会导致我们无法仅通过简单的语法检查确定约束限制的可能。尽管如此，sail 有一个简单的穷举性检查器，如果它无法判断模式匹配是 exhaustiveness 的，它会发出警告 (而不是错误)，但这个检查可能会给出误报。可以使用 `-no_warn` 标志将其关闭。

在上面 `print("1")` 的情况下，n 将具有 `int('e)` 类型，其中 `'e` 是某个新的类型变量，并且存在 `'e` 等于 1 的约束。

我们还可以在模式上设置保护：

```ocaml
let n : int = f();
match n {
    1 => print("1"),
    2 => print("2"),
    3 => print("3"),
    m if m <= 10 => print("n␣is␣less␣than␣or␣equal␣to␣10"),
    _ => print("wildcard")
}
```

变量模式 m 可以与任何内容匹配

#### 对枚举进行匹配

Match 可用于匹配枚举的可能值，如下所示：

```rust
enum E = A | B | C
match x {
    A => print("A"),
    B => print("B"),
    C => print("C")
}
```

请注意，由于 Sail 对枚举元素的词法结构没有限制，无法将其与普通标识符区分开来，因此变量和枚举元素的模式匹配可能有些不明确。

#### 对元组匹配

我们使用 match 来解构元组类型，例如：

```ocaml
let x : (int, int) = (2, 3) in
match x {
    (y, z) => print("y = 2 and z = 3")
}
```

#### 对 Union 匹配

Match 也可用于解构联合体构造函数，例如使用第 4.10.3 节中的选项类型：

```ocaml
match option {
    Some(x) => foo(x),
    None() => print("matched␣None()")
}
```

请注意，就像调用带有单位 (unit) 参数的函数可以作为 `f()` 而不是 `f(())` 完成一样，可以使用 `C()` 而不是 `C(())` 来实现对具有单位类型的构造函数 C 的匹配。

#### 对 bit vectors 匹配

Sail 允许在位向量上进行多种匹配，例如：

```ocaml
match v {
    0xFF => print("hex match"),
    0b0000_0001 => print("binary match"),
    0xF @ v : bits(4) => print("vector concatenation pattern"),
    0xF @ [bitone, _, b1, b0] => print("vector pattern"),
    _ : bits(4) @ v : bits(4) => print("annotated wildcard pattern")
}

- 可以以十六进制或二进制形式匹配位向量文字。
- 向量串联模式，形式为 `pattern @ . . . @ pattern`。我们必须能够推断向量连接模式中所有子模式的长度，因此在上面的示例中，向量连接模式下的所有通配符和变量模式都有类型注释。在模式的上下文中，`:` 运算符的绑定比 `@` 运算符更紧密

- 向量模式，对于位向量，这些模式在单个位上匹配。在上面的示例中，b0 和 b1 的类型为 bit。模式 bitone 是一个 bit 字面量，bitzero 是另一个 bit 字面量模式。

请注意，由于 Sail 中的向量是类型多态的，因此我们还可以使用向量串联模式和向量模式来匹配非位向量。

#### 对 list 匹配

Sail 允许使用模式对列表进行解构。列表有两种匹配模式，`cons patterns` 和 `list literal patterns`。

```ocaml
match ys {
    x :: xs => print("cons pattern"),
    [||] => print("empty list")
}
match ys {
    [|1, 2, 3|] => print("list pattern"),
    _ => print("wildcard")
}
```

#### 对 string 匹配

不同寻常的是，Sail 允许在模式匹配中使用字符串和字符串的串联

```ocaml
match s {
    "hello" ^ " " ^ "world" => print("matched hello world"),
    _ => print("wildcard")
}
```

注意，字符串匹配始终是贪婪的，因此下面的示例虽然在语法上有效，但永远不会与第一种情况匹配。

```ocaml
match s {
    "hello" ^ s ^ "world" => print("matched hello" ^ s ^ "world"),
    "hello" ^ s => print("matched hello" ^ s),
    _ => print("wildcard")
}
```

字符串匹配最常与上面介绍的映射一起使用，以允许解析包含整数的字符串：

```ocaml
match s {
    "int=" ^ int(x) ^ ";" => x
    _ => -1
}
```

> 这旨在用于分析汇编语言。

#### As patterns

与 OCaml 一样，Sail 也支持使用 as 关键字命名部分模式。例如，在上面的列表模式中，我们可以将整个列表绑定为 zs，如下所示：

```ocaml
match ys {
    x :: xs as zs => print("cons with as pattern"),
    [||] => print("empty list")
}
```

as 模式的优先级低于模式中的任何其他关键字或运算符，因此在此示例中，zs 将引用 `x::xs`。

### 可变与不可变

可以通过 let 关键字引入局部不可变绑定：

```ocaml
let pattern = expression in expression
```

pattern 匹配到第一个表达式，绑定该模式中的任何标识符。该模式可以具有任何形式，如在 match 语句的分支中，但它应该是完整的(即它不应该不匹配)。

当在 block 中使用时，我们允许 let 语句的变体，其中它可以用分号而不是 in 关键字终止。

```ocaml
{
    let pattern = expression0;
    expression1;
    ...
    expressionn
}
```

等价于

```ocaml
{
    let pattern = expression0 in {
        expression1;
        ...
        expressionn
    }
}
```

```ocaml
{
    let pattern = expression0 in
    expression1;
    ...
    expressionn // pattern not visible
}
```

相反，模式将只绑定在表达式中，而不是任何进一步的其他表达式中。通常，以分号结尾的 let 语句的块形式在块中应始终是首选。

在函数参数、match 语句和 let 中绑定的变量始终是不可变的，但 Sail 也允许可变变量。可变变量通过使用块中的赋值运算符进行隐式绑定。

```ocaml
{
    x : int = 3 // Create a new mutable variable x initialised to 3
    x = 2 // Rebind it to the value 2
}
```

赋值运算符是相等符号，就像在 C 和其他编程语言中一样。 Sail 支持丰富的 l 值形式语言，可以出现在赋值的左侧。这些将在第 4.8.1 小节中描述。请注意，我们本可以简单的写成

```ocaml
{
    x = 3;
    x = 2
}
```

但它不会进行类型检查。这样做的原因是，如果声明了一个没有类型的可变变量，Sail 将尝试从表达式的右侧推断出最具体的类型。然而，在这种情况下，Sail 会将类型推断为 `int(3)`，因此当我们尝试将其重新分配给 2，因为类型 `int(2)`不是 `int(3)` 的子类型。因此，我们将其声明为 `int`，如第 4.3 节所述，它是所有数值类型的超类型。一旦使用特定类型创建变量，Sail 将不允许我们更改变量的类型。我们可以为变量 x 设置一个更具体的类型，因此

```ocaml
{
    x : {|2, 3|} = 3;
    x = 2
}
```

上面的类型注释将允许 x 为 2 或 3，但不允许任何其他值。`{|2, 3|}` 语法等同于 `{2, 3}` 中的 `{'n,  'n -> int('n)}`

### 4.8 赋值和 l 值(左值)

在 ISA 规范中，向复杂的 l 值复制是很常见的

例如向一个 bit vector 寄存器的子向量或命名字段赋值，或者向通过某些辅助函数计算得到的 l 值，例如为当前执行模型选择适当的寄存器。

对于 vector l 值，允许我们写入向量的各个元素，或者是子向量：

```sail
{
    v : bits(8) = 0xFF;
    v[0] = bitzero;
    assert(v == 0xFE)
}

{
    v : bits(8) = 0xFF;
    v[3 .. 0] = 0x0; // assume default Order dec
    assert(v == 0xF0)
}
```

对于向量拼接 l 值，与向量拼接模式非常相似

```ocaml
{
    v1 : bits(4) = 0xF;
    v2 : bits(4) = 0xF;
    v1 @ v2 = 0xAB;
    assert(v1 == 0xA & v2 == 0xB)
}
```

对于结构体，我们可以写入单个字段

```ocaml
{
    s : S = struct { field = 0xFF }
    s.field = 0x00
}
```

对于元组

```ocaml
{
    (x, y) = (2, 3);
    assert(x == 2 & x == 3)
}
```

// TODO: 1-value
最后，我们允许函数以 1-value 出现。这是一种非常简单的方法来声明看起来像自定义 1-value 的 "setter" 函数，例如：

```ocaml
{
    memory(addr) = 0x0F
}
```

这之所以有效，是因为 `f(x) = y` 是 `f(x, y)` 的糖。此功能通常用于设置在读取或写入时具有附加语义的寄存器或存储器。我们通常使用重载功能来声明似乎是 `getter/setter` 对的内容，因此在上面的例子中，我们可以实现一个 `read_memory` 函数和一个 `write_memory` 函数，并将它们都重载为内存，以允许我们使用 `memory(addr) = data` 写入内存，使用 `data = memory(addr)` 读取内存：

```ocaml
val read_memory : bits(64) -> bits(8)
val write_memory : (bits(64), bits(8)) -> unit

overload memory = {read_memory, write_memory}
```

有关运算符和函数重载的更多详细信息，请参见第 4.12 节。

### 4.9 寄存器

寄存器可以用 "顶级声明" 声明

```ocaml
register name : type
```

寄存器本质上是顶级全局变量，可以使用前面讨论的 l 表达式形式进行设置。目前对 Sail 中的寄存器类型没有限制。
寄存器与普通可变变量不同，因为我们可以通过名称传递对它们的引用。

对寄存器 R 的引用创建为引用 R。如果寄存器 R 的类型为 A，则引用 R 的类型将为寄存器(A)。有一个取消引用 l 值运算符 *，用于分配给寄存器引用。寄存器引用的一个用途是创建通用寄存器列表，以便可以使用数值变量对它们进行索引。例如：

```rust
default Order dec
$include <prelude.sail>

register X0 : bits(8)
register X1 : bits(8)
register X2 : bits(8)

let X : vector(3, dec, register(bits(8))) = [ref X2, ref X1, ref X0]

function main() : unit -> unit = {
    X0 = 0xFF;
    assert(X0 == 0xFF);
    (*X[0]) = 0x11;
    assert(X0 == 0x11);
    (*ref X0) = 0x00;
    assert(X0 == 0x00)
}
```

我们可以使用内置的 "reg_deref" 取消引用寄存器引用 (参见第 4.16 节)，其设置如下：

```rust
val "reg_deref" : forall ('a : Type). register('a) -> 'a effect {rreg}
```

目前没有用于在表达式中取消引用寄存器的内置语法糖。

与以前版本的 Sail 不同，引用和取消引用寄存器是显式完成的，尽管如果大量使用寄存器引用的特定规范需要该语义，我们可以使用自动转换来隐式取消引用寄存器，如下所示：

```rust
val cast auto_reg_deref = "reg_deref" : forall ('a : Type). register('a) -> 'a effect {rreg}
```

### 4.10 类型声明

#### 4.10.1 枚举

枚举可以采用类似 Haskell 的语法(适用于较小的枚举)或更传统的类似 C 的语法进行定义，这对具有更多成员的枚举，通常更具可读性。

对于可以作为枚举一部分的标识符，没有词法约束。枚举类型的名称也没有限制，但必须是有效的标识符。例如，下面演示了定义具有三个成员(Bar、Baz 和 quux)的枚举 Foo 的两种方法：

```sail
enum Foo = Bar | Baz | quux

enum Foo = {
    Bar,
    Baz,
    quux
}
```

对于每个枚举类型 `E`, sail 都会生成一个 `num_of_E` 函数和一个 `E_of_num` 函数，对于上面的 `Foo`，它们将具有以下定义：

```ocaml
val Foo_of_num : forall 'e, 0 <= 'e <= 2. int('e) -> Foo
function Foo_of_num(arg) = match arg {
    0 => Bar,
    1 => Baz,
    _ => quux
}

val num_of_Foo : Foo -> {'e, 0 <= 'e <= 2. int('e)}
function num_of_Foo(arg) = match arg {
    Bar => 0,
    Baz => 1,
    quux => 2
}
```

请注意，这些函数不会自动转换为隐式强制转换。

#### 4.10.2 结构体

使用 struct 关键字定义结构体，如下所示：

```ocaml
struct Foo = {
    bar : vector(4, dec, bit),
    baz : int,
    quux : range(0, 9)
}
```

如果我们有一个结构 `foo : Foo`，它的字段可以通过 `foo.bar` 访问，并设置为 `foo.bar = 0xF`。它也可以使用构造 `{foo with bar = 0xF}` 以纯函数方式更新。

可以使用 `struct {foo = 0xF， baz = 42， quux = 3}` 创建新的结构体。

对结构体的名称或其字段的名称没有词法限制。

无法对结构进行模式匹配。

#### 4.10.3 Unions

例如，可以在 Sail 中定义来自 Haskell 的 `maybe` 类型，如下所示：

```ocaml
union maybe ('a : Type) = {
    Just : 'a,
    None : unit
}
```

调用构造函数比如 Just 的方式类似于函数，如 `Just(3): maybe(int)`。None 的构造函数也以这种方式调用：`None()`。请注意，与其他语言不同，每个构造函数都必须与一个类型相关联，没有空构造函数。与结构体一样，构造函数的名称和类型本身都没有词法限制，唯一限制是它们必须是有效的标识符。

#### 4.10.4 位域(Bitfields)

下面的示例创建一个名为 cr 的位域类型, 和一个该类型的寄存器 CR。

```ocaml
bitfield cr : bitvector(8,dec) = {
    CR0 : 7 .. 4,
    LT : 7,
    GT : 6,
    CR1 : 3 .. 2,
    CR3 : 1 .. 0
}
register CR : cr
```

一个位域的定义会创建一个对位向量类型的 Wrapper，并为字段生成 getter 和 setter。对于 setter 会假定它们用于设置位域类型的寄存器。如果位向量是递减，则字段的索引也必须按递减顺序排列，反之亦然。

对于上面的示例，Wrapper 的定义会是如下：

```ocaml
struct cr = {bits : bitvector(8, dec)}
```

完整的向量可以作为 `CR.bits()` 访问，cr 类型的寄存器可以像 `CR->bits() -> = 0xFF` 设置。获取和设置单个字段的操作与 CR 类似。例如 `CR0()` 和 `CR->CR0()` = `0xF`

在内部，位域的定义将为每个字段 `F` 生成一个 `_get_F` 和 `_set_F` 函数，然后将它们重载为访问器语法(accessor synta)的`_mod_F`。setter 将位域作为寄存器的引用，因此我们使用 `->` 表示法。
对于 cr 类型值的纯更新，还定义了一个函数 `update_F`。

> 有关 getter 和 setter 的更多详细信息，请参见第 4.8.1 节。

位字段定义中的单个位(例如 LT：7)将被定义为长度为 1 的位向量，而不是 bit 类型的值，这复刻了 ARM 的 ASL 语言的行为。

### 4.11 Operators

Sail 中的有效运算符是以下非字母数字字符的序列：`!%&*+-./:<>=@^|`。此外，任何此类序列都可能以下划线后跟任何有效标识符为后缀，因此 `<=_u` 甚至 `<=_unsigned` 都是有效的运算符名称。运算符可以是左、右或非关联，并且有 10 个不同的优先级，范围从 0 到 9，其中 9 的绑定最紧密。为了声明运算符的优先级，我们使用固定声明，例如：

```ocaml
infix 4 <=_u
```

对于左或右关联运算符，我们将分别使用关键字 `infixl` 或 `infixr`。运算符可以在任何可以通过运算符关键字使用普通标识符的地方使用。因此，`<=_u` 运算符可以定义为：

```ocaml
val operator <=_u : forall 'n. (bits('n), bits('n)) -> bool
function operator <=_u(x, y) = unsigned(x) <= unsigned(y)
```

**内置优先级** Sail 中内置了几个常见运算符的优先级。其中包括类型级数值表达式中使用的所有运算符，以及几种常见运算，如相等、除法和取模。下表总结了这些运算符的优先级。

| Precedence | Left associative | Non-associative | Right associative |
|------------|------------------|-----------------|-------------------|
|      9     |                  |                 |                   |
|      8     |                  |                 |  ^                |
|      7     |    *, /, %       |                 |                   |
|      6     |    +,-           |                 |                   |
|      5     |                  |                 |                   |
|      4     |                  |<, <=, >, >=, !=, =, ==|                   |
|      3     |                  |                 |  &                |
|      2     |                  |                 |  |                |
|      1     |                  |                 |                   |
|      0     |                  |                 |                   |

**类型运算符** Sail 允许在类型级别使用运算符。例如，我们可以为内置范围 range 定义一个同义词：

```ocaml
infix 3 ...
type operator ... ('n : Int) ('m : Int) = range('n, 'm)
let x : 3 ... 5 = 4
```

注意，这里不能使用 `..` 作为运算符名称，因为这是向量切片的保留语法。类型中使用的运算符与表达式级别上同名的运算符共享优先级。

### 4.12 Ad-hoc 重载

Sail 有一个灵活的重载机制，使用 overload 关键字

`overload name = { name_1 , . . . , name_n }`

overload 需要一个标识符名称，以及一个其他标识符名称的列表来重载该名称。当在 Sail 定义中看到重载名称时，类型检查器将按从左到右的顺序(即从 name_1 到 name_n)尝试每个重载。直到找到一个使生成的表达式正确的名称。

同一标识符允许多个重载声明，第一个重载声明之后的每个重载声明都会将其标识符名称列表添加到重载列表的右侧(因此，前面的重载声明优先于后面的重载声明)。因此，我们可以将上述语法示例中的每个标识符拆分为它自己的行，如下所示：

```ocaml
overload name = { name_1 }
...
overload name = { name_n }
```

如何使用重载函数的示例：

下面我们分别定义了用于打印整数和字符串的函数 print_int, print_string。然后将 print 重载为 print_int 或 print_string，因此我们可以在以下 main 中使用 print 打印数字(如 4)或字符串(如"Hello， World！")。

```ocaml
val print_int : int -> unit
val print_string : string -> unit

overload print = {print_int, print_string}

function main() : unit -> unit = {
    print("Hello,␣World!");
    print(4);
}
```

你可以使用以下命令 `sail -ddump_tc_ast examples/overload.sail` 将类型检查的 AST dump 到 stdout，重载产生了预期的效果:

```ocaml
function main () : unit = {
    print_string("Hello,␣World!");
    print_int(4)
}
```

这个参数对于测试重载非常有用。由于重载是按照它们在源文件中列出的顺序完成的，因此确保此顺序正确非常重要。标准库中的一个常见做法是，保证 对输出有更多约束的函数 重载为 接受更多输入但保证其结果较少的函数。
例如，我们可能有两个除法函数：

```ocaml
val div1 : forall 'm 'n, 'n >= 0 & 'm > 0. (int('n), int('m)) -> {'o, 'o >= 0. int('o)}
val div2 : (int, int) -> option(int)
```

第一个保证如果 `'m >= 0`, `'n > 0`，则结果将大于或等于零。如果我们将这些定义重载为：

`overload operator / = {div1, div2}`

当输入符合 div1 的约束时，div1 会被应用，因此可以保证其输出的约束.

> 实际上，由于 option 类型，我们需要手动检查除以零的情况。注意，在重载不同情况下，返回值类型也可能非常不同。

重载函数具有的参数数量也可以变化，因此我们可以用它来定义带有可选参数的函数，例如:

```ocaml
val zero_extend_1 : forall 'm 'n, 'm <= 'n. bits('m) -> bits('n)
val zero_extend_2 : forall 'm 'n, 'm <= 'n. (bits('m), int('n)) -> bits('n)
overload zero_extend = {zero_extend_1, zero_extend_2}
```

在此示例中，我们可以调用 zero_extend，并且返回长度是隐式的 (可能使用 sizeof，参见第 4.13 节)，或者我们可以自己将其作为显式参数提供。

### 4.13 Sizeof 和 Constraint

如第 4.1 节所述，Sail 允许在表达式中包含任意类型变量。但是，我们可以稍微走得更远，在代码中包括任意(类型级)数值表达式以及类型约束。

例如，如果我们有一个将两个位向量作为参数的函数，那么有几种方法可以计算它们的长度之和。

```ocaml
val f : forall 'n 'm. (bits('n), bits('m)) -> unit
function f(xs, ys) = {
    let len = length(xs) + length(ys);
    let len = 'n + 'm;
    let len = sizeof('n + 'm);
    ()
}
```

注意第二行等价于

```ocaml
let len = sizeof('n) + sizeof('n)
```

还有 `constraint` 关键字，它接受类型级约束并允许将其用作布尔表达式，因此我们可以这样写：

```ocaml
function f(xs, ys) = {
    if constraint('n <= 'm) {
        // Do something
    }
}
```

而不是等效的测试长度 `(xs) <= len(ys)`。这种编写表达式的方式可以简洁明了，还可以非常明确地说明在流类型化期间将生成哪些约束。但是，必须重写定义的所有约束和大小才能生成可执行代码，这可能导致生成的定理证明器输出 (在外观上) 与源输入有所不同。总之，最好谨慎使用 `sizeof` 和 `constraint`

但是，如前所述，sizeof 和 constraint 都可以指仅出现在输出中或在运行时无法访问的类型变量，因此可用于实现隐式参数，如第 4.1 节中的 replicate_bits 所示。

### 4.14 Scattered

在 Sail 规范中，有时需要收集与每个机器指令（或其组）相关的定义，例如，将 AST 类型的子句与解码和执行函数的相关子句分组，如第 2 节所示。Sail 允许使用句法糖来表示 "Scattered" 的定义。函数或联合类型都支持。

首先通过声明 Scattered 定义的名称和种类（function 或 union）来开始分散定义，例如:

```ocaml
scattered function foo
scattered union bar
```

然后是联合体或函数的子句列表，这些子句可以与其他定义（例如以下代码中的 `E`）自由交错

```ocaml
union clause bar : Baz(int, int)

function clause foo(Baz(x, y)) = . . .

enum E = A | B | C

union clause bar : Quux(string)

function clause foo(Quux(str)) = print(str)
```

最后，分散的定义以 end 关键字结尾，如下所示：

```ocaml
end foo
end bar
```

从语义上讲，union 类型的 scattered 定义出现在其定义的开头，funciton 的 scattered 定义出现在其末尾。scattered 函数定义可以是递归的，但应避免递归。

### 4.15 Exceptions

也许令人惊讶，对于一个规范语言来说，Sail 竟然支持异常。这是因为异常作为一种语言功能有时会出现在供应商的 ISA 伪代码中，如果 Sail 本身不支持异常，则此类代码将很难转换为 Sail。我们已经将 Sail 翻译成 monadic theorem 证明代码，因此使用支持异常的 monad 是相当自然的。

> TODO: 解释 monad 和 monadic theorem

对于异常，我们提供两种语言功能：`throw` 语句和 `try-catch` 块。throw 关键字的参数为 `exception` 类型的值，该值可以是任何用户定义的类型。Sail 没有内置的异常类型，因此要使用异常，必须基于每个项目设置一个异常。通常异常类型会是一个 union，通常是一个 `cattered union`，它允许在整个规范中声明异常，就像在 OCaml 中一样，例如：

```ocaml
val print = {ocaml: "print_endline"} : string -> unit

scattered union exception

union clause exception = Epair : (range(0, 255), range(0, 255))

union clause exception = Eunknown : string

function main() : unit -> unit = {
    try {
        throw(Eunknown("foo"))
    } catch {
        Eunknown(msg) => print(msg),
        _ => exit()
    }
}

union clause exception = Eint : int

end exception
```

请注意，这里使用 scattered 类型的方式 (在 main 结束后有新增了一个 Eint 的变体)，允许在使用其他异常后声明新的异常。

### 4.16 Preludes 和默认环境

默认情况下，Sail 几乎没有内置类型或函数，除了本章中描述的基元类型。这是因为即使是最基本的运算符，不同的供应商伪代码也具有不同的命名约定和样式，因此我们的目标是提供灵活性，并避免使用任何特定的命名约定或内置函数集。但是，每个 Sail 后端通常都实现了特定的外部名称，因此对于 PowerPC ISA 描述，可能会有：

```ocaml
val EXTZ = "zero_extend" : ...
```

对于 arm 则是:

```ocaml
val ZeroExtend = "zero_extend" : ...
```

每个后端都知道 "zero_extend" 这个外部名称，但实际的 Sail 函数会针对每个供应商的伪代码进行适当的命名。因此，每个 Sail ISA 规范都有自己的 prelude。

但是，Sail 代码库中的 lib 目录包含一些文件，这些文件可以包含在任何 ISA 规范中，以执行某些基本操作。下面列出了这些：

- flow.sail 包含流类型化正常工作所需的基本定义。
- arith.sail 包含整数的简单算术运算。
- vector_dec.sail 包含对递减（dec）索引向量的运算，参见第 4.4 节。
- vector_inc.sail 与 vector_dec.sail 类似，除了增加（inc）索引向量。
- option.sail 包含 option 类型的定义，以及一些相关的实用程序函数。
- prelude.sail 包含上述所有文件，并根据默认顺序在 vector_dec.sail 和 vector_inc.sail 之间进行选择（必须在包含此文件之前设置）。
- smt.sail 定义运算符，允许通过将 div、mod 和 abs 公开给 Z3 SMT 求解器，在类型中使用它们。
- exception_basic.sail 定义一个微不足道的异常类型，用于您不想声明自己的异常类型（参见第 4.15 节）。

## 5 深入 Sail 内部

### 5.1 AST
