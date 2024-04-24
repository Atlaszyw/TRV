import os
import re
import shutil  # 用于删除文件夹及其所有内容
from pathlib import Path


def delete_files_folders_by_patterns(directory_path: str, patterns: list):
    """
    删除指定目录下，匹配给定模式列表的所有文件和文件夹。

    :param directory_path: 要遍历的目录路径。
    :param patterns: 正则表达式模式的列表，用于匹配文件和文件夹名称。
    """
    directory = Path(directory_path)
    regexes = [re.compile(pattern) for pattern in patterns]

    # 遍历目录中的所有项目（文件和文件夹）
    for path in directory.iterdir():
        # 检查项目名称是否匹配任意一个正则表达式模式
        if any(regex.match(path.name) for regex in regexes):
            # 尝试删除文件或文件夹
            try:
                if path.is_file():
                    path.unlink()
                    print(f'Deleted file: {path}')
                elif path.is_dir():
                    shutil.rmtree(path)
                    print(f'Deleted folder and its contents: {path}')
            except Exception as e:
                print(f'Error deleting {path}: {e}')


def path_parse(paths: list[str]) -> list[Path]:
    return [p for path in paths for p in _dir_parse(path)]


def _dir_parse(path: str) -> list[Path]:
    path = os.path.expandvars(path)

    return (
        [Path(path)]
        if path.endswith('...')
        else [Path(path)] + [p for p in Path(path[:-3]).rglob('*') if p.is_dir()]
    )
