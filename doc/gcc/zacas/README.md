# 添加 zacas 拓展

## 问题

### riscv-opts MASK 改为自动生成

见 [RISC-V:Optimize the MASK opt generation](https://github.com/gcc-mirror/gcc/commit/e4a4b8e983bac865eb435b11798e38d633b98942)

riscv-opts.h -> riscv.opt

### `error: 'CODE_FOR_riscv_amocas32' was not declared in this scope;`

```bash
g++  -fno-PIE -c   -g -O2   -DIN_GCC -DCROSS_DIRECTORY_STRUCTURE   -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wmissing-format-attribute -Wconditionally-supported -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings -fno-common  -DHAVE_CONFIG_H -fno-PIE -I. -I. -I../.././gcc/gcc -I../.././gcc/gcc/. -I../.././gcc/gcc/../include  -I../.././gcc/gcc/../libcpp/include -I../.././gcc/gcc/../libcody -I/plct/riscv-gnu-toolchain/build-gcc-newlib-stage1/./gmp -I/plct/riscv-gnu-toolchain/gcc/gmp -I/plct/riscv-gnu-toolchain/build-gcc-newlib-stage1/./mpfr/src -I/plct/riscv-gnu-toolchain/gcc/mpfr/src -I/plct/riscv-gnu-toolchain/gcc/mpc/src  -I../.././gcc/gcc/../libdecnumber -I../.././gcc/gcc/../libdecnumber/dpd -I../libdecnumber -I../.././gcc/gcc/../libbacktrace -I/plct/riscv-gnu-toolchain/build-gcc-newlib-stage1/./isl/include -I/plct/riscv-gnu-toolchain/gcc/isl/include  -o riscv-selftests.o -MT riscv-selftests.o -MMD -MP -MF ./.deps/riscv-selftests.TPo ../.././gcc/gcc/config/riscv/riscv-selftests.cc
../.././gcc/gcc/config/riscv/riscv-builtins.cc:147:5: error: 'CODE_FOR_riscv_amocas32' was not declared in this scope; did you mean 'CODE_FOR_riscv_fscsr'?
  147 |   { CODE_FOR_riscv_ ## INSN, "__builtin_riscv_" NAME,                   \
      |     ^~~~~~~~~~~~~~~
../.././gcc/gcc/config/riscv/riscv-builtins.cc:147:5: note: in definition of macro 'RISCV_BUILTIN'
  147 |   { CODE_FOR_riscv_ ## INSN, "__builtin_riscv_" NAME,                   \
      |     ^~~~~~~~~~~~~~~
g++  -fno-PIE -c   -g -O2   -DIN_GCC -DCROSS_DIRECTORY_STRUCTURE   -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wmissing-format-attribute -Wconditionally-supported -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings -fno-common  -DHAVE_CONFIG_H -fno-PIE -I. -I. -I../.././gcc/gcc -I../.././gcc/gcc/. -I../.././gcc/gcc/../include  -I../.././gcc/gcc/../libcpp/include -I../.././gcc/gcc/../libcody -I/plct/riscv-gnu-toolchain/build-gcc-newlib-stage1/./gmp -I/plct/riscv-gnu-toolchain/gcc/gmp -I/plct/riscv-gnu-toolchain/build-gcc-newlib-stage1/./mpfr/src -I/plct/riscv-gnu-toolchain/gcc/mpfr/src -I/plct/riscv-gnu-toolchain/gcc/mpc/src  -I../.././gcc/gcc/../libdecnumber -I../.././gcc/gcc/../libdecnumber/dpd -I../libdecnumber -I../.././gcc/gcc/../libbacktrace -I/plct/riscv-gnu-toolchain/build-gcc-newlib-stage1/./isl/include -I/plct/riscv-gnu-toolchain/gcc/isl/include  -o riscv-string.o -MT riscv-string.o -MMD -MP -MF ./.deps/riscv-string.TPo ../.././gcc/gcc/config/riscv/riscv-string.cc
../.././gcc/gcc/config/riscv/riscv-builtins.cc:147:5: error: 'CODE_FOR_riscv_amocas64' was not declared in this scope; did you mean 'CODE_FOR_riscv_fscsr'?
  147 |   { CODE_FOR_riscv_ ## INSN, "__builtin_riscv_" NAME,                   \
      |     ^~~~~~~~~~~~~~~
../.././gcc/gcc/config/riscv/riscv-builtins.cc:147:5: note: in definition of macro 'RISCV_BUILTIN'
  147 |   { CODE_FOR_riscv_ ## INSN, "__builtin_riscv_" NAME,                   \
      |     ^~~~~~~~~~~~~~~
make[2]: *** [../.././gcc/gcc/config/riscv/t-riscv:14: riscv-builtins.o] Error 1
make[2]: *** Waiting for unfinished jobs....
insn-opinit.cc: In function 'void init_all_optabs(target_optabs*)':
insn-opinit.cc:10604:1: note: variable tracking size limit exceeded with '-fvar-tracking-assignments', retrying without
10604 | init_all_optabs (struct target_optabs *optabs)
      | ^~~~~~~~~~~~~~~
rm gfdl.pod gcc.pod gcov-dump.pod gcov-tool.pod fsf-funding.pod gpl.pod cpp.pod gcov.pod lto-dump.pod
make[2]: Leaving directory '/plct/riscv-gnu-toolchain/build-gcc-newlib-stage1/gcc'
make[1]: *** [Makefile:4660: all-gcc] Error 2
make[1]: Leaving directory '/plct/riscv-gnu-toolchain/build-gcc-newlib-stage1'
make: *** [Makefile:591: stamps/build-gcc-newlib-stage1] Error 2
```

报错位置：

```c
#define RISCV_BUILTIN(INSN, NAME, BUILTIN_TYPE, FUNCTION_TYPE, AVAIL) \
  { CODE_FOR_riscv_ ## INSN, "__builtin_riscv_" NAME,   \
    BUILTIN_TYPE, FUNCTION_TYPE, riscv_builtin_avail_ ## AVAIL }
```

这里的宏是为了拼接下面的数组使用

```c
static const struct riscv_builtin_description riscv_builtins[] = {
  #include "riscv-cmo.def"
  #include "riscv-scalar-crypto.def"
  #include "riscv-buildins-zacas.def"
  #include "corev.def"

  DIRECT_BUILTIN (frflags, RISCV_USI_FTYPE, hard_float),
  DIRECT_NO_TARGET_BUILTIN (fsflags, RISCV_VOID_FTYPE_USI, hard_float),
  RISCV_BUILTIN (pause, "pause", RISCV_BUILTIN_DIRECT_NO_TARGET, RISCV_VOID_FTYPE, hint_pause),
};
```

下面是该结构体定义

```cpp
struct riscv_builtin_description {
  /* The code of the main .md file instruction.  See riscv_builtin_type
     for more information.  */
  enum insn_code icode;

  /* The name of the built-in function.  */
  const char *name;

  /* Specifies how the function should be expanded.  */
  enum riscv_builtin_type builtin_type;

  /* The function's prototype.  */
  enum riscv_function_type prototype;

  /* Whether the function is available.  */
  unsigned int (*avail) (void);
};
```

`CODE_FOR_riscv_ ## INSN` 对应第一个字段，检查生成的 `insn_code` 枚举：

文件：`build-gcc-newlib-stage1/gcc/insn-codes.h`

```cpp
/* Generated automatically by the program `gencodes'
   from the machine description file `md'.  */

#ifndef GCC_INSN_CODES_H
#define GCC_INSN_CODES_H

enum insn_code {
  ...
  CODE_FOR_amocas32 = 27884,
  CODE_FOR_amocas64 = 27885,
  ...
  CODE_FOR_riscv_sha256sig0_si = 28175,
  ...
}
```

与预期并不一样，查询 crypto.md 生成结果

```cpp
// riscv-scalar-crypto.def
RISCV_BUILTIN (sha256sig0_si, "sha256sig0", RISCV_BUILTIN_DIRECT, RISCV_USI_FTYPE_USI, crypto_zknh),
```

调用的都是 **RISCV**_BUILD 不应该会少拼 riscv, 故推测 riscv 前缀并不是从 第一个参数取得，再根据 insn_node 是从 .md 生成，推测是 defn_insn 的 name 取得

检查 crypto.md, 符合预期

```gcc-md
;; ZKNH - SHA256

(define_int_iterator SHA256_OP [
  UNSPEC_SHA_256_SIG0 UNSPEC_SHA_256_SIG1
  UNSPEC_SHA_256_SUM0 UNSPEC_SHA_256_SUM1])
(define_int_attr sha256_op [
  (UNSPEC_SHA_256_SIG0 "sha256sig0") (UNSPEC_SHA_256_SIG1 "sha256sig1")
  (UNSPEC_SHA_256_SUM0 "sha256sum0") (UNSPEC_SHA_256_SUM1 "sha256sum1")])

(define_insn "*riscv_<sha256_op>_si"
  [(set (match_operand:SI 0 "register_operand" "=r")
        (unspec:SI [(match_operand:SI 1 "register_operand" "r")]
                   SHA256_OP))]
  "TARGET_ZKNH && !TARGET_64BIT"
  "<sha256_op>\t%0,%1"
  [(set_attr "type" "crypto")])
```

### `internal compiler error: in riscv_expand_builtin_direct, at config/riscv/riscv-builtins.cc:347`

```bash
root@f9fd30c0c5e7:/plct/riscv-gnu-toolchain# ./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64gc_zacas -mabi=lp64 -O2 -S ./gcc/gcc/testsuite/gcc.target/riscv/zacas64.c
during RTL pass: expand
./gcc/gcc/testsuite/gcc.target/riscv/zacas64.c: In function 'foo1':
./gcc/gcc/testsuite/gcc.target/riscv/zacas64.c:5:5: internal compiler error: in riscv_expand_builtin_direct, at config/riscv/riscv-builtins.cc:347
    5 |     __builtin_riscv_amocas64(rd, rs1, rs2);
      |     ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
0xb0485b riscv_expand_builtin_direct
        ../.././gcc/gcc/config/riscv/riscv-builtins.cc:347
0xeb1242 expand_expr_real_1(tree_node*, rtx_def*, machine_mode, expand_modifier, rtx_def**, bool)
        ../.././gcc/gcc/expr.cc:11944
0xd7944a expand_expr(tree_node*, rtx_def*, machine_mode, expand_modifier)
        ../.././gcc/gcc/expr.h:310
0xd7944a expand_call_stmt
        ../.././gcc/gcc/cfgexpand.cc:2831
0xd7944a expand_gimple_stmt_1
        ../.././gcc/gcc/cfgexpand.cc:3880
0xd7944a expand_gimple_stmt
        ../.././gcc/gcc/cfgexpand.cc:4044
0xd7e404 expand_gimple_tailcall
        ../.././gcc/gcc/cfgexpand.cc:4090
0xd7e404 expand_gimple_basic_block
        ../.././gcc/gcc/cfgexpand.cc:6074
0xd80266 execute
        ../.././gcc/gcc/cfgexpand.cc:6835
Please submit a full bug report, with preprocessed source (by using -freport-bug).
Please include the complete backtrace with any bug report.
See <https://gcc.gnu.org/bugs/> for instructions.
```

```cpp

  /* Map any target to operand 0.  */
  int opno = 0;
  if (has_target_p)
    create_output_operand (&ops[opno++], target, TYPE_MODE (TREE_TYPE (exp)));

  gcc_assert (opno + call_expr_nargs (exp)
       == insn_data[icode].n_generator_args);

  /* ../.././gcc/gcc/config/riscv/zacas.md:15 */
  {
    "riscv_amocas64",
#if HAVE_DESIGNATED_UNION_INITIALIZERS
    { .single =
#else
    {
#endif
    "return amocas.d\t%0,%1,%2",
#if HAVE_DESIGNATED_UNION_INITIALIZERS
    },
#else
    0, 0 },
#endif
    { (insn_gen_fn::stored_funcptr) gen_riscv_amocas64 },
    &operand_data[48],
    3,
    3,
    0,
    1,
    1
  },
```

经检查断言右侧输出符合预期 3. 左侧输出不符合预期，`call_expr_nargs` 不是很能看得懂，推测 opno 有问题，has_target_p 暂时不知道触发条件。

经过多次对比，我的函数唯一不同之处是返回值为 VOID, 查看其他返回值为 VOID 的函数：

```cpp
// zicboz
RISCV_BUILTIN (zero_si, "zicboz_cbo_zero", RISCV_BUILTIN_DIRECT_NO_TARGET, RISCV_VOID_FTYPE_VOID_PTR, zero32),
```

它使用的第三个参数是：`RISCV_BUILTIN_DIRECT_NO_TARGET`, 查看此 builtin 函数对应的机器描述：

```lisp
(define_insn "riscv_zero_<mode>"
  [(unspec_volatile:X [(match_operand:X 0 "register_operand" "r")]
    UNSPECV_ZERO)]
  "TARGET_ZICBOZ"
  "cbo.zero\t%a0"
  [(set_attr "type" "cbo")]
)
```

所以这里应该使用 `RISCV_BUILTIN_DIRECT_NO_TARGET`

### 生成汇编没有预期指令，只有一个 `nop`

为 md 设置属性 `set_attr "type" "zacas"`

成功生成汇编

```asm
        .file   "zacas32.c"
        .option nopic
        .attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zacas1p0"
        .attribute unaligned_access, 0
        .attribute stack_align, 16
        .text
        .align  1
        .globl  foo1
        .type   foo1, @function
foo1:
        addi    sp,sp,-32
        sw      ra,28(sp)
        sw      s0,24(sp)
        addi    s0,sp,32
        sw      a0,-20(s0)
        sw      a1,-24(s0)
        sw      a2,-28(s0)
        lw      a4,-28(s0)
        amocas.w        a4,a5,a4
        nop
        lw      ra,28(sp)
        lw      s0,24(sp)
        addi    sp,sp,32
        jr      ra
        .size   foo1, .-foo1
        .ident  "GCC: (g6a7e4ff7275-dirty) 14.0.0 20231116 (experimental)"
        .section        .note.GNU-stack,"",@progbits
```

> NOP 指令不会改变任何用户可见的状态，除了增加 PC（except for advancing the pc）。NOP 被编码成 ADDI x0, x0, 0. 功能大概有：有效地址边界的对齐，留给内联代码的空间

### rv64 下没有成功输出汇编

```rust
(define_insn "riscv_amocassi3"
  [(set (match_operand:SI 0 "register_operand" "=r")
        (unspec_volatile:SI [(match_operand:SI 1 "register_operand" "=r")
                    (match_operand:SI 2 "register_operand" "r")]
                    UNSPEC_AMOCAS32))]
  "TARGET_ZACAS && !TARGET_64BIT"
  "amocas.w\t%0,%1,%2"
  [(set_attr "type" "zacas")])
```

```rust
(define_insn "riscv_amocasdi3"
  [(set (match_operand:DI 0 "register_operand" "=r")
        (if_then_else:DI (eq:DI (match_dup 0)
                                (match_operand:DI 1 "register_operand" "r"))
                       (match_operand:DI 2 "register_operand" "r")
                       (match_dup 0)))]
  "TARGET_ZACAS && TARGET_64BIT"
  "amocas.d\t%0,%1,%2"
  [(set_attr "type" "zacas")])
```

64 位下使用的 `if_then_else` 是生成指令的条件，如果不匹配就不会生成，而这个判断应该是由 amocas 指令本身做的事

### WIP: set_attr 为什么必须加上？

[9.9 机器描述信息提取] 中解释：

下面的代码会生成函数 `get_attr_type`, 用于获取 inst 的 attr 信息

```cpp
char *func_name, *attr_name;
func_name = strcat("get_attr_", attr_name);
```

define_attr 可以设置默认值

```lisp
(define_attr "type"
  "unknown,branch,jump,jalr,ret,call,load,fpload,store,fpstore,
   mtc,mfc,const,arith,logical,shift,slt,imul,idiv,move,fmove,fadd,fmul,
   fmadd,fdiv,fcmp,fcvt,fsqrt,multi,auipc,sfb_alu,nop,trap,ghost,bitmanip,
   rotate,clmul,min,max,minu,maxu,clz,ctz,cpop,
   atomic,condmove,cbo,crypto,zacas,pushpop,mvpair,zicond,rdvlenb,rdvl,wrvxrm,wrfrm,
   rdfrm,vsetvl,vsetvl_pre,vlde,vste,vldm,vstm,vlds,vsts,
   vldux,vldox,vstux,vstox,vldff,vldr,vstr,
   vlsegde,vssegte,vlsegds,vssegts,vlsegdux,vlsegdox,vssegtux,vssegtox,vlsegdff,
   vialu,viwalu,vext,vicalu,vshift,vnshift,vicmp,viminmax,
   vimul,vidiv,viwmul,vimuladd,viwmuladd,vimerge,vimov,
   vsalu,vaalu,vsmul,vsshift,vnclip,
   vfalu,vfwalu,vfmul,vfdiv,vfwmul,vfmuladd,vfwmuladd,vfsqrt,vfrecp,
   vfcmp,vfminmax,vfsgnj,vfclass,vfmerge,vfmov,
   vfcvtitof,vfcvtftoi,vfwcvtitof,vfwcvtftoi,
   vfwcvtftof,vfncvtitof,vfncvtftoi,vfncvtftof,
   vired,viwred,vfredu,vfredo,vfwredu,vfwredo,
   vmalu,vmpop,vmffs,vmsfs,vmiota,vmidx,vimovvx,vimovxv,vfmovvf,vfmovfv,
   vslideup,vslidedown,vislide1up,vislide1down,vfslide1up,vfslide1down,
   vgather,vcompress,vmov,vector"
  (cond [(eq_attr "got" "load") (const_string "load")

  ;; If a doubleword move uses these expensive instructions,
  ;; it is usually better to schedule them in the same way
  ;; as the singleword form, rather than as "multi".
  (eq_attr "move_type" "load") (const_string "load")
  (eq_attr "move_type" "fpload") (const_string "fpload")
  (eq_attr "move_type" "store") (const_string "store")
  (eq_attr "move_type" "fpstore") (const_string "fpstore")
  (eq_attr "move_type" "mtc") (const_string "mtc")
  (eq_attr "move_type" "mfc") (const_string "mfc")

  ;; These types of move are always single insns.
  (eq_attr "move_type" "fmove") (const_string "fmove")
  (eq_attr "move_type" "arith") (const_string "arith")
  (eq_attr "move_type" "logical") (const_string "logical")
  (eq_attr "move_type" "andi") (const_string "logical")

  ;; These types of move are always split.
  (eq_attr "move_type" "shift_shift")
    (const_string "multi")

  ;; These types of move are split for doubleword modes only.
  (and (eq_attr "move_type" "move,const")
       (eq_attr "dword_mode" "yes"))
    (const_string "multi")
  (eq_attr "move_type" "move") (const_string "move")
  (eq_attr "move_type" "const") (const_string "const")
  (eq_attr "move_type" "rdvlenb") (const_string "rdvlenb")]
 (const_string "unknown")))
```

最后一个 `unknown` 就是默认值，生成的代码位于：`build-gcc-newlib-stage1/gcc/insn-attr.h`

`build-gcc-newlib-stage2/gcc/insn-attr-common.h`

查找对应的枚举 `grep -rH -E 'TYPE_UNKNOWN' --color=always * | less -R`

```cpp
  gcc_assert (get_attr_type (insn) != TYPE_UNKNOWN);
```

### WIP: unspec_volatile & unspec

这里使用 unspec_volatile

资料：

- <https://gcc.gnu.org/onlinedocs/gccint/Side-Effects.html>

### memory consdtrains "A"

保存在通用寄存器内的地址

```lisp
(define_memory_constraint "A"
  "An address that is held in a general-purpose register."
  (and (match_code "mem")
       (match_test "GET_CODE(XEXP(op,0)) == REG")))

```

### binutil 测试不过

以为测试用例的正则中 空格 和 tab 写错（确实可能是原因之一），其实是正则使用 `[空格Tab]+` 同时匹配了两者

最后原因是 riscv_multi_subset_supports_ext 条件写错

### 128 跑不了

数据类型对不上，128 为整形应该是 `__128`

### 实际编译能跑，gcc 测试跑不通

测试用例中的 march 拼错

### `amocas.w` 在 64 位使用报错

机器模式对不上，原本的写法只能匹配 SI，但是在 64 位上指针大小是 64 位，需要匹配 DI

```lisp
(define_insn "*addsi3"
  [(set (match_operand:SI          0 "register_operand" "=r,r")
 (plus:SI (match_operand:SI 1 "register_operand" " r,r")
   (match_operand:SI 2 "arith_operand"    " r,I")))]
  ""
  "add%i2%~\t%0,%1,%2"
  [(set_attr "type" "arith")
   (set_attr "mode" "SI")])

(define_expand "addsi3"
  [(set (match_operand:SI          0 "register_operand" "=r,r")
 (plus:SI (match_operand:SI 1 "register_operand" " r,r")
   (match_operand:SI 2 "arith_operand"    " r,I")))]
  ""
{
  if (TARGET_64BIT)
    {
      rtx t = gen_reg_rtx (DImode);
      emit_insn (gen_addsi3_extended (t, operands[1], operands[2]));
      t = gen_lowpart (SImode, t);
      SUBREG_PROMOTED_VAR_P (t) = 1;
      SUBREG_PROMOTED_SET (t, SRP_SIGNED);
      emit_move_insn (operands[0], t);
      DONE;
    }
})
```

尝试使用 define_expand 配合 emit_insn 实现，无法解决匹配模式的问题

这里创建多个 insn，在 TARGET_64BIT 不同时启用里一个 insn

```cpp
RISCV_BUILTIN(amocas_si_32, "amocas32", RISCV_BUILTIN_DIRECT_NO_TARGET, RISCV_VOID_FTYPE_SI_SI_VOID_PTR, zacas_amocas32_32),
RISCV_BUILTIN(amocas_si_64, "amocas32", RISCV_BUILTIN_DIRECT_NO_TARGET, RISCV_VOID_FTYPE_SI_SI_VOID_PTR, zacas_amocas32_64),
```

### GPR 和 X 是什么机器模式

不是模式，是迭代器，定义从 `riscv.md` 被拆分到 `iterators.md`

```lisp
;; This mode iterator allows 32-bit and 64-bit GPR patterns to be generated
;; from the same template.
(define_mode_iterator GPR [SI (DI "TARGET_64BIT")])


;; This mode iterator allows :P to be used for patterns that operate on
;; pointer-sized quantities.  Exactly one of the two alternatives will match.
(define_mode_iterator P [(SI "Pmode == SImode") (DI "Pmode == DImode")])

;; Likewise, but for XLEN-sized quantities.
(define_mode_iterator X [(SI "!TARGET_64BIT") (DI "TARGET_64BIT")])


;; Branches operate on XLEN-sized quantities, but for RV64 we accept
;; QImode values so we can force zero-extension.
(define_mode_iterator BR [(QI "TARGET_64BIT") SI (DI "TARGET_64BIT")])
```

### WIP: 编译不报错，加上 `-O1` 报错

register_operand 替换为 memory_operand 造成

尝试手动添加优化参数查找原因，下面使用 `-Q --help=optimizers` 查看最终的优化结果：

```bash
diff -y <(./build-toolchain-out/bin/riscv64-unknown-elf-gcc -fthread-jumps -ftoplevel-reorder -ftree-builtin-call-dce -fsection-anchors -fsched-pressure -finline -fno-delayed-branch -fauto-inc-dec -fbranch-count-reg -fcombine-stack-adjustments -fcompare-elim -fcprop-registers -fdce -fdefer-pop -fdse -fforward-propagate -fguess-branch-probability -fif-conversion -fif-conversion2 -finline-functions-called-once -fipa-modref -fipa-profile -fipa-pure-const -fipa-reference -fipa-reference-addressable -fmerge-constants -fmove-loop-invariants -fmove-loop-stores -fomit-frame-pointer -freorder-blocks -fshrink-wrap -fshrink-wrap-separate -fsplit-wide-types -fssa-backprop -fssa-phiopt -ftree-bit-ccp -ftree-ccp -ftree-ch -ftree-coalesce-vars -ftree-copy-prop -ftree-dce -ftree-dominator-opts -ftree-dse -ftree-forwprop -ftree-fre -ftree-phiprop -ftree-pta -ftree-scev-cprop -ftree-sink -ftree-slsr -ftree-sra -ftree-ter -funit-at-a-time -finline -Q --help=optimizers) <(./build-toolchain-out/bin/riscv64-unknown-elf-gcc -O1 -funreachable-traps -Q --help=optimizers) | rg "enable.*disable"
```

除了 `-finline` 无法 enable 外都相同，依然报错

几个 xxxxx_operand 定义如下：

- general_operand: a valid general operand for machine mode MODE. This is either a register reference, a memory reference or a constant.
- register_operand: a register reference of mode MODE

```cpp

/* Return true if OP is a register reference of mode MODE.
   If MODE is VOIDmode, accept a register in any mode.

   The main use of this function is as a predicate in match_operand
   expressions in the machine description.  */

bool
register_operand (rtx op, machine_mode mode)
{
  if (GET_CODE (op) == SUBREG)
    {
      rtx sub = SUBREG_REG (op);

      /* Before reload, we can allow (SUBREG (MEM...)) as a register operand
  because it is guaranteed to be reloaded into one.
  Just make sure the MEM is valid in itself.
  (Ideally, (SUBREG (MEM)...) should not exist after reload,
  but currently it does result from (SUBREG (REG)...) where the
  reg went on the stack.)  */
      if (!REG_P (sub) && (reload_completed || !MEM_P (sub)))
 return false;
    }
  else if (!REG_P (op))
    return false;
  return general_operand (op, mode);
}

/* Return true if OP is a valid memory reference with mode MODE,
   including a valid address.

   The main use of this function is as a predicate in match_operand
   expressions in the machine description.  */

bool
memory_operand (rtx op, machine_mode mode)
{
  rtx inner;

  if (! reload_completed)
    /* Note that no SUBREG is a memory operand before end of reload pass,
       because (SUBREG (MEM...)) forces reloading into a register.  */
    return MEM_P (op) && general_operand (op, mode);

  if (mode != VOIDmode && GET_MODE (op) != mode)
    return false;

  inner = op;
  if (GET_CODE (inner) == SUBREG)
    inner = SUBREG_REG (inner);

  return (MEM_P (inner) && general_operand (op, mode));
}

```

匹配 memory_operand 的条件：

1. 要么 mode 是 VOIDmode，要么 mode 和 op mode 相同
2. op 是 MEM_P: `#define MEM_P(X) (GET_CODE (X) == MEM)`
3. op 是 general_operand

增加编译参数 `-fdump-rtl-all`, 检查生成的 rtl：

```bash
mkdir xxx

../build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64g_zacas -mabi=lp64d -fdump-rtl-all -S ../gcc/gcc/testsuite/gcc.target/riscv/zacas128.c

echo `pwd`/zacas128.c.262r.expand
```

`zacas128.c` 文件内容：

```cpp
void foo1(__int128 rd, __int128 rs2, __int128 *rs1) {
    __builtin_riscv_amocas128(rd, rs2, rs1);
}

```

[succ](./succ.rtl)
[fail](./fail.rtl)

生成的 succ 里是 mem，fail 则是 subreg, set 或 clobber. 似乎不是很容易查看，下面简化一些：

```cpp
__int128 rd = 0;
__int128 rs2 = 1;
int rs1 = 1;

void foo1()
{
    void *p = &rs1;
    return __builtin_riscv_amocas128(rd, rs2, p);
}
```

对应的：

```rust
(note 1 0 3 NOTE_INSN_DELETED)
(note 3 1 2 2 [bb 2] NOTE_INSN_BASIC_BLOCK)
(note 2 3 5 2 NOTE_INSN_FUNCTION_BEG)
(insn 5 2 6 2 (set (reg:DI 137)
        (high:DI (symbol_ref:DI ("*.LANCHOR0") [flags 0x182]))) "../gcc/gcc/testsuite/gcc.target/riscv/zacas128.c":11:12 -1
     (nil))
(insn 6 5 7 2 (set (reg/f:DI 136)
        (lo_sum:DI (reg:DI 137)
            (symbol_ref:DI ("*.LANCHOR0") [flags 0x182]))) "../gcc/gcc/testsuite/gcc.target/riscv/zacas128.c":11:12 -1
     (expr_list:REG_EQUAL (symbol_ref:DI ("*.LANCHOR0") [flags 0x182])
        (nil)))
(insn 7 6 8 2 (set (reg:DI 139)
        (high:DI (symbol_ref:DI ("*.LANCHOR1") [flags 0x182]))) "../gcc/gcc/testsuite/gcc.target/riscv/zacas128.c":11:12 -1
     (nil))
(insn 8 7 0 2 (set (reg/f:DI 138)
        (lo_sum:DI (reg:DI 139)
            (symbol_ref:DI ("*.LANCHOR1") [flags 0x182]))) "../gcc/gcc/testsuite/gcc.target/riscv/zacas128.c":11:12 -1
     (expr_list:REG_EQUAL (symbol_ref:DI ("*.LANCHOR1") [flags 0x182])
        (nil)))
```

似乎丢失了最后一个 unspec_volatile

> 但机器指令从不产生值;它们仅对机器状态的副作用有意义。特殊表达式代码用于表示副作用。

上面的似乎对此没有影响，毕竟 zicbom 的 md 中只有一条 unspec_volatile 依然正确生成

## 运行测试

```bash
# 编译
./configure --prefix=$(pwd)/build-toolchain-out --with-arch="rv64imafdc_zacas"

# 测试 gcc
rm stamps/check-gcc-newlib
rm stamps/build-gcc-newlib-stage2
time RUNTESTFLAGS=riscv.exp=zacas*.c make -j$(nproc) report-gcc | tee ./debug/report-gcc-riscv-zacas.log


# 测试 binutil
time RUNTESTFLAGS=riscv.exp=zacas* make -j$(nproc) report-binutils | tee ./debug/report-binutils-riscv-zacas.log
```

<!-- -fdump-rtl-all -->

```bash
rm -f ./zacas32.s ./zacas32.o
rm -f ./zacas64.s ./zacas64.o
rm -f ./zacas128.s ./zacas128.o

./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv32g_zacas -mabi=ilp32 -S ./gcc/gcc/testsuite/gcc.target/riscv/zacas32.c
./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64g_zacas -mabi=lp64d -S ./gcc/gcc/testsuite/gcc.target/riscv/zacas64.c
./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64g_zacas -mabi=lp64d -S ./gcc/gcc/testsuite/gcc.target/riscv/zacas128.c
./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64g_zacas -mabi=lp64d -O2 -S ./gcc/gcc/testsuite/gcc.target/riscv/zacas128.c

./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv32g_zacas -mabi=ilp32 -c ./gcc/gcc/testsuite/gcc.target/riscv/zacas32.c
./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64g_zacas -mabi=lp64d -c ./gcc/gcc/testsuite/gcc.target/riscv/zacas64.c
./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64g_zacas -mabi=lp64d -c ./gcc/gcc/testsuite/gcc.target/riscv/zacas128.c

# zawrs: 参考价值: 都属于 za 子集
rm -f ./zawrs.s
./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64gc_zawrs -S -O3 ./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c

./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64gc_zawrs -c ./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c

# zicbom, 参考价值:参数时 VOID_PTR, 返回值为 VOID
./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64gc_zicbom -mabi=lp64 -S -O3 ./gcc/gcc/testsuite/gcc.target/riscv/cmo-zicbom-1.c

# atomic_load, 参考价值: 属于原子操作, 使用了 mem_operand
./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64gc_zicbom -mabi=lp64 -S -O3 ./gcc/gcc/testsuite/gcc.target/riscv/amo-table-a-6-load-1.c


# rtl 检查脚本
rm -rf ./zacas128.c.* ./zawrs.c.* ./cmo-zicbop-1.c.* ./cmo-zicbom-1.c.* ./amo-table-a-6-load-1.c.* && ./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64g_zacas_zicbom_zawrs -mabi=lp64d -S -fdump-rtl-all -O1 ./gcc/gcc/testsuite/gcc.target/riscv/zacas128.c; ll ./*.expand

```

# 尝试打印 gimple

```cpp
FILE *fp;
fp = fopen("gimple-before-expand", "w");
FOR_BB_BETWEEN (bb, ENTRY_BLOCK_PTR ->next_bb, EXIT_BLOCK_PTR, next_bb)
  gimple_dump_bb (bb, fp, 0, 0xffff);
```
