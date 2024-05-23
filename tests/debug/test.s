# RISC-V加法测试程序
    .section .data
    .text
    .option  norvc;
    .globl   _start

_start:
# 初始化寄存器
    li       x5, 10     # 将寄存器x5初始化为10
    li       x6, 20     # 将寄存器x6初始化为20

# 执行加法运算
    add      x7, x5, x6 # 将x5和x6中的值相加，结果存入x7

end:
    j        end        # 无限循环，防止程序退出
