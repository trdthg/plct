/* { dg-do compile } */
/* { dg-options "-march=rv64g_zacas -mabi=lp64d" } */

// __int128 rd = 0;
// __int128 rs2 = 1;

// void foo1()
// {
//     void *p = &rs1;
//     return __builtin_riscv_amocas128(rd, rs2, p);
// }

// void foo2(long long rd, long long rs2, long long *rs1)
// {
//     __builtin_riscv_amocas_test1(rd, rs2, 0);
//     __builtin_riscv_amocas_test1(rd, rs2, &var);
//     __builtin_riscv_amocas_test1(rd, rs2, (void*)0x111);

//     __builtin_riscv_amocas_test1(rd, rs2, rs1);
// }

// void foo3()
// {
//     __builtin_riscv_amocas_test2(rs2, rs1, 1);
// }


void foo3()
{
    void *var_p = (void *)0x3;
    __builtin_riscv_amocas_test1(
        1,
        2,
        var_p);
}

/* { dg-final { scan-assembler-times "amocas.q" 1 } } */