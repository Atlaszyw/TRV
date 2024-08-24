# workflow.py

import logging
from pathlib import Path

from ted.TedParser import toml_parse
from ted.tool_factory import Node, ToolFactory, Workflow
from vlnv import Vlnv

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

def run_workflow(step, tool):
    """根据命令行参数运行工作流"""
    config = toml_parse(Path("test/top.toml"))
    vlnv = Vlnv(config["VLNV"])
    dgn_lib = [vlnv.library_name]

    workflow = Workflow(config)

    compile_node = ToolFactory.create_compile_node(config, dgn_lib, tool)
    elaborate_node = ToolFactory.create_elaborate_node(config, dgn_lib, tool)
    simulate_node = ToolFactory.create_simulate_node(config, tool)

    workflow.add_node(compile_node)
    workflow.add_node(elaborate_node)
    workflow.add_node(simulate_node)

    if step == "compile":
        workflow.run("compile")
    elif step == "elaborate":
        workflow.run("elaborate")
    elif step == "simulate":
        workflow.run("simulate")
    elif step == "all":
        workflow.run("compile")
        workflow.run("elaborate")
        workflow.run("simulate")

def process_reset(reset_all):
    """根据命令行参数处理重置逻辑"""
    if reset_all:
        reset_node = Node("reset_run", ["reset_run"])
        reset_node.run()
        logging.info("Simulation run files deleted.")

if __name__ == "__main__":
    from cli import main
    main()
