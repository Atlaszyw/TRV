import ctypes

from veri_types import svBitVecVal

# 加载动态库
libdpi = ctypes.CDLL('./libdpi.so')  # 在Linux上
# libdpi = ctypes.CDLL('libdpi.dll')  # 在Windows上

# DPI函数声明
# mhpmcounter_get
libdpi.mhpmcounter_get.argtypes = [ctypes.c_int]
libdpi.mhpmcounter_get.restype = ctypes.c_ulonglong

# mhpmcounter_num
libdpi.mhpmcounter_num.argtypes = []
libdpi.mhpmcounter_num.restype = ctypes.c_uint


libdpi.simutil_get_mem.argtypes = [ctypes.c_int, svBitVecVal]
libdpi.simutil_get_mem.restype = ctypes.c_int

# simutil_get_scramble_key
libdpi.simutil_get_scramble_key.argtypes = [svBitVecVal]
libdpi.simutil_get_scramble_key.restype = ctypes.c_int

# simutil_get_scramble_nonce
libdpi.simutil_get_scramble_nonce.argtypes = [svBitVecVal]
libdpi.simutil_get_scramble_nonce.restype = ctypes.c_int

# simutil_memload
libdpi.simutil_memload.argtypes = [ctypes.c_char_p]
libdpi.simutil_memload.restype = None

# simutil_set_mem
libdpi.simutil_set_mem.argtypes = [ctypes.c_int, svBitVecVal]
libdpi.simutil_set_mem.restype = ctypes.c_int
