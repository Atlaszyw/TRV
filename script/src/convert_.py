#!/usr/bin/env python3
from pathlib import Path

import click


def convert_to_vmem(input_file_path, output_dir):
    input_file_path = Path(input_file_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    content = input_file_path.read_text().strip().split("\n")
    output_file_path = output_dir / (input_file_path.stem + ".vmem")

    hex_lines = []
    address = 0
    for line in content:
        hex_value = hex(int(line, 2))[2:].zfill(8)
        hex_lines.append(f"@{address:04x} {hex_value}")
        address += 1

    output_file_path.write_text("\n".join(hex_lines))
    click.echo(f"Conversion complete. Output file: {output_file_path}")


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
        raise ValueError("address_per_line must be at least 1")
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
                if addr != offset:
                    mem_file.write("\n")
                mem_file.write(f"@{addr:08x} ")
            mem_file.write(block_hex_str + " ")
            addr += 1
            block = bin_file.read(block_size)

    click.echo(
        f"Conversion completed. Output file is located at: {verilog_mem_file_path}"
    )


@click.command()
@click.argument("bin_file_path", type=click.Path(exists=True))
@click.argument("verilog_mem_file_path", type=click.Path())
@click.option("--byte-swap", is_flag=True, help="Enable byte swapping.")
@click.option(
    "--offset",
    default=0x00000000,
    help="Memory offset in the output file (in hexadecimal).",
    type=click.IntRange(min=0),
)
@click.option(
    "--bytes-per-address",
    default=4,
    help="Number of bytes per memory address.",
    type=int,
)
@click.option(
    "--address-per-line",
    default=1,
    help="Number of blocks per line in the output file.",
    type=int,
)
@click.option(
    "--fill",
    default=0x00,
    help="Fill value for the last block (in hexadecimal).",
    type=int,
)
def main(
    bin_file_path,
    verilog_mem_file_path,
    byte_swap,
    offset,
    bytes_per_address,
    address_per_line,
    fill,
):
    bin_to_verilog_mem_enhanced(
        bin_file_path,
        verilog_mem_file_path,
        byte_swap,
        offset,
        bytes_per_address,
        address_per_line,
        fill,
    )


if __name__ == "__main__":
    main()
