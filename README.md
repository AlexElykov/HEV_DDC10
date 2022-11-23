DDC10 Module Firmware & Software for XENONnT

A. Elykov (alexey.elykov@physik.uni-freiburg.de)

## Description
Custom firmware for the DDC-10 based High Energy Veto module

## DDC10 FPGA:
This firmware was designed for the DDC10 Spartan 6 FPGA. However, in principle,
it could be ported to newer FPGAs models, used by similar CAEN devices. 

## Prerequisites
* Firmware:
    - Xilinx ISE 14.7
    - If any other environment is used Spartan 6 FPGA has to be supported

* Software:
    - These codes rely on very old libraries and unsupported uClinux kernel
    - Setup the needed enviro and libraries using the supplied images or use the
      small ZOTAC PC setup for this purpose. However, for any future application
      one must rewrite these to be compatible either with DDC10 ARM or some
      CAEN module.  
    - Compiled using the following gcc call:
    - bfin-linux-uclibc-gcc -Wall -o Initialize -mfdpic Initialize.c
   

## Content
* README.md (This file).
* /ddc10_software/
    - Initialize.c - Initialize the DDC10 firmware 
    - get_status.c - Read back the user supplied parameters
    - get_baseline.c - Recalcualte the current baseline values

* /ddc10_firmware/
    - /ipcore_dir - BRAM definition files
    - VHD firmware modules
    - VHD simple test bench example
    - hev_xenonnt.bin - compiled firmware file
    - user constraint file (ucf) - from Skutek
