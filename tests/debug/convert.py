import argparse
from pathlib import Path


def convert_to_vmem(input_file_path, output_dir):
    # Convert input paths to Path objects
    input_file_path = Path(input_file_path)
    output_dir = Path(output_dir)

    # Ensure the output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Read the input file
    content = input_file_path.read_text().strip().split("\n")

    # Prepare the output file path
    output_file_path = output_dir / (input_file_path.stem + ".vmem")

    # Convert each line from binary to hexadecimal and format for .vmem
    hex_lines = []
    address = 0
    for line in content:
        hex_value = hex(int(line, 2))[2:].zfill(
            8
        )  # Pad the hex value to ensure it has 8 characters
        hex_lines.append(f"@{address:04x} {hex_value}")
        address += 1

    # Write the .vmem file
    output_file_path.write_text("\n".join(hex_lines))

    print(f"Conversion complete. Output file: {output_file_path}")


def bin_to_verilog_mem_enhanced(
    bin_file_path,
    verilog_mem_file_path,
    byte_swap=False,
    offset=0x00000000,
    bytes_per_address=4,
    address_per_line=1,
    fill=0x00,
):
    block_size = bytes_per_address
    if address_per_line < 1:
        raise ValueError("blocks_per_line must be at least 1")
    addr = offset

    with open(bin_file_path, "rb") as bin_file, open(
        verilog_mem_file_path, "w"
    ) as mem_file:
        block = bin_file.read(block_size)
        while block:
            if len(block) < block_size:
                block += bytes([fill] * (block_size - len(block)))

            if byte_swap and block_size > 1:
                block = block[::-1]

            block_hex_str = "".join(f"{byte:02x}" for byte in block)
            if addr % address_per_line == 0:
                if addr != offset:  # Avoid new line at the beginning
                    mem_file.write("\n")
                mem_file.write(f"@{addr:08x} ")
            mem_file.write(block_hex_str + " ")
            addr += 1
            block = bin_file.read(block_size)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Convert a binary file to a Verilog memory file."
    )
    parser.add_argument("bin_file_path", help="Path to the input binary file.")
    parser.add_argument(
        "verilog_mem_file_path", help="Path to the output Verilog memory file."
    )
    parser.add_argument(
        "--byte_swap", action="store_true", help="Enable byte swapping."
    )
    parser.add_argument(
        "--offset",
        type=lambda x: int(x, 0),
        default=0x00000000,
        help="Memory offset in the output file (in hexadecimal).",
    )
    parser.add_argument(
        "--bytes_per_address",
        type=int,
        default=4,
        help="Number of bytes per memory address.",
    )
    parser.add_argument(
        "--address_per_line",
        type=int,
        default=1,
        help="Number of blocks per line in the output file.",
    )
    parser.add_argument(
        "--fill",
        type=lambda x: int(x, 0),
        default=0x00,
        help="Fill value for the last block (in hexadecimal).",
    )

    args = parser.parse_args()

    bin_to_verilog_mem_enhanced(
        args.bin_file_path,
        args.verilog_mem_file_path,
        args.byte_swap,
        args.offset,
        args.bytes_per_address,
        args.address_per_line,
        args.fill,
    )
    print(
        f"Conversion completed. Output file is located at: {args.verilog_mem_file_path}"
    )
