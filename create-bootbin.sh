#!/bin/bash

BOOT_GEN="/opt/Xilinx/SDK/2014.1/bin/bootgen"
FPGA_IMAGE="z4e_bringup_synth.bit"
FSBL_IMAGE="FSBL_NM-ZE7000.elf"
UBOOT_IMAGE="u-boot.elf"
BOOT_BIF="ze7000_boot.bif"
OUTPUT_BIN="boot.bin"

createBootBin()
{
    $BOOT_GEN -image $BOOT_BIF -o i $OUTPUT_BIN -w on
}

createBifFile()
{
    echo "the_ROM_image:" > $BOOT_BIF
    echo "{" >> $BOOT_BIF
    echo -e "\t[bootloader]$FSBL_IMAGE" >> $BOOT_BIF
    echo -e "\t$FPGA_IMAGE" >> $BOOT_BIF
    echo -e "\t$UBOOT_IMAGE" >> $BOOT_BIF
    echo "}" >> $BOOT_BIF
    echo "" >> $BOOT_BIF
}

usage()
{
    echo "create-bootbin.sh"
}

exitScript()
{
    exit $1
}

createBifFile
createBootBin

exitScript 0
