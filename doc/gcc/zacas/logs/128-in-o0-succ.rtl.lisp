
;; Function foo3 (foo3, funcdef_no=0, decl_uid=2292, cgraph_uid=1, symbol_order=0)


;; Generating RTL for gimple basic block 2


try_optimize_cfg iteration 1

Merging block 3 into block 2...
Merged blocks 2 and 3.
Merged 2 and 3 without moving.
Merging block 4 into block 2...
Merged blocks 2 and 4.
Merged 2 and 4 without moving.


try_optimize_cfg iteration 2



;;
;; Full RTL generated for this function:
;;
(note 1 0 3 NOTE_INSN_DELETED)
(note 3 1 2 2 [bb 2] NOTE_INSN_BASIC_BLOCK)
(note 2 3 5 2 NOTE_INSN_FUNCTION_BEG)
(insn 5 2 6 2 (set (reg:DI 134)
        (const_int 3 [0x3])) "./gcc/gcc/testsuite/gcc.target/riscv/zacas128.c":30:11 -1
     (nil))
(insn 6 5 7 2 (set (mem/f/c:DI (plus:DI (reg/f:DI 129 virtual-stack-vars)
                (const_int -8 [0xfffffffffffffff8])) [1 var_p+0 S8 A64])
        (reg:DI 134)) "./gcc/gcc/testsuite/gcc.target/riscv/zacas128.c":30:11 -1
     (nil))
(insn 7 6 8 2 (set (reg:DI 135)
        (const_int 1 [0x1])) "./gcc/gcc/testsuite/gcc.target/riscv/zacas128.c":31:5 -1
     (nil))
(insn 8 7 9 2 (set (reg:DI 136)
        (const_int 2 [0x2])) "./gcc/gcc/testsuite/gcc.target/riscv/zacas128.c":31:5 -1
     (nil))
(insn 9 8 0 2 (unspec_volatile:DI [
            (reg:DI 135)
            (reg:DI 136)
            (mem/f/c:DI (plus:DI (reg/f:DI 129 virtual-stack-vars)
                    (const_int -8 [0xfffffffffffffff8])) [1 var_p+0 S8 A64])
        ] UNSPEC_AMOCASTEST) "./gcc/gcc/testsuite/gcc.target/riscv/zacas128.c":31:5 -1
     (nil))
