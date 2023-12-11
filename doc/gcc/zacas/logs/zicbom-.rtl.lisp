
;; Function foo1 (foo1, funcdef_no=0, decl_uid=2293, cgraph_uid=1, symbol_order=1)


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
(insn 5 2 6 2 (set (reg:DI 135)
        (high:DI (symbol_ref:DI ("var") [flags 0x86]  <var_decl 0x7f261397fb40 var>))) "./gcc/gcc/testsuite/gcc.target/riscv/cmo-zicbom-1.c":9:5 -1
     (nil))
(insn 6 5 7 2 (set (reg:DI 134)
        (lo_sum:DI (reg:DI 135)
            (symbol_ref:DI ("var") [flags 0x86]  <var_decl 0x7f261397fb40 var>))) "./gcc/gcc/testsuite/gcc.target/riscv/cmo-zicbom-1.c":9:5 -1
     (expr_list:REG_EQUAL (symbol_ref:DI ("var") [flags 0x86]  <var_decl 0x7f261397fb40 var>)
        (nil)))
(insn 7 6 0 2 (unspec_volatile:DI [
            (reg:DI 134)
        ] UNSPECV_CLEAN) "./gcc/gcc/testsuite/gcc.target/riscv/cmo-zicbom-1.c":9:5 -1
     (nil))
