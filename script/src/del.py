from pathlib import Path


def remove_duplicates_and_empty_dirs(a_folder: str, b_folder: str) -> None:
    a_folder_path = Path(a_folder)
    b_folder_path = Path(b_folder)

    # 删除重复文件
    for a_file in a_folder_path.rglob('*'):
        if a_file.is_file():
            b_file = b_folder_path / a_file.relative_to(a_folder_path)
            if b_file.exists():
                print(f'Removing: {a_file}')
                a_file.unlink()

    # 删除空文件夹
    for dir in list(a_folder_path.rglob('*'))[::-1]:  # 逆序是为了确保先删除子文件夹
        if dir.is_dir() and not any(dir.iterdir()):
            print(f'Removing empty directory: {dir}')
            dir.rmdir()


# 调用函数，A_folder 和 B_folder 需要替换成实际的路径
remove_duplicates_and_empty_dirs('/path/to/A_folder', '/path/to/B_folder')
