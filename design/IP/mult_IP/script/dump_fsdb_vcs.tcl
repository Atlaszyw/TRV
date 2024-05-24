# global env
fsdbDumpfile "./tb_top.fsdb"
fsdbDumpvars 0 "tb" +all
run 30000ns
exit
