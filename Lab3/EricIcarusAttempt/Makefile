# Directories
SRC_DIR := .
TB_DIR  := tb
BUILD_DIR := build

# Tools
IVERILOG := iverilog
VVP := vvp

# Source and testbench files
SRC_FILES := $(wildcard $(SRC_DIR)/*.v)
TB_FILES  := $(wildcard $(TB_DIR)/*.v)

# Default testbench
DEFAULT_TB := $(basename $(notdir $(firstword $(TB_FILES))))
TB ?= $(DEFAULT_TB)

# Build output
OUT := $(BUILD_DIR)/$(TB).out

# Compilation flags
IVERILOG_FLAGS := -Wall -g2012 -DSIMULATION
VVP_FLAGS :=

# ================================================================
# Targets
# ================================================================
.PHONY: all compile run list clean

all: run

# Ensure build directory exists
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Compile only
compile: $(BUILD_DIR)
	@echo "🛠  Compiling testbench $(TB).v ..."
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(OUT) $(SRC_FILES) $(TB_DIR)/$(TB).v
	@echo "✅ Build complete: $(OUT)"

# Run simulation
run: compile
	@echo "🚀 Running simulation: $(TB)"
	$(VVP) $(OUT) $(VVP_FLAGS)

# List available testbenches
list:
	@echo "Available testbenches:"
	@for tb in $(TB_FILES); do echo "  - $$(basename $$tb .v)"; done

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "✨ Clean done."
