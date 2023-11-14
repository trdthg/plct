# 报告

## 问题描述

部分测试结果：

```txt
root@f9fd30c0c5e7:/plct/riscv-gnu-toolchain# make -j$(nproc) report-gcc | tee ./debug/report-gcc.log
/plct/riscv-gnu-toolchain/scripts/testsuite-filter gcc newlib /plct/riscv-gnu-toolchain/test/allowlist `find build-gcc-newlib-stage2/gcc/testsuite/ -name *.sum |paste -sd "," -`
                === gcc: Unexpected fails for rv64imafdc lp64d medlow ===
FAIL: gcc.dg/tree-ssa/copy-headers-8.c scan-tree-dump-times ch2 "Conditional combines static and invariant" 1
FAIL: gcc.dg/tree-ssa/copy-headers-8.c scan-tree-dump-times ch2 "Will duplicate bb" 2
FAIL: gcc.dg/tree-ssa/ssa-dom-cse-2.c scan-tree-dump optimized "return 28;"
FAIL: gcc.dg/tree-ssa/update-threading.c scan-tree-dump-times optimized "Invalid sum" 0

               ========= Summary of gcc testsuite =========
                            | # of unexpected case / # of unique unexpected case
                            |          gcc |          g++ |     gfortran |
 rv64imafdc/  lp64d/ medlow |    4 /     3 |    0 /     0 |      - |
make: *** [Makefile:1057: report-gcc-newlib] Error 1
```

`gcc.dg/tree-ssa/ssa-dom-cse-2.c` 用例运行失败，原先 riscv 状态是 XFAIL，自 2023-10-11 已被移除 [commit](https://gcc.gnu.org/pipermail/gcc-cvs/2023-October/390895.html)

## 相关参数

- tree-vectorize: OPT_ftree_vectorize ftree-vectorize flag_tree_vectorize
- tree-loop-vectorize: OPT_ftree_loop_vectorize **flag_tree_loop_vectorize**
- tree-slp-vectorize: OPT_ftree_slp_vectorize flag_tree_slp_vectorize

- -fpeel-loops: x_flag_peel_loops, x_flag_cunroll_grow_size

## 测试命令

```bash
./build-toolchain-out/bin/riscv64-unknown-elf-gcc-13.2.0 ./gcc/gcc/testsuite/gcc.dg/tree-ssa/ssa-dom-cse-2.c \
    -O1 \
    -fdiagnostics-plain-output \
    -ftree-vectorize \
    -fopt-info-missed=missed2.all \
    -fno-tree-fre -fno-tree-pre -fdump-tree-optimized --param sra-max-scalarization-size-Ospeed=32 -S -o ssa-dom-cse-2.s
```

### 本机 x86 下

- -ftree-vectorize 或者 -fpeel-loops 都足够了
- 都不使用时，数组未被转为向量，循环未被优化

|参数 | 向量化优化 | 循环优化 |
|-------------------------------|---------------------------|---------------------------|
| None | 不变  |  for 循环未被优化 |
| -ftree-vectorize  | 28 | 28 |
| -fpeel-loops | 28 | 28 |
| -ftree-vectorize, -fpeel-loops | 28 | 28 |

### 开发环境下

|参数 | 向量化优化 | 循环优化 |
|-------------------------------|---------------------------|---------------------------|
| -fpeel-loops                  | 正常                      |             正常 |
| -ftree-vectorize | 数组变成了向量  |  循环未被优化 |
| -ftree-vectorize, -fno-tree-slp-vectorize | 正常  |  正常 |
| -ftree-vectorize, -fpeel-loops | 数组变成了向量 | for 循环被优化成多次重复赋值 |
| -ftree-vectorize, -fno-tree-slp-vectorize, -fpeel-loops | 正常 | 正常 |

推测 tree-slp-vectorize 导致 tree-vectorize 优化失败？

搜索：`flag_tree_loop_vectorize`

## 测试方法

推测 riscv 下，tree-vectorize 优化失败。尝试添加参数，让 gcc 输出更多优化信息

`-fopt-info-missed=missed.all`: 编译结束可以在 `./missed.all` 文件下查看结果

```bash
./gcc/gcc/testsuite/gcc.dg/tree-ssa/ssa-dom-cse-2.c:17:17: missed: couldn't vectorize loop
./gcc/gcc/testsuite/gcc.dg/tree-ssa/ssa-dom-cse-2.c:18:9: missed: not vectorized: relevant stmt not supported: sum_10 = _1 + sum_13;
./gcc/gcc/testsuite/gcc.dg/tree-ssa/ssa-dom-cse-2.c:17:17: missed: couldn't vectorize loop
./gcc/gcc/testsuite/gcc.dg/tree-ssa/ssa-dom-cse-2.c:18:9: missed: not vectorized: relevant stmt not supported: sum_10 = _1 + sum_13;
```

**missed: not vectorized: relevant stmt not supported: sum_10 = _1 + sum_13;**

此处报错语句和中间文件 27 行对应，是一条赋值赋值语句 `sum_10 =_1 + sum_13`

```c
;; Function foo (foo, funcdef_no=0, decl_uid=2269, cgraph_uid=1, symbol_order=0)

Removing basic block 5
int foo ()
{
  unsigned long ivtmp.18;
  int sum;
  const int a[8];
  int _1;
  unsigned long _19;
  void * _21;

  <bb 2> [local count: 119292720]:
  MEM <const vector(2) int> [(int *)&a] = { 0, 1 };
  MEM <const vector(2) int> [(int *)&a + 8B] = { 2, 3 };
  MEM <const vector(2) int> [(int *)&a + 16B] = { 4, 5 };
  MEM <const vector(2) int> [(int *)&a + 24B] = { 6, 7 };
  ivtmp.18_22 = (unsigned long) &a;
  _19 = ivtmp.18_22 + 32;

  <bb 3> [local count: 954449105]:
  # sum_13 = PHI <sum_10(3), 0(2)>
  # ivtmp.18_24 = PHI <ivtmp.18_23(3), ivtmp.18_22(2)>
  _21 = (void *) ivtmp.18_24;
  _1 = MEM[(int *)_21];
  sum_10 = _1 + sum_13;
  ivtmp.18_23 = ivtmp.18_24 + 4;
  if (_19 != ivtmp.18_23)
    goto <bb 3>; [88.89%]
  else
    goto <bb 4>; [11.11%]

  <bb 4> [local count: 119292720]:
  a ={v} {CLOBBER(eol)};
  return sum_10;

}
```

搜索：`relevant stmt not supported`

```cpp
  if (!ok)
    return opt_result::failure_at (stmt_info->stmt,
       "not vectorized:"
       " relevant stmt not supported: %G",
       stmt_info->stmt);
```

## 具体流程分析


追踪调用链：

```txt
can_vectorize_live_stmts <- vect_transform_stmt <- vect_transform_loop_stmt <- vect_transform_loop <- vect_transform_loops <- try_vectorize_loop_1 <- try_vectorize_loop <- pass_vectorize::execute (passes.def:310)
                                    ^                       ^                                                                                 |
                                    |                       |                                                                                 Y
                                    |                       -------------------------------------------------                 vect_slp_if_converted_bb
                                    |                                                                        |                                |
                                    -------------- vect_schedule_slp_node <- vect_schedule_scc <- vect_schedule_slp <- vect_slp_region <- vect_slp_bbs <- vect_slp_function <- pass_slp_vectorize::execute (passes.def:322)
```

> vect_transform_stmt 函数直接调用只有两处，还有许多依赖关系需要注意

pass_slp_vectorize:

```cpp
bool gate (function *) final override { return flag_tree_slp_vectorize != 0; }
```

pass_vectorize:

```cpp
  pass_vectorize (gcc::context *ctxt)
    : gimple_opt_pass (pass_data_vectorize, ctxt)
  {}

  /* opt_pass methods: */
  bool gate (function *fun) final override
    {
      return flag_tree_loop_vectorize || fun->has_force_vectorize_loops;
    }
```

排除后的调用链：

```txt
can_vectorize_live_stmts <- vect_transform_stmt <- vect_transform_loop_stmt <- vect_transform_loop <- vect_transform_loops <- try_vectorize_loop_1 <- try_vectorize_loop <- pass_vectorize::execute (passes.def:310)
```

pass_vectorize::execute
