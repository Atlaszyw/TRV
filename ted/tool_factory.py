import logging
from pathlib import Path

from util.util_cmd import execute_command
from util.util_path import path_parse

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

class Node:
    """表示工作流中的一个节点"""

    def __init__(self, name: str, command: list[str], dependencies=None):
        self.name = name
        self.command = command
        self.dependencies = dependencies or []
        self.executed = False

    def run(self, cwd: str):
        """执行节点并处理依赖项"""
        for dep in self.dependencies:
            if not dep.executed:
                dep.run(cwd)

        logging.info(f"Executing {self.name}: {' '.join(self.command)}")
        execute_command(self.command, Path(cwd) / f"{self.name}.log")
        self.executed = True


class Workflow:
    """管理工作流中的所有节点"""

    def __init__(self, config):
        self.config = config
        self.nodes = {}

    def add_node(self, node: Node):
        self.nodes[node.name] = node

    def run(self, start_node_name: str):
        start_node = self.nodes.get(start_node_name)
        if start_node:
            start_node.run(self.config["target"]["work_dir"])


class ToolFactory:
    """工具工厂，用于创建适用于指定仿真器的节点"""

    @staticmethod
    def create_compile_node(config, design_lib: list[str], tool: str):
        if tool == "vcs":
            return ToolFactory._create_vcs_compile_node(config, design_lib)
        elif tool == "verilator":
            return ToolFactory._create_verilator_compile_node(config, design_lib)
        else:
            raise ValueError(f"Unsupported tool: {tool}")

    @staticmethod
    def create_elaborate_node(config, design_lib, tool: str):
        if tool == "vcs":
            return ToolFactory._create_vcs_elaborate_node(config, design_lib)
        elif tool == "verilator":
            return ToolFactory._create_verilator_elaborate_node(config)
        else:
            raise ValueError(f"Unsupported tool: {tool}")

    @staticmethod
    def create_simulate_node(config, tool: str):
        if tool == "vcs":
            return ToolFactory._create_vcs_simulate_node(config)
        elif tool == "verilator":
            return ToolFactory._create_verilator_simulate_node(config)
        else:
            raise ValueError(f"Unsupported tool: {tool}")

    @staticmethod
    def _create_vcs_compile_node(config, design_lib: list[str]):
        macros = config["design"]["macros"]
        incdirs = path_parse(config["design"]["inc_dirs"])
        extlibs = path_parse(config["design"]["ext_lib"])
        vlogan_opts = config["target"]["tools"]["vcs"]["vlogan_args"]
        v_filelist = path_parse(config["design"]["filelists"]["v"])
        sv_filelist = path_parse(config["design"]["filelists"]["sv"])
        pvalues = config["design"]["param"]

        write_file_list("verilog.f", macros, incdirs, extlibs, pvalues, v_filelist)
        write_file_list("sverilog.f", macros, incdirs, extlibs, pvalues, sv_filelist)

        vlogan_cmd = [
            "vlogan",
            "-work",
            design_lib[0],
            f'-timescale={config["target"]["tools"]["vcs"]["timescale"]}',
            "-assert",
            "svaext",
            "-sverilog",
            "-file",
            "verilog.f",
        ] + vlogan_opts
        svlogan_cmd = [
            "vlogan",
            "-work",
            design_lib[0],
            f'-timescale={config["target"]["tools"]["vcs"]["timescale"]}',
            "-assert",
            "svaext",
            "-sverilog",
            "-file",
            "sverilog.f",
        ] + vlogan_opts

        return Node("compile", [vlogan_cmd, svlogan_cmd])

    @staticmethod
    def _create_verilator_compile_node(config, design_lib: list[str]):
        verilator_args = config["target"]["tools"]["verilator"]["verilator_args"]
        v_filelist = path_parse(config["design"]["filelists"]["v"])
        sv_filelist = path_parse(config["design"]["filelists"]["sv"])
        top_module = config["design"]["top"]

        command = (
            [
                "verilator",
                "--top-module",
                top_module,
                "-I" + ":".join(path_parse(config["design"]["inc_dirs"])),
                "-o",
                "simv",
            ]
            + verilator_args
            + v_filelist
            + sv_filelist
        )

        return Node("compile", command)

    @staticmethod
    def _create_vcs_elaborate_node(config, design_lib):
        vcs_elab_opts = config["target"]["tools"]["vcs"]["vcs_args"]
        command = [
            "vcs",
            f'-timescale={config["target"]["tools"]["vcs"]["timescale"]}',
            f'{design_lib[0]}.{config["design"]["top"]}',
            f"{design_lib[0]}.glbl",
            "-o",
            "fpga_top_simv",
        ] + vcs_elab_opts
        return Node("elaborate", command)

    @staticmethod
    def _create_verilator_elaborate_node(config):
        return Node(
            "elaborate", ["make", "-j", "-C", "obj_dir", "-f", "Vtop.mk", "Vtop"]
        )

    @staticmethod
    def _create_vcs_simulate_node(config):
        vcs_sim_opts = config["target"]["tools"]["vcs"]["sim_args"]
        command = ["./fpga_top_simv"] + vcs_sim_opts
        return Node("simulate", command)

    @staticmethod
    def _create_verilator_simulate_node(config):
        sim_opts = config["target"]["tools"]["verilator"]["sim_args"]
        command = ["./simv"] + sim_opts
        return Node("simulate", command)
