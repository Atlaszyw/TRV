import logging
import subprocess
from dataclasses import dataclass, field

import toml

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

    def run(self, cwd: str):
        """运行节点的命令，并检查依赖项是否已完成"""
        for dep in self.dependencies:
            if not dep.executed:
                dep.run(cwd)

        logger.info(f"Executing {self.name}: {self.command}")
        result = subprocess.run(self.command, shell=True, cwd=cwd)
        if result.returncode != 0:
            raise RuntimeError(f"Command {self.name} failed")

        self.executed = True

@dataclass
class VcsWorkflow:
    """管理整个工作流的类"""
    config: dict
    work_root: str = field(init=False)
    nodes: dict[str, TedNode] = field(default_factory=dict, init=False)

    def __post_init__(self):
        self.work_root = self.config['project']['work_root']
        self.build_graph()

    def build_graph(self):
        """根据配置文件创建工作流的节点图"""
        nodes_config = self.config['nodes']
        for node_name, node_info in nodes_config.items():
            command = node_info['command']
            dependencies = [self.nodes[dep] for dep in node_info.get('depends_on', [])]
            node = Node(name=node_name, command=command, dependencies=dependencies)
            self.nodes[node_name] = node

    def run(self):
        """运行整个工作流"""
        # 根据three_step选项决定最终的仿真节点依赖于哪个节点
        if self.config['flow_options'].get('three_step', False):
            self.nodes['simulate'].dependencies = [self.nodes['elaborate']]
        else:
            self.nodes['simulate'].dependencies = [self.nodes['compile']]

        # 运行最终的仿真节点，递归执行所有依赖节点
        self.nodes['simulate'].run(self.work_root)

def load_config(config_file: str) -> dict:
    """加载TOML配置文件"""
    with open(config_file, 'r') as f:
        return toml.load(f)

def main():
    config_file = 'workflow_config.toml'  # TOML 配置文件的路径
    config = load_config(config_file)

    vcs_workflow = VcsWorkflow(config)
    vcs_workflow.run()

if __name__ == "__main__":
    main()
