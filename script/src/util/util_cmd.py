import logging
import shlex
import subprocess
import sys
from pathlib import Path


def execute_command(command: list[str], log_file: Path) -> None:
    """
    Executes a given command and logs the output to a log file.

    Args:
        command (list[str]): The command to execute.
        log_file (Path): Path to the log file where the command's output will be stored.

    The function captures both standard output and standard error. It also logs any
    errors encountered during the command execution.
    """
    try:
        with open(log_file, 'w') as log:
            # Capture both stdout and stderr
            result: subprocess.CompletedProcess[str] = subprocess.run(
                command, stdout=log, stderr=subprocess.STDOUT, text=True
            )

        if result.returncode != 0:
            logging.error(
                f'Command "{command}" failed with return code {result.returncode}'
            )
    except subprocess.SubprocessError as e:
        logging.error(f'Error executing command: {e}')
        sys.exit(1)
    except Exception as e:
        logging.error(f'Unexpected error: {e}')
        sys.exit(1)


def shpath_join(paths: list[Path], arg_prefix: str) -> str:
    """
    join paths into a single shlex formatted string
    :param paths: list of paths
    :param arg_prefix: prefix for each path
    :return: shlex formatted string
    """
    return shlex.join([f'{arg_prefix}{path}' for path in paths])
