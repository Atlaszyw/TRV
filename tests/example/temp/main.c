#include <stdint.h>

int main( )
{
    uint8_t Temperature;
    *(unsigned int*)0x30000000 = 1;    // 将uart设置到发送数据的模式
    for ( int i = 0; i < 0xff; ++i )
        ;
    while ( 1 )
    {
        asm volatile( ".insn i 0x2f, 1, %0, x0, 0" : "=r"( Temperature ) );

        *(unsigned int*)0x3000000c = Temperature;
        for ( int i = 0; i < 0xff; ++i )
            ;
    }


    return 0;
}
