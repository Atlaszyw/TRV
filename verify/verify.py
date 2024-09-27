import ctypes

import veri_types as vtype

# 加载动态库
lib = ctypes.CDLL('./libTRV.so')

# 定义函数的参数类型和返回类型
# 定义函数的参数和返回类型
lib.init_trv.argtypes = []
lib.init_trv.restype = None

lib.set_scope.argtypes = [ctypes.c_char_p]
lib.set_scope.restype = None

lib.eval_trv.argtypes = []
lib.eval_trv.restype = None

lib.set_clk_i.argtypes = [vtype.svBit]
lib.set_clk_i.restype = None

lib.set_rst_ni.argtypes = [vtype.svBit]
lib.set_rst_ni.restype = None

lib.get_success.argtypes = []
lib.get_success.restype = vtype.svBit

lib.get_current_time.argtypes = []
lib.get_current_time.restype = ctypes.c_uint64

lib.load_memory.argtypes = [ctypes.c_char_p]
lib.load_memory.restype = None

lib.get_memory.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_uint32)]
lib.get_memory.restype = ctypes.c_int

lib.set_memory.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_uint32)]
lib.set_memory.restype = None

lib.get_debug_info.argtypes = [ctypes.c_char_p, ctypes.c_size_t]
lib.get_debug_info.restype = None

lib.cleanup_trv.argtypes = []
lib.cleanup_trv.restype = None
# 准备命令行参数

# 初始化
lib.init_trv()

# 定义内存案例
mem_cases = [
    b"/home/main/Projects/tinyriscv/tb/mul.mif",
    b"/home/main/Projects/tinyriscv/tb/mulhu.mif",
    b"/home/main/Projects/tinyriscv/tb/lw.mif",
]
print("begin")
# 运行模拟
for mem_case in mem_cases:
    lib.set_scope(b"TOP.tinyriscv_soc_top.u_L1")
    lib.load_mem(mem_case)
    lib.set_scope(b"TOP.tinyriscv_soc_top.u_ram")
    lib.load_mem(mem_case)
    lib.set_clk(0)
    lib.set_rst(1)
    lib.run_simulation()
    while lib.get_time() < 10000:
        lib.set_clk(lib.get_clk() ^ 1)
        if lib.get_time() > 1 and lib.get_time() < 200:
            lib.set_rst(0)
        else:
            lib.set_rst(1)

        lib.eval_trv()

    success = lib.get_success()
    if success == 0:
        print(f"Test case {mem_case.decode()} is successful")

    # 延迟，模拟时间的推移

# 结束处理
lib.finalize()
lib.cleanup()
