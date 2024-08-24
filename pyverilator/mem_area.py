from pathlib import Path

from dpi import libdpi
from veri_types import svBitVecVal

SV_MEM_WIDTH_BITS = 312


class MemArea:
    def __init__(self, scope: str, num_words: int, width_byte: int) -> None:
        self._scope = scope
        self._num_words = num_words
        self._width_byte = width_byte

    @property
    def scope(self):
        return self._scope

    @property
    def num_words(self):
        return self._num_words

    @property
    def width_byte(self):
        return self._width_byte

    @property
    def num_bytes(self):
        return self._num_words * self._width_byte

    @property
    def width(self):
        return self._width_byte * 8

    def load_vmem(self, path: Path):
        # Implementation of the load_vmem method (omitted for brevity)
        libdpi.simutil_memload(str(path).encode("ascii"))

    def read_to_minibuf(self, minibuf: list[int], phys_addr: int) -> list[int]:
        # Convert list to ctypes array
        buf = (svBitVecVal * len(minibuf))()
        if not libdpi.simutil_get_mem(phys_addr, buf):
            raise RuntimeError(
                f"Could not read memory word at physical index 0x{phys_addr:x}."
            )
        return list(buf)

    def write_from_minibuf(self, phys_addr: int, minibuf: list[int], dst_word: int):
        buf = (svBitVecVal * len(minibuf))(*minibuf)
        if not libdpi.simutil_set_mem(phys_addr, buf):
            raise RuntimeError(
                f"Could not set memory at byte offset 0x{dst_word * self.width_byte:x}."
            )
        return
