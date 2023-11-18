# run
RUNTESTFLAGS=tree-ssa.exp make report-gcc -j$(nproc) | tee ./debug/report-gcc-tree-ssa.txt
rm stamps/check-gcc-newlib

grep -r -H "^FAIL" | grep "gcc"

grep -r -H "^FAIL" | grep "gcc" | awk '{split($0, array, ":"); print array[1]}' | uniq

grep -r -H "ssa-dom-cse-2" ./build-gcc-newlib-stage2/gcc/testsuite/

# -O3
/plct/riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/xgcc -B/plct/riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/ /plct/riscv-gnu-toolchain/gcc/gcc/testsuite/gcc.dg/tree-ssa/ssa-dom-cse-2.c -march=rv64imafdc -mabi=lp64d -mcmodel=medlow -fdiagnostics-plain-output -O3 -fno-tree-fre -fno-tree-pre -fdump-tree-optimized --param sra-max-scalarization-size-Ospeed=32 -S -o ssa-dom-cse-2.s
# -O2
/plct/riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/xgcc -B/plct/riscv-gnu-toolchain/build-gcc-newlib-stage2/gcc/ /plct/riscv-gnu-toolchain/gcc/gcc/testsuite/gcc.dg/tree-ssa/ssa-dom-cse-2.c -march=rv64imafdc -mabi=lp64d -mcmodel=medlow -fdiagnostics-plain-output -O2 -fpeel-loops -fno-tree-fre -fno-tree-pre -fdump-tree-optimized --param sra-max-scalarization-size-Ospeed=32 -S -o ssa-dom-cse-2.s
