
void *var_p = (void *)0x3;

void foo3()
{
    __builtin_riscv_amocas_test1(
        1,
        2,
        var_p);
}