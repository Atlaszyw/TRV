#ifndef DEV_ACCESS_H
#define DEV_ACCESS_H

#define DEV_WRITE( addr, val ) ( *( (volatile uint32_t*)( addr ) ) = val )
#define DEV_READ( addr )       ( *( (volatile uint32_t*)( addr ) ) )

#endif    // DEV_ACCESS_H
