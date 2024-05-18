# global env
fsdbDumpfile "./tb_top.fsdb"
fsdbDumpvars 0 "tb" +all
run 1200000ns
exit
