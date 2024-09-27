import ctypes

# 对应C语言中的各种基本类型
uint64_t = ctypes.c_uint64
uint32_t = ctypes.c_uint32
uint8_t = ctypes.c_uint8
int64_t = ctypes.c_int64
int32_t = ctypes.c_int32
int8_t = ctypes.c_int8

# 对应SystemVerilog的简单数据类型
svScalar = uint8_t  # 用于bit和logic标量
svBit = svScalar
svLogic = svScalar


class SVpiVecVal(ctypes.Structure):
    _fields_ = [("aval", uint32_t), ("bval", uint32_t)]


# SystemVerilog逻辑向量和位向量类型，可以使用相同的结构体
SVLogicVecVal = SVpiVecVal
svBitVecVal = uint32_t  # 直接使用uint32_t，因为它代表一个chunk of packed bit array


class SVpiTime(ctypes.Structure):
    _fields_ = [
        ("type", int32_t),
        ("high", uint32_t),
        ("low", uint32_t),
        ("real", ctypes.c_double),
    ]
