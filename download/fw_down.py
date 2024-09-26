import struct
import time

import serial


# CRC16-CCITT Kermit implementation
def crc16(data: bytes) -> int:
    crc = 0x0000
    polynomial = 0x1021

    for byte in data:
        crc ^= (byte << 8)
        for _ in range(8):
            if (crc & 0x8000) != 0:
                crc = (crc << 1) ^ polynomial
            else:
                crc <<= 1
            crc &= 0xFFFF  # Ensure CRC remains 16-bit

    return crc

# 发送一块数据并接收ACK，支持校验失败时重发
def send_block_and_receive_ack(ser: serial.Serial, block_data: bytes, preamble: bytes, max_retries: int = 3):
    # 计算并附加CRC校验码
    crc_value = crc16(block_data)
    crc_bytes = struct.pack('>H', crc_value)  # 大端模式将CRC转换为2字节

    # 添加前导码和CRC校验码
    data_to_send = preamble + block_data + crc_bytes

    retries = 0
    while retries < max_retries:
        print(f"Sending {len(data_to_send)} bytes (including preamble and CRC), attempt {retries + 1}...")
        ser.write(data_to_send)

        # 等待ACK信号
        ack = ser.read(1)  # 假设ACK为1字节
        if ack == b'\x06':  # 假设ACK为0x06 (ACK ASCII code)
            print("ACK received, block sent successfully.")
            return True
        elif ack == b'\x15':  # 假设NAK为0x15 (NAK ASCII code for failure)
            print("NAK received, retrying...")
            retries += 1
            time.sleep(0.1)  # 重发间隔，避免过快发送
        else:
            print("Unexpected response or no response, retrying...")
            retries += 1
            time.sleep(0.1)  # 重发间隔

    print("Max retries reached, sending failed.")
    return False

def read_bin_file(file_path: str) -> bytes:
    with open(file_path, 'rb') as f:
        return f.read()

def main():
    # 初始化串口
    ser = serial.Serial('/dev/ttyUSB0', 115200, timeout=1)  # 请修改为你的串口设备名称和波特率
    ser.flush()

    # 读取bin文件
    bin_file_path = 'path_to_your_bin_file.bin'  # 替换为你的bin文件路径
    data = read_bin_file(bin_file_path)

    # 定义前导码 (假设是4字节前导码，示例为0xAA 0xBB 0xCC 0xDD)
    preamble = b'\xAA\xBB\xCC\xDD'

    # 分块发送数据，每32字节一块
    block_size = 32
    max_retries = 3  # 设置最大重发次数
    try:
        for i in range(0, len(data), block_size):
            block_data = data[i:i+block_size]
            # 发送每一块数据并等待ACK，若失败则重发
            if not send_block_and_receive_ack(ser, block_data, preamble, max_retries):
                print(f"Failed to send block starting at byte {i}.")
                break  # 可以根据需求选择继续重发或者终止传输
            time.sleep(0.1)  # 可根据需要设置发送间隔
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        ser.close()

if __name__ == "__main__":
    main()
