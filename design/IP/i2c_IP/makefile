# Define the name of the project
PROJECT_NAME = my_project

# Define the list of Verilog files
SRC_FILES = $(wildcard *.v) $(wildcard *.sv)

# Define the list of macro definitions
MACROS =

# Define the list of include directories
INC_DIRS =

# Define the list of external directories
EXT_DIRS =

# Define the src list file
LIST_FILE = $(CURDIR)/filelist.f
# LIST_FILE = $(CURDIR)/tb/list_o.f
# Define the VCS executable and options
VCS = vcs
VCS_FLAGS = -full64 \
			-debug_access+all -kdb \
			-P /home/soft/synopsys/verdi/verdi/P-2019.06-SP2/share/PLI/VCS/LINUX64/novas.tab \
			/home/soft/synopsys/verdi/verdi/P-2019.06-SP2/share/PLI/VCS/LINUX64/pli.a \
			-timescale=1ns/10ps \
			+vcs+lic+wait \
			$(foreach marco,$(MACROS),+define+$(marco)) \
			$(foreach incdir,$(INC_DIRS),+incdir+$(incdir)) \
			$(foreach filelist, $(LIST_FILE), -F $(filelist)) \
			$(foreach extlib, $(EXT_DIRS), -y $(extlib) +libext+.v+.sv) \
			-l $(SIM_DIR)/compile.log


# Define the name of the simulation executable
TCL_FILE = $(CURDIR)/script/dump_fsdb_vcs.tcl
# Define the dump fsdb file name

# Define the simulation options
SIM_DIR = $(CURDIR)/sim
SIM_EXE = $(SIM_DIR)/simv
SIM_OPTIONS = -ucli -i $(TCL_FILE) \
				+fsdb+autoflush \
			 	-l $(SIM_DIR)/sim.log

# Define the verdi executable and options
VERDI = verdi
VERDI_FLAGS = -ultra -full64 -nologo
export FSDB_FILE = $(SIM_DIR)/sim.fsdb
VERDI_OPTIONS = -ssf $(FSDB_FILE) -dbdir $(SIM_DIR)/simv.daidir

# Create the sim directory if it doesn't exist
$(shell mkdir -p $(SIM_DIR))

# Define the default target
.PHONY: build run wave
$(SIM_EXE): build
$(FSDB_FILE): run
# Compile the source files, testbench file, and link them into a simulation executable
build: $(SRC_FILES) $(LIST_FILE)
	@cd $(SIM_DIR) && $(VCS) $(VCS_FLAGS) -o $(SIM_EXE)

# Run the simulation and dump fsdb file
run: $(SIM_EXE)
	@cd $(SIM_DIR) && $(SIM_EXE) $(SIM_OPTIONS)

# Open waveform in Verdi
wave: $(FSDB_FILE)
	@cd $(SIM_DIR) && $(VERDI) $(VERDI_FLAGS) $(VERDI_OPTIONS)

# Clean the simulation files
clean:
	rm -rf $(SIM_DIR)
	clear
