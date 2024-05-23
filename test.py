"""
Serial Download Script for FPGA Development Board

Author: Blue Liang
Contact: liangkangnan@163.com
License: Apache License, Version 2.0
"""

import sys
from pathlib import Path

import serial

# Packet constants
ACK = bytes([0x6])
FIRST_PACKET_LEN = 35
OTHER_PACKET_LEN = 35
FILE_NAME_INDEX = 1
FILE_SIZE_INDEX = 25
FIRST_PACKET_CRC0_INDEX = 33
FIRST_PACKET_CRC1_INDEX = 34

serial_com = serial.Serial()


def serial_init(port):
    """
    Initialize the serial port.

    Args:
        port (str): Serial port identifier.

    Returns:
        bool: True if the port was opened successfully, False otherwise.
    """
    serial_com.port = port
    serial_com.baudrate = 115200
    serial_com.bytesize = serial.EIGHTBITS
    serial_com.parity = serial.PARITY_NONE
    serial_com.stopbits = serial.STOPBITS_ONE
    serial_com.xonxoff = False
    serial_com.rtscts = False
    serial_com.dsrdtr = False

    try:
        if not serial_com.is_open:
            serial_com.open()
        return serial_com.is_open
    except serial.SerialException as e:
        print(f"Serial initialization failed: {e}")
        return False


def serial_deinit():
    """
    Deinitialize the serial port.
    """
    if serial_com.is_open:
        serial_com.close()


def serial_write(data):
    """
    Write data to the serial port.

    Args:
        data (bytes): Data to write.

    Returns:
        int: Number of bytes written.
    """
    if serial_com.is_open:
        return serial_com.write(data)
    return 0


def serial_read(length, timeout=0):
    """
    Read data from the serial port.

    Args:
        length (int): Number of bytes to read.
        timeout (int, optional): Read timeout in seconds. Defaults to 0.

    Returns:
        bytes: Data read from the serial port.
    """
    serial_com.timeout = timeout
    if serial_com.is_open:
        return serial_com.read(length)
    return b""


def calc_crc16(data):
    """
    Calculate the CRC16 checksum.

    Args:
        data (bytes): Data for which the CRC is to be calculated.

    Returns:
        int: CRC16 checksum.
    """
    crc = 0xFFFF
    for pos in data:
        crc ^= pos
        for _ in range(8):
            if (crc & 1) != 0:
                crc >>= 1
                crc ^= 0xA001
            else:
                crc >>= 1
    return crc


def create_packet(packet_number, data, file_size=0):
    """
    Create a packet to be sent over the serial port.

    Args:
        packet_number (int): Packet number.
        data (bytes): Data to be included in the packet.
        file_size (int, optional): File size. Required for the first packet.

    Returns:
        list: Packet ready for transmission.
    """
    packet = [0] * FIRST_PACKET_LEN
    packet[0] = packet_number

    if packet_number == 0:
        filename_bytes = data.encode()
        packet[FILE_NAME_INDEX : FILE_NAME_INDEX + len(filename_bytes)] = filename_bytes
        packet[FILE_SIZE_INDEX] = (file_size >> 24) & 0xFF
        packet[FILE_SIZE_INDEX + 1] = (file_size >> 16) & 0xFF
        packet[FILE_SIZE_INDEX + 2] = (file_size >> 8) & 0xFF
        packet[FILE_SIZE_INDEX + 3] = file_size & 0xFF
        crc_data = packet[1:33]
    else:
        packet[1 : 1 + len(data)] = data
        crc_data = packet[1:33]

    crc = calc_crc16(crc_data)
    packet[FIRST_PACKET_CRC0_INDEX] = crc & 0xFF
    packet[FIRST_PACKET_CRC1_INDEX] = (crc >> 8) & 0xFF

    return packet


def send_file(filepath):
    """
    Send a file to the FPGA development board over the serial port.

    Args:
        filepath (str): Path to the file to be sent.
    """
    file_path = Path(filepath)
    file_size = file_path.stat().st_size
    print(f"File size: {file_size} bytes")
    file_basename = file_path.name
    print(f"File name: {file_basename}")
    total_packets = (file_size // 32) + 1
    print(f"Total {total_packets} packets to be sent")

    # Send the first packet with file name and size
    print("Sending packet #0")
    packet = create_packet(0, file_basename, file_size)
    serial_write(packet)

    # Send the rest of the packets with file data
    with file_path.open("rb") as bin_file:
        data: bytes = bin_file.read()
        for i in range(total_packets):
            print(f"Sending packet #{i + 1}")
            packet_data: bytes = data[i * 32 : (i + 1) * 32]
            packet: list[int] = create_packet(i + 1, packet_data)
            serial_write(packet)

    print("File sent successfully")


def convert_data_to_bin(data_filename):
    """
    Convert .data file to .bin file.

    Args:
        data_filename (str): Path to the .data file.
    """
    data_path = Path(data_filename)
    bin_path = data_path.with_suffix(".bin")

    with data_path.open("r") as infile, bin_path.open("wb") as outfile:
        for line in infile:
            for i in range(4):
                byte = int(line[2 * (3 - i) : 2 * (3 - i) + 2], 16)
                outfile.write(byte.to_bytes(1, "big"))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: python {sys.argv[0]} COMx <data file>")
    else:
        port = sys.argv[1]
        data_file = sys.argv[2]

        convert_data_to_bin(data_file)
        bin_file = data_file + ".bin"

        if serial_init(port):
            send_file(bin_file)
            serial_deinit()
        else:
            print("Serial initialization failed")
