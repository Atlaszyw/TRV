// File: trv_wrapper.cpp

#include "TRV.h"
#include "svdpi.h"
#include "verilated.h"
#include <cassert>
#include <cstring>
#include <memory>

// A global pointer to TRV and VerilatedContext, so Python can interact with it
static std::unique_ptr<VerilatedContext> contextp;
static std::unique_ptr<TRV>              trvModel;

// Variable to hold the current scope
static svScope currScope = nullptr;

extern "C"
{
    // Function to initialize the TRV model
    void initialize_trv( const char* name )
    {
        contextp = std::make_unique<VerilatedContext>( );
        trvModel = std::make_unique<TRV>( contextp.get( ), name );
    }

    // Function to delete the TRV model and clean up
    void cleanup_trv( )
    {
        if ( trvModel )
        {
            trvModel->final( );    // Call final on the model
            trvModel.reset( );
        }
        if ( contextp )
        {
            contextp.reset( );
        }
    }

    // Function to set the scope
    void set_scope( const char* scopeName )
    {
        currScope = svGetScopeFromName( scopeName );
        assert( currScope && "Scope not found! Make sure the scope name is correct." );
        svSetScope( currScope );
    }

    // Function to load memory from a file using DPI
    void simutil_memload( const char* file )
    {
        if ( trvModel && currScope )
        {
            trvModel->simutil_memload( file );
        }
        else
        {
            fprintf( stderr,
                     "Error: Model not initialized or scope not set before calling simutil_memload.\n" );
        }
    }

    // Function to set clock input
    void set_clk_i( unsigned char value )
    {
        if ( trvModel )
        {
            trvModel->clk_i = value;
        }
    }

    // Function to set reset input
    void set_rst_ni( unsigned char value )
    {
        if ( trvModel )
        {
            trvModel->rst_ni = value;
        }
    }

    // Function to evaluate the model
    void eval_trv( )
    {
        if ( trvModel )
        {
            trvModel->eval( );
        }
    }

    // Function to get output signals
    unsigned char get_tx( )
    {
        if ( trvModel )
        {
            return trvModel->tx;
        }
        return 0;
    }

    unsigned char get_succ( )
    {
        if ( trvModel )
        {
            return trvModel->succ;
        }
        return 0;
    }

    // Function to advance simulation time
    void advance_time( uint64_t timeInc )
    {
        if ( contextp )
        {
            contextp->timeInc( timeInc );
        }
    }

    // Function to get the current simulation time
    uint64_t get_time( )
    {
        if ( contextp )
        {
            return contextp->time( );
        }
        return 0;
    }

}    // extern "C"
