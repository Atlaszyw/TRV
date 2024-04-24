import logging
import subprocess
from pathlib import Path


class Tcmd:
    def __init__(self, name, cmd) -> None:
        self.name: str = name
        self.cmd: list[str] = cmd
        self.ret_code: int = 0
        self.log_path: Path = Path(f'./{self.name}.log')

    def execute_command(self, timeout=None, cwd=None, env=None):
        """
        Executes a given command and logs the output to a log file.

        Args:
            timeout (int): Timeout for the command execution in seconds.
            cwd (Path): The working directory for the command execution.
            env (dict): Environment variables for the command.

        Returns:
            str: The output of the command execution.
        """
        try:
            with open(self.log_path, 'a') as log:
                result = subprocess.run(
                    self.cmd,
                    stdout=log,
                    stderr=subprocess.STDOUT,
                    text=True,
                    timeout=timeout,
                    cwd=cwd,
                    env=env,
                )
                self.ret_code = result.returncode

            if self.ret_code != 0:
                logging.error(
                    f'Command "{self.cmd}" failed with return code {self.ret_code}'
                )
            else:
                logging.info(f'Command "{self.cmd}" executed successfully.')

        except subprocess.TimeoutExpired:
            logging.error(f'Command "{self.cmd}" timed out after {timeout} seconds.')
            self.ret_code = -1
        except Exception as e:
            logging.error(f'Error executing command "{self.cmd}": {e}')
            self.ret_code = -1


class Tstep:
    def __init__(self, step: list[str], workdir: Path, timescale: str) -> None:
        self.step = step
        self.workdir = workdir
        self.timescale = timescale

    @property
    def get_workdir(self) -> Path:
        return self.workdir
