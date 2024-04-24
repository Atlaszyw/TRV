import logging
import os
from pathlib import Path

import click
from toml_parser import toml_parse
from util.util_cmd import execute_command
from util.util_path import delete_files_folders_by_patterns, path_parse
from vlnv import Vlnv

files_to_remove: list[str] = [
    r".*\.fsdb",
    r".*\.tmp$",
    r".*\.log$",
    r"Verdi.*",
    r".*vcs_compile_lib.*",
    r".*\.key$",
    r".*\.f$",
    r".*\.setup$",
    r".*novas.*",
    r".*\.daidir$",
    r".*simv",
    r".*build.*",
    r"64",
    r"csrc",
    r"vc_hdrs.h",
]

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


@click.group()
def cli():
    """Command line argument parser for the script."""
    pass


@click.command()
@click.option(
    "-step",
    type=click.Choice(["compile", "elaborate", "simulate", "all"]),
    default="all",
    help="Specify the step to execute.",
)
def run(step):
    """Run command with options."""
    init_lib(config, dgn_lib, Path(simlib_dir))
    if step == "compile":
        compile(config, dgn_lib, Path("compile.log"))
    elif step == "elaborate":
        elaborate(config, dgn_lib, Path("elaborate.log"))
    elif step == "simulate":
        sim(config, Path("simulate.log"))
    elif step == "all":
        compile(config, dgn_lib, Path("compile.log"))
        elaborate(config, dgn_lib, Path("elaborate.log"))
        sim(config, Path("simulate.log"))


@click.command()
@click.option("--reset_all", is_flag=True, help="Reset run switch.")
def process(reset_all):
    """Process command with exclusive options."""
    if reset_all:
        reset_run(files_to_remove)
        logging.info("Simulation run files deleted.")


cli.add_command(run)
cli.add_command(process)


def init_lib(config, design_libs: list[str], sim_lib_dir: Path):
    """
    Initializes the library with the given arguments and design libraries.

    Args:
        args: The arguments for initialization.
        design_libs: A list of design libraries.
        sim_lib_dir: The directory path for simulation libraries.

    Returns:
        None
    """
    file_path = Path("synopsys_sim.setup")
    lib_map_paths: list[str] = config["target"]["tools"]["vcs"]["lib_path"]

    with open(file_path, "w") as file:
        file.write("LIBRARY_SCAN=TRUE\n")
        for lib in design_libs:
            file.write(f"{lib}:{sim_lib_dir.resolve()}/{lib}\n")
        for lib_map_path in lib_map_paths:
            file.write(f"OTHERS={lib_map_path}/synopsys_sim.setup\n")

    # if sim_lib_dir.exists():
    #     shutil.rmtree(sim_lib_dir)
    for lib in design_libs:
        Path(f"./{sim_lib_dir}/{lib}").resolve().mkdir(parents=True, exist_ok=True)


def write_file_list(file_name, macros, incdirs, extlibs, pvalues, filelist):
    """
    Writes the compilation directives to a file.

    Args:
        file_name (str): The name of the file to write to.
        macros (list[str]): List of macro definitions.
        incdirs (list[Path]): List of include directories.
        extlibs (list[Path]): List of external libraries.
        pvalues (dict[str, str]): Parameter values.
        filelist (list[Path]): List of Verilog/SystemVerilog files.
    """
    with open(file_name, "w") as file:
        for macro in macros:
            file.write(f"+define+{macro}\n")
        file.write("\n")
        for incdir in incdirs:
            file.write(f"+incdir+{incdir}\n")
        file.write("\n")
        for extlib in extlibs:
            file.write(f"-y {extlib} +libext+.v+.sv+.svh\n")
        file.write("\n")
        for p, value in pvalues.items():
            file.write(f"-pvalue+{p}={value}\n")
        file.write("\n")
        for f in filelist:
            file.write(f"{f}\n")
        file.write("\n")


def compile(options, design_lib: list[str], log_file: Path):
    """
    Compile the Verilog files using the specified options and design library.

    Args:
        options (dict): The options for compilation.
        design_lib (str): The design library to compile the Verilog files into.
        log_file (Path): The file to log compilation output to.
    """
    log_file.touch(exist_ok=True)

    macros = options["design"]["macros"]
    build_dir = Path(os.path.expandvars(options["target"]["work_dir"])).resolve()
    incdirs = path_parse(options["design"]["inc_dirs"])
    vlogan_opts: list[str] = options["target"]["tools"]["vcs"]["vlogan_args"]
    extlibs = path_parse(options["design"]["ext_lib"])

    v_filelist = path_parse(options["design"]["filelists"]["v"])
    sv_filelist = path_parse(options["design"]["filelists"]["sv"])
    pvalues = options["design"]["param"]

    roms = path_parse(options["design"]["roms"])
    for rom in roms:
        source_rom_path = Path.cwd() / rom.name
        if source_rom_path.exists() or source_rom_path.is_symlink():
            source_rom_path.unlink(missing_ok=True)
        source_rom_path.symlink_to(rom)

    write_file_list("verilog.f", macros, incdirs, extlibs, pvalues, v_filelist)
    write_file_list("sverilog.f", macros, incdirs, extlibs, pvalues, sv_filelist)

    vlogan_cmd: list[str] = [
        "vlogan",
        "-work",
        design_lib[0],
        f'-timescale={options["target"]["tools"]["vcs"]["timescale"]}',
        "-assert",
        "svaext",
        "-sverilog",
        "-file",
        "verilog.f",
    ] + vlogan_opts
    svlogan_cmd: list[str] = [
        "vlogan",
        "-work",
        design_lib[0],
        f'-timescale={options["target"]["tools"]["vcs"]["timescale"]}',
        "-assert",
        "svaext",
        "-sverilog",
        "-file",
        "sverilog.f",
    ] + vlogan_opts

    for cmd in [vlogan_cmd, svlogan_cmd]:
        execute_command(cmd, log_file)


def elaborate(options, design_lib, log_file) -> None:
    vcs_elab_opts: list[str] = options["target"]["tools"]["vcs"]["vcs_args"]
    command = [
        "vcs",
        f'-timescale={options["target"]["tools"]["vcs"]["timescale"]}',
        f'{design_lib[0]}.{options["design"]["top"]}',
        f"{design_lib[0]}.glbl",
        "-o",
        "fpga_top_simv",
    ] + vcs_elab_opts
    execute_command(command, log_file)


def sim(options, log_file) -> None:
    vcs_sim_opts: list[str] = options["target"]["tools"]["vcs"]["sim_args"]
    command: list[str] = ["./fpga_top_simv"] + vcs_sim_opts
    execute_command(command, log_file)


def reset_run(files_to_remove: list[str]) -> None:
    """
    重置编译程序
    :param files_to_remove:
    """
    delete_files_folders_by_patterns(".", files_to_remove)


if __name__ == "__main__":
    config = toml_parse(Path("test/top.toml"))
    # Design libraries and simulation directory
    vlnv = Vlnv(config["VLNV"])
    dgn_lib: list[str] = [vlnv.library_name]
    simlib_dir = "vcs_compile_lib"
    cli()
