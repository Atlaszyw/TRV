#include "dev_access.h"
#include <stdint.h>

#define UART_BASE    0x30000000
#define UART_RE      ( UART_BASE + 0x00 )
#define UART_STATUS  ( UART_BASE + 0x04 )
#define UART_RX_DATA ( UART_BASE + 0x10 )

#define UART_RE_ENABLE_MASK 0x2    // Control bit [1] for enabling read
#define DATA_BUFFER_SIZE    35
#define PAYLOAD_SIZE        33
#define CRC_SIZE            2
#define FILE_SIZE_INDEX     25

typedef void ( *jump_to_address_t )( void );

uint16_t calc_crc16( uint8_t* data, uint8_t length )
{
    uint16_t crc = 0xFFFF;
    for ( uint8_t i = 0; i < length; i++ )
    {
        crc ^= data[i];
        for ( uint8_t j = 0; j < 8; j++ )
        {
            if ( crc & 1 )
            {
                crc >>= 1;
                crc ^= 0xA001;
            }
            else
            {
                crc >>= 1;
            }
        }
    }
    return crc;
}

int main( void )
{
    uint8_t  data_buffer[DATA_BUFFER_SIZE];
    uint32_t package_num = 0xFFFFFFFF, current_package_num = 0, rom_counter = 0;

    DEV_WRITE( UART_RE, UART_RE_ENABLE_MASK );
    uint8_t data_length = 0;
    uint8_t first;

    while ( current_package_num <= package_num )
    {
        // Polling status register until data is ready
        while ( !( DEV_READ( UART_STATUS ) & UART_RE_ENABLE_MASK ) )
            ;

        // Read data from UART
        uint8_t data = DEV_READ( UART_RX_DATA );

        // Assume the first byte of the received data is 0
        first = ( data == 0 );

        // Store data in buffer
        data_buffer[data_length++] = data;

        // When the buffer is full, process the package
        if ( data_length == DATA_BUFFER_SIZE )
        {
            uint16_t received_crc   = ( data_buffer[PAYLOAD_SIZE] << 8 ) | data_buffer[PAYLOAD_SIZE + 1];
            uint16_t calculated_crc = calc_crc16( data_buffer, PAYLOAD_SIZE );

            if ( received_crc == calculated_crc )
            {
                if ( first )
                {
                    package_num = ( data_buffer[FILE_SIZE_INDEX] << 24 ) |
                                  ( data_buffer[FILE_SIZE_INDEX + 1] << 16 ) |
                                  ( data_buffer[FILE_SIZE_INDEX + 2] << 8 ) |
                                  data_buffer[FILE_SIZE_INDEX + 3];
                }
                else
                {
                    for ( uint8_t i = 1; i < PAYLOAD_SIZE; i++ )
                    {
                        DEV_WRITE( rom_counter++, data_buffer[i] );
                    }
                    current_package_num++;
                }
            }
            data_length = 0;    // Reset buffer length for the next package
        }
    }
    // Define the function pointer to the target address
    jump_to_address_t jump_to_address = (jump_to_address_t)0x00000000;
    jump_to_address( );    // Jump to the target address
    return 0;
}
