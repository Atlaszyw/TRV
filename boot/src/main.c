#include "dev_access.h"
#include <stdint.h>

#define UART_BASE    0x30000000
#define UART_RE      ( UART_BASE + 0x00 )
#define UART_STATUS  ( UART_BASE + 0x04 )
#define UART_RX_DATA ( UART_BASE + 0x10 )
#define UART_TX_DATA ( UART_BASE + 0x08 )

#define UART_RE_ENABLE_MASK 0x2     // Control bit [1] for enabling read
#define UART_TX_READY_MASK  0x1     // Status bit [0] for UART transmit ready
#define ACK                 0x06    // Acknowledge byte
#define NAK                 0x15    // Not Acknowledge byte
#define DATA_BUFFER_SIZE    32      // 32-byte payload
#define PREAMBLE_SIZE       4       // 前导码大小
#define CRC_SIZE            2       // CRC 校验码大小
#define TOTAL_BUFFER_SIZE   ( DATA_BUFFER_SIZE + PREAMBLE_SIZE + CRC_SIZE )

typedef void ( *jump_to_address_t )( void );

// CRC16-CCITT Kermit implementation to match Python code
uint16_t crc16_ccitt_kermit( uint8_t* data, uint8_t length )
{
    uint16_t crc        = 0x0000;    // Initial value matches Python
    uint16_t polynomial = 0x1021;    // Polynomial used in Python

    for ( uint8_t i = 0; i < length; i++ )
    {
        crc ^= ( data[i] << 8 );    // Process each byte
        for ( uint8_t j = 0; j < 8; j++ )
        {
            if ( crc & 0x8000 )
            {
                crc = ( crc << 1 ) ^ polynomial;
            }
            else
            {
                crc <<= 1;
            }
        }
        crc &= 0xFFFF;    // Ensure CRC is 16-bit
    }

    return crc;
}

// 等待串口准备好发送
void uart_send_byte( uint8_t data )
{
    while ( !( DEV_READ( UART_STATUS ) & UART_TX_READY_MASK ) );
    DEV_WRITE( UART_TX_DATA, data );
}

// 等待串口准备好接收
uint8_t uart_receive_byte( )
{
    while ( !( DEV_READ( UART_STATUS ) & UART_RE_ENABLE_MASK ) );
    return DEV_READ( UART_RX_DATA );
}

int main( void )
{
    uint8_t  data_buffer[TOTAL_BUFFER_SIZE];
    uint32_t rom_counter = 0;

    // 启用 UART 接收
    DEV_WRITE( UART_RE, UART_RE_ENABLE_MASK );
    uint8_t data_length = 0;

    while ( 1 )
    {
        // 接收一个字节
        uint8_t data = uart_receive_byte( );

        // 存入数据缓冲区
        data_buffer[data_length++] = data;

        // 当接收到完整的数据包时，处理数据包
        if ( data_length == TOTAL_BUFFER_SIZE )
        {
            // 检查前导码
            if ( data_buffer[0] == 0xAA && data_buffer[1] == 0xBB && data_buffer[2] == 0xCC &&
                 data_buffer[3] == 0xDD )
            {
                // 计算 CRC
                uint16_t received_crc =
                    ( data_buffer[TOTAL_BUFFER_SIZE - 2] << 8 ) | data_buffer[TOTAL_BUFFER_SIZE - 1];
                uint16_t calculated_crc =
                    crc16_ccitt_kermit( data_buffer + PREAMBLE_SIZE, DATA_BUFFER_SIZE );

                if ( received_crc == calculated_crc )
                {
                    // 校验通过，写入有效负载数据
                    for ( uint8_t i = 0; i < DATA_BUFFER_SIZE; i++ )
                    {
                        DEV_WRITE( rom_counter++, data_buffer[PREAMBLE_SIZE + i] );
                    }

                    // 发送 ACK 确认
                    uart_send_byte( ACK );
                }
                else
                {
                    // CRC 校验失败，发送 NAK 请求重发
                    uart_send_byte( NAK );
                }
            }
            else
            {
                // 前导码不匹配，发送 NAK 请求重发
                uart_send_byte( NAK );
            }

            // 清空缓冲区，准备接收下一个包
            data_length = 0;
        }
    }

    // 定义函数指针，跳转到目标地址
    jump_to_address_t jump_to_address = (jump_to_address_t)0x00000000;
    jump_to_address( );    // 跳转到目标地址
    return 0;
}
