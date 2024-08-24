import logging
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

from util.util_path import path_parse

# 配置日志记录
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class TedNode:
    """代表工作流中的一个步骤"""

    name: str
    command: str
    dependencies: list = field(default_factory=list)
    executed: bool = False

    def run(self, cwd: Path):
        """运行节点的命令，并检查依赖项是否已完成"""
        for dep in self.dependencies:
            if not dep.executed:
                dep.run(cwd)

        logger.info(f"Executing {self.name}: {self.command}")
        result = subprocess.run(self.command, shell=True, cwd=cwd)
        if result.returncode != 0:
            raise RuntimeError(f"Command {self.name} failed")

        self.executed = True

    def export_make(self, makefile_path: Path) -> None:
        pass

    def pre_run(self, cwd: Path) -> None:
        pass

    def post_run(self, cwd: Path) -> None:
        pass

    def execute(self, cwd: Path) -> None:
        self.pre_run(cwd)
        self.run(cwd)
        self.post_run(cwd)


class Teda:
    def __init__(self, config: dict) -> None:
        pass

    def export_make(self, makefile_path: Path) -> None:
        pass

    def build_node(self, config: dict) -> None:
        pass

    def parse_macro(self) -> None:
        pass

    def parse_file_list(self) -> None:
        pass

    def run(self) -> None:
        pass


class TedIPNode:
    def __init__(self, config: dict) -> None:
        self.v_filelist: list[Path] = path_parse(config["design"]["filelists"]["v"])
        self.sv_filelist: list[Path] = path_parse(config["design"]["filelists"]["sv"])
        # self.extlibs: list[Path] = path_parse(config["design"]["ext_libs"])
        self.pvalues: dict = config["design"]["param"]
        self.incdir: list[Path] = path_parse(config["design"]["inc_dirs"])
