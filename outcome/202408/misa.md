# misa 相关

## 总结

- misa 可选成为可写的，用以修改 base 和支持的 ISA 拓展
- 补充了 misa 上出现互相矛盾的值时的行为
- exts
  - misa 没有使用的位是 WARL
  - Base 被重命名为 MXL, 限制：SXLEN≥UXLEN, MXLEN 为 constant
  - misa.MXL: read-only
  - 拓展位是 WARL 的，可以包含可写的位，当重置时，需要包含最大的拓展集合，例如 I E 都可选时只选大的 I
  - 增加 misa.V 作为向量拓展启用状态
  - U S 分别对应 用户，Super 模式
  - X 对应 有非标准的拓展
  - B ext
    - 当 B = 1 时，支持 Zba, Zbb, Zbs
    - 当 B = 0 时，可能有一个或多个不被支持
  - E 是只读的，除非 misa 全是可读的 0
  - 如果 x 取决于 y，x 启用，y 禁用，则两个都禁

## 原文

20240213

- 不严格兼容
  - Redefined misa.MXL to be read-only, making MXLEN a constant
  - Added the constraint that SXLEN≥UXLEN.

- 兼容
  - Defined the misa.V field to reflect that the V extension has been implemented.

1.11

- Made the unused misa fields WARL, rather than WIRI.
- Specified the behavior of the misa and xepc registers in systems with variable IALIGN
- Specified the behavior of writing self-contradictory values to the misa register.

- 1.10
- An optional mechanism to change the base ISA used by supervisor and user modes has been added
to the mstatus CSR, and the field previously called Base in misa has been renamed to MXL for
consistency.

1.9.1

- Made misa optionally writable to support modifying base and supported ISA extensions. CSR
address of misa changed

1.0

- 0x301 MRW misa ISA and extensions

- The misa CSR is a WARL read-write register

- The Extensions field is a WARL field that can contain writable bits
where the implementation allows the supported ISA to be modified. At reset, the Extensions field shall
contain the maximal set of supported extensions, and "I" shall be selected over "E" if both are available.

- The "U" and "S" bits will be set if there is support for user and supervisor modes respectively.
- The "X" bit will be set if there are any non-standard extensions.
- When "B" bit is 1, the implementation supports the instructions provided by the Zba, Zbb, and Zbs
extensions. When "B" bit is 0, it indicates that the implementation may not support one or more of the
Zba, Zbb, or Zbs extensions.
- "E" bit is read-only. Unless misa is all read-only zero,

- 指令集启用
  - If an ISA feature x depends on an ISA feature y, then attempting to enable feature x but disable feature
y results in both features being disabled. For example, setting "F"=0 and "D"=1 results in both "F" and "D"
being cleared

- 注意 IALIGN
  - Writing misa may increase IALIGN, e.g., by disabling the "C" extension. If an instruction that would
write misa increases IALIGN, and the subsequent instruction’s address is not IALIGN-bit aligned, the
write to misa is suppressed, leaving misa unchanged.
