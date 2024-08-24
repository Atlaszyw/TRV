import logging
from pathlib import Path
from typing import Dict, List

import toml

# 假设已经有一些通用的工具函数如 execute_command
from util.util_cmd import execute_command

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class TaskNode:
    """表示工作流中的一个任务节点"""

    def __init__(
        self, name: str, command: List[str], dependencies=None, script: List[str] = None
    ):
        self.name = name
        self.command = command
        self.script = script or []
        self.dependencies = dependencies or []
        self.executed = False

    def run(self, work_dir: Path) -> None:
        """递归执行节点及其依赖"""
        for dep in self.dependencies:
            if not dep.executed:
                dep.run(work_dir)

        log_file = work_dir / f"{self.name}.log"
        full_command = self.command + self.script
        logging.info(
            f"Executing task: {self.name} with command: {' '.join(full_command)}"
        )
        execute_command(full_command, log_file)
        self.executed = True


def load_workflow_from_toml(config_file: Path) -> Dict[str, TaskNode]:
    config = toml.load(config_file)

    tool_config = None
    for tool in config["target"]["tools"]:
        if tool["type"] == config["target"]["default"]:
            tool_config = tool
            break

    if not tool_config:
        raise ValueError("No matching tool configuration found.")

    flow = tool_config["flow"]
    flowstr = flow["flowstr"].split("->")

    task_nodes = {}

    for step in flowstr:
        step_config = flow.get(step)
        if not step_config:
            raise ValueError(f"Step {step} is not defined in the configuration.")

        node = TaskNode(
            name=step,
            command=step_config["command"],
            script=step_config.get("script", []),
        )
        task_nodes[step] = node

    # 设置依赖关系
    previous_node = None
    for step in flowstr:
        current_node = task_nodes[step]
        if previous_node:
            current_node.dependencies.append(previous_node)
        previous_node = current_node

    return task_nodes


def run_workflow(task_nodes: Dict[str, TaskNode], work_dir: Path):
    """运行工作流中的所有节点"""
    for node in task_nodes.values():
        if not node.executed:
            node.run(work_dir)


if __name__ == "__main__":
    config_file = Path("config.toml")
    work_dir = Path("build")
    task_nodes = load_workflow_from_toml(config_file)
    run_workflow(task_nodes, work_dir)
