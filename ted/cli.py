# cli.py

import click
from workflow import process_reset, run_workflow


@click.group()
def cli():
    """命令行参数解析器"""
    pass


@click.command()
@click.option(
    "-step",
    type=click.Choice(["compile", "elaborate", "simulate", "all"]),
    default="all",
    help="Specify the step to execute.",
)
@click.option(
    "-tool",
    type=click.Choice(["vcs", "verilator"]),
    default="vcs",
    help="Specify the tool to use.",
)
def run(step, tool):
    """运行命令行指定的步骤"""
    run_workflow(step, tool)


@click.command()
@click.option("--reset_all", is_flag=True, help="Reset run switch.")
def process(reset_all):
    """处理命令行选项"""
    process_reset(reset_all)


cli.add_command(run)
cli.add_command(process)


def main():
    cli()


if __name__ == "__main__":
    main()
