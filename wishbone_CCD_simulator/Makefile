#
# Main Makefile for the Armadeus FPGA Wishbone example
#

all:
	$(MAKE) -C vhdl all
	$(MAKE) -C test all
	$(MAKE) -C modules all

clean:
	$(MAKE) -C vhdl clean
	$(MAKE) -C test clean
	$(MAKE) -C modules clean

install:
	$(MAKE) -C vhdl install
	$(MAKE) -C modules install

