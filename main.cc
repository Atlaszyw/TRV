// Verilated -*- C++ -*-
// DESCRIPTION: main() calling loop, created with Verilator --main

#include "Vtinyriscv_soc_top.h"
#include "svdpi.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cassert>
#include <cstdio>
#include <string>
#include <vector>

//======================

int main( int argc, char** argv, char** )
{
    // Setup context, defaults, and parse command line
    Verilated::debug( 0 );
    const std::unique_ptr<VerilatedContext> contextp{ new VerilatedContext };
    contextp->traceEverOn( true );
    contextp->commandArgs( argc, argv );

    // Construct the Verilated model, from Vtop.h generated from Verilating
    const std::unique_ptr<Vtinyriscv_soc_top> topp{ new Vtinyriscv_soc_top{ contextp.get( ) } };

    std::vector<std::string> memcases = {
        "/home/main/Projects/tinyriscv/tb/mul.mif",
        "/home/main/Projects/tinyriscv/tb/mulhu.mif",
        "/home/main/Projects/tinyriscv/tb/lw.mif",
    };

    printf( "time precision is %d\n", contextp->timeprecision( ) );
    printf( "event pending is %d\n", topp->eventsPending( ) );

    for ( const auto& memcase : memcases )
    {
        VerilatedVcdC* m_trace  = new VerilatedVcdC;
        std::string    vcd_file = "wave_" + memcase.substr( memcase.find_last_of( "/" ) + 1 ) + ".vcd";
        topp->trace( m_trace, 10 );
        m_trace->open( vcd_file.c_str( ) );

        svScope curr_scope = svGetScopeFromName( "TOP.tinyriscv_soc_top.u_L1" );
        assert( curr_scope );
        svSetScope( curr_scope );

        topp->simutil_memload( memcase.c_str( ) );

        curr_scope = svGetScopeFromName( "TOP.tinyriscv_soc_top.u_ram" );
        assert( curr_scope );
        svSetScope( curr_scope );

        topp->simutil_memload( memcase.c_str( ) );
        // Reset simulation time to zero
        contextp->time( 0 );

        topp->clk_i  = 0;
        topp->rst_ni = 1;

        // Simulate until $finish
        while ( contextp->time( ) < 10000 )
        {
            // Evaluate model
            topp->eval( );
            m_trace->dump( contextp->time( ) );
            // Advance time
            contextp->timeInc( 1 );

            topp->clk_i ^= 1;
            if ( contextp->time( ) > 1 && contextp->time( ) < 200 )
                topp->rst_ni = 0;
            else
                topp->rst_ni = 1;
        }

        if ( topp->succ == 0 )
            printf( "Test case %s is success\n", memcase.c_str( ) );

        m_trace->close( );
        delete m_trace;    // Clean up
    }

    // Execute 'final' processes
    topp->final( );

    // Print statistical summary report
    contextp->statsPrintSummary( );

    return 0;
}
