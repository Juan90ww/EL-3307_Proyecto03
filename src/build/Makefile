# FPGA GOWIN
BOARD  = tangnano9k
FAMILY = GW1N-9C
DEVICE = GW1NR-LV9QN88PC6/I5

# Nombre del proyecto
PROYECT = proyecto_03

# Archivos fuente de diseño
SOURCES := $(wildcard ../design/*.v ../design/*.sv)

# Archivo de constraints
CONSTRAINTS = ../constr/Modulo_Pines.cst

# Nombre del módulo top (sin extensión)
TOP_DESIGN = top
TOP_TB     = tb_registro

# Testbench por defecto (top-level)
TESTBENCH = ../sim/$(TOP_TB).sv

# Archivo de ondas VCD
VCD_FILE = tb_registro.vcd

# Simulación del top por defecto
test: $(SOURCES) $(TESTBENCH)
	@echo "Compilando testbench: $(TOP_TB)"
	@iverilog -g2012 -o $(PROYECT)_test.o -s $(TOP_TB) $(TESTBENCH) $(SOURCES)
	@echo "Ejecutando simulación..."
	@vvp $(PROYECT)_test.o

# Ver ondas con GTKWave
wv: $(VCD_FILE)
	@echo "Abriendo GTKWave..."
	gtkwave $(VCD_FILE) 

# Simulación individual por módulo
# Uso: make tb=tb_nombre test-single
tb ?= tb_registro

test-single:
	@echo "Simulando testbench individual: $(tb)"
	iverilog -g2012 -o $(tb).o -s $(tb) ../sim/$(tb).sv $(SOURCES)
	vvp $(tb).o
all: synth pnr bitstream load

# Síntesis con Yosys
synth: $(SOURCES)
	@echo "Ejecutando síntesis..."
	yosys -p "read_verilog -sv $(SOURCES); synth_gowin -top $(TOP_DESIGN) -json $(PROYECT).json" > synthesis_$(BOARD).log 2>&1
	@echo " Síntesis completada"

# Place & Route con nextpnr
pnr: $(PROYECT).json
	@echo "Ejecutando P&R..."
	nextpnr-gowin --json $(PROYECT).json --write $(PROYECT)_pnr.json --freq 27 --device $(DEVICE) --family $(FAMILY) --cst $(CONSTRAINTS) > pnr_$(BOARD).log 2>&1
	@echo "✔ P&R completado"

# Bitstream
bitstream: $(PROYECT)_pnr.json
	@echo "Generando bitstream $(PROYECT)_$(BOARD).fs"
	gowin_pack -d $(FAMILY) -o $(PROYECT)_$(BOARD).fs $(PROYECT)_pnr.json
	@echo "✔ Bitstream generado"

# Cargar en FPGA
load: $(PROYECT)_$(BOARD).fs
	@echo "Cargando en FPGA $(BOARD)..."
	openFPGALoader -b $(BOARD) $(PROYECT)_$(BOARD).fs
