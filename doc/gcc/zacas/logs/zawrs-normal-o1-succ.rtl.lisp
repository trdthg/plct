
;; Function foo (foo, funcdef_no=0, decl_uid=2293, cgraph_uid=1, symbol_order=0)


;; Generating RTL for gimple basic block 2


try_optimize_cfg iteration 1

Merging block 3 into block 2...
Merged blocks 2 and 3.
Merged 2 and 3 without moving.
Removing jump 7.
Merging block 4 into block 2...
Merged blocks 2 and 4.
Merged 2 and 4 without moving.


try_optimize_cfg iteration 2



;;
;; Full RTL generated for this function:
;;
(note 1 0 4 NOTE_INSN_DELETED)
(note 4 1 2 2 [bb 2] NOTE_INSN_BASIC_BLOCK)
(insn 2 4 3 2 (set (reg/v:DI 135 [ a ])
        (reg:DI 10 a0 [ a ])) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":11:1 -1
     (nil))
(note 3 2 6 2 NOTE_INSN_FUNCTION_BEG)
(insn 6 3 10 2 (set (reg:DI 134 [ <retval> ])
        (reg/v:DI 135 [ a ])) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":12:10 discrim 1 -1
     (nil))
(insn 10 6 11 2 (set (reg/i:DI 10 a0)
        (reg:DI 134 [ <retval> ])) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":13:1 -1
     (nil))
(insn 11 10 0 2 (use (reg/i:DI 10 a0)) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":13:1 -1
     (nil))
