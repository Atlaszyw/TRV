import logging
import shlex
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def execute_command(
    command: list[str],
    log_file: Path,
    timeout: int | None = None,
    print_to_console: bool = False,
) -> None:
    """
    Executes a given command and logs the output to a log file.

    Args:
        command (list[str]): The command to execute.
        log_file (Path): Path to the log file where the command's output will be stored.
        timeout (int | None): The maximum time in seconds to allow the command to run. Defaults to None.
        print_to_console (bool): If True, also print command output to the console. Defaults to False.

    The function captures both standard output and standard error. It also logs any
    errors encountered during the command execution.
    """
    start_time = datetime.now()
    logging.info(f"Executing command: {' '.join(command)}")
    logging.info(f"Command started at {start_time}")

    try:
        with open(log_file, "w") as log:
            if print_to_console:
                # Simultaneously write to log file and print to console
                process = subprocess.Popen(
                    command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
                )
                assert process.stdout is not None
                for line in iter(process.stdout.readline, ""):
                    sys.stdout.write(line)
                    log.write(line)
                process.stdout.close()
                result_code = process.wait(timeout=timeout)
            else:
                # Only write to log file
                result = subprocess.run(
                    command,
                    stdout=log,
                    stderr=subprocess.STDOUT,
                    text=True,
                    timeout=timeout,
                )
                result_code = result.returncode

        if result_code != 0:
            logging.error(f'Command "{command}" failed with return code {result_code}')
        else:
            logging.info(f'Command "{command}" completed successfully.')

    except subprocess.TimeoutExpired:
        logging.error(f'Command "{command}" timed out after {timeout} seconds.')
    except subprocess.CalledProcessError as e:
        logging.error(f'Command "{command}" failed with return code {e.returncode}')
    except FileNotFoundError:
        logging.error(f"Command not found: {command[0]}")
    except Exception as e:
        logging.error(f"Unexpected error: {e}")
    finally:
        end_time = datetime.now()
        logging.info(f"Command ended at {end_time}")
        logging.info(f"Total execution time: {end_time - start_time}")


def shpath_join(paths: list[Path], arg_prefix: str) -> str:
    """
    join paths into a single shlex formatted string
    :param paths: list of paths
    :param arg_prefix: prefix for each path
    :return: shlex formatted string
    """
    return shlex.join([f"{arg_prefix}{path}" for path in paths])
