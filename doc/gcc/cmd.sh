rm ssa-dom-cse-2.* || echo ""
./build-toolchain-out/bin/riscv64-unknown-elf-gcc-13.2.0 ./gcc/gcc/testsuite/gcc.dg/tree-ssa/ssa-dom-cse-2.c \
    -O1 \
    --verbose \
    -fdiagnostics-plain-output \
    -ftree-vectorize \
    -fno-tree-slp-vectorize \
    -fpeel-loops \
    -fopt-info-missed=missed.all \
    -fno-tree-fre -fno-tree-pre -fdump-tree-optimized --param sra-max-scalarization-size-Ospeed=32 -S -o ssa-dom-cse-2.s

# gcc ./gcc/gcc/testsuite/gcc.dg/tree-ssa/ssa-dom-cse-2.c \

 gcc ./gcc/gcc/testsuite/gcc.dg/tree-ssa/ssa-dom-cse-2.c \
    -O1 \
    -fdiagnostics-plain-output \
    -ftree-vectorize \
    -fno-tree-slp-vectorize \
    -fopt-info-missed=missed2.all \
    -fno-tree-fre -fno-tree-pre -fdump-tree-optimized --param sra-max-scalarization-size-Ospeed=32 -S -o ssa-dom-cse-2.s2