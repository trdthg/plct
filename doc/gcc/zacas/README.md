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
#define RISCV_BUILTIN(INSN, NAME, BUILTIN_TYPE,	FUNCTION_TYPE, AVAIL)	\
  { CODE_FOR_riscv_ ## INSN, "__builtin_riscv_" NAME,			\
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

  gcc_assert (opno + call_expr_nargs (exp)
	      == insn_data[icode].n_generator_args);

struct insn_operand_data
{
  const insn_operand_predicate_fn predicate;

  const char *const constraint;

  ENUM_BITFIELD(machine_mode) const mode : 16;

  const char strict_low;

  const char is_operator;

  const char eliminable;

  const char allows_mem;
};


struct insn_data_d
{
  const char *const name;
#if HAVE_DESIGNATED_UNION_INITIALIZERS
  union {
    const char *single;
    const char *const *multi;
    insn_output_fn function;
  } output;
#else
  struct {
    const char *single;
    const char *const *multi;
    insn_output_fn function;
  } output;
#endif
  const insn_gen_fn genfun;
  const struct insn_operand_data *const operand;

  const char n_generator_args;
  const char n_operands;
  const char n_dups;
  const char n_alternatives;
  const char output_format;
};


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

## 运行测试

```bash
RUNTESTFLAGS=riscv.exp=zacas*.c make -j$(nproc) report-gcc | tee ./debug/report-gcc-riscv-zacas.log
```

```bash
./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv64g_zacas -mabi=lp64d -O2 -S ./gcc/gcc/testsuite/gcc.target/riscv/zacas64.c
```

```bash
./build-toolchain-out/bin/riscv64-unknown-elf-gcc -march=rv32gc_zacas -mabi=ilp32 -O2 -S ./gcc/gcc/testsuite/gcc.target/riscv/zacas32.c
```
