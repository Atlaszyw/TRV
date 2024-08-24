import re
from pathlib import Path



if __name__ == "__main__":
    directory = Path(".")  # 替换为实际的文件夹路径
    search_key = "fpga_top:0.0.1"  # 替换为您要查找的字符串

    results = search_toml_files(directory, search_key)

    if results:
        print("匹配的文件路径如下：")
        for file in results:
            print(file)
    else:
        print("未找到匹配的文件。")
