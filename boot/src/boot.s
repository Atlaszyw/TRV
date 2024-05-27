    .section .text
    # .option  norvc;
    .global  reset_handler
reset_handler:
    la       x2, stack
    j        main

    jal      x0, reset_handler

loop:
    j        loop
