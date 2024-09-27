#include "TRV.h"
#include "verilated.h"
#include <cassert>
#include <cstring>

extern "C"
{
    TRV*              trv_instance = nullptr;
    VerilatedContext* contextp     = nullptr;
    svScope           scope;

    void set_scope( const char* scope_name )
    {
        scope = svGetScopeFromName( scope_name );
        assert( scope );
        svSetScope( scope );
    }


    // 初始化 TRV 实例
    void init_trv( )
    {
        Verilated::debug( 0 );
        contextp = new VerilatedContext;
        contextp->traceEverOn( true );
        trv_instance = new TRV( contextp );
    }

    // 评估 TRV 模型
    void eval_trv( )
    {
        assert( trv_instance != nullptr );
        trv_instance->eval( );
    }

    // 设置时钟信号
    void set_clk_i( uint8_t value )
    {
        assert( trv_instance != nullptr );
        trv_instance->clk_i = value;
    }

    // 设置复位信号
    void set_rst_ni( uint8_t value )
    {
        assert( trv_instance != nullptr );
        trv_instance->rst_ni = value;
    }

    // 获取成功状态
    uint8_t get_success( )
    {
        assert( trv_instance != nullptr );
        return trv_instance->succ;
    }

    // 获取当前的时钟周期
    uint64_t get_current_time( )
    {
        assert( trv_instance != nullptr );
        return contextp->time( );
    }

    // 加载内存数据
    void load_memory( const char* file )
    {
        assert( trv_instance != nullptr );
        TRV::simutil_memload( file );
    }

    // 获取指定内存地址的数据
    int get_memory( int index, svBitVecVal* val )
    {
        assert( trv_instance != nullptr );
        return TRV::simutil_get_mem( index, val );
    }

    // 设置指定内存地址的数据
    void set_memory( int index, const svBitVecVal* val )
    {
        assert( trv_instance != nullptr );
        TRV::simutil_set_mem( index, val );
    }

    // 获取调试信息
    void get_debug_info( char* buffer, size_t size )
    {
        assert( trv_instance != nullptr );
        snprintf( buffer, size, "Current Time: %lu\nSuccess: %d\n", get_current_time( ), get_success( ) );
    }

    // 清理 TRV 实例
    void cleanup_trv( )
    {
        if ( trv_instance )
        {
            trv_instance->final( );
            delete trv_instance;
            trv_instance = nullptr;
        }
        if ( contextp )
        {
            delete contextp;
            contextp = nullptr;
        }
    }
}
