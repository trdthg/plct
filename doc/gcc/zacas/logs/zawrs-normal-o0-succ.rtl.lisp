
;; Function foo (foo, funcdef_no=0, decl_uid=2293, cgraph_uid=1, symbol_order=0)


;; Generating RTL for gimple basic block 2

;; Generating RTL for gimple basic block 3


try_optimize_cfg iteration 1

Merging block 3 into block 2...
Merged blocks 2 and 3.
Merged 2 and 3 without moving.
Merging block 4 into block 2...
Merged blocks 2 and 4.
Merged 2 and 4 without moving.
Removing jump 12.
Merging block 5 into block 2...
Merged blocks 2 and 5.
Merged 2 and 5 without moving.


try_optimize_cfg iteration 2



;;
;; Full RTL generated for this function:
;;
(note 1 0 6 NOTE_INSN_DELETED)
(note 6 1 2 2 [bb 2] NOTE_INSN_BASIC_BLOCK)
; 参数: a
(insn 2 6 3 2 (set (reg:DI 136)
        (reg:DI 10 a0 [ a ])) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":11:1 -1
     (nil))
; 把 a 拷贝到 子寄存器
(insn 3 2 4 2 (set (reg:SI 137)
        (subreg:SI (reg:DI 136) 0)) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":11:1 -1
     (nil))
; 把 (栈指针向上 4) 设置为 (子寄存器)
(insn 4 3 5 2 (set (mem/c:SI (plus:DI (reg/f:DI 129 virtual-stack-vars)
                (const_int -4 [0xfffffffffffffffc])) [1 a+0 S4 A32])
        (reg:SI 137)) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":11:1 -1
     (nil))
(note 5 4 8 2 NOTE_INSN_FUNCTION_BEG)
; 函数, 启动!
; 把 (134) 设置为 (栈指针向上 4 的地址)
(insn 8 5 11 2 (set (reg:DI 134 [ _2 ])
        (sign_extend:DI (mem/c:SI (plus:DI (reg/f:DI 129 virtual-stack-vars)
                    (const_int -4 [0xfffffffffffffffc])) [1 a+0 S4 A32]))) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":12:10 -1
     (nil))
(insn 11 8 15 2 (set (reg:DI 135 [ <retval> ])
        (reg:DI 134 [ _2 ])) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":12:10 discrim 1 -1
     (nil))
(insn 15 11 16 2 (set (reg/i:DI 10 a0)
        (reg:DI 135 [ <retval> ])) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":13:1 -1
     (nil))
(insn 16 15 0 2 (use (reg/i:DI 10 a0)) "./gcc/gcc/testsuite/gcc.target/riscv/zawrs.c":13:1 -1
     (nil))
