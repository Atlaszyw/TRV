import ctypes

# Load the shared library
lib = ctypes.CDLL('./mylib.so')  # Adjust path as needed

# Define the C function prototype
lib.process_array.argtypes = [ctypes.POINTER(ctypes.c_int), ctypes.c_int]
lib.process_array.restype = None

# Python list
py_list = [1, 2, 3, 4, 5]

# Convert list to ctypes array
ArrayType = ctypes.c_int * len(py_list)  # Create a ctypes array type
c_array = ArrayType(*py_list)  # Initialize the ctypes array with the list elements

# Call the C function
lib.process_array(c_array, len(py_list))
