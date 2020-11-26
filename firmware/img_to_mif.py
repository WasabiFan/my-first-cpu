#!/usr/bin/env python3

import sys

TOTAL_SIZE = 512

HEADER = f"""
WIDTH=32;
DEPTH={TOTAL_SIZE};

ADDRESS_RADIX=UNS;
DATA_RADIX=HEX;

CONTENT BEGIN
"""

FOOTER = "END;\n"

if __name__ == "__main__":
    _, start_address_str, input_filename, output_filename = sys.argv

    start_address = int(start_address_str, 0)
    if start_address % 4 != 0:
        raise RuntimeError("Start address must be word-aligned")

    word_index = start_address // 4

    with open(output_filename, "w") as outfile:
        outfile.write(HEADER)

        with open(input_filename, "rb") as infile:
            while word := infile.read(4):
                arr = bytearray(word)
                arr.reverse()
                outfile.write(f"    {word_index} : {arr.hex()};\n")
                word_index += 1
        
        outfile.write(f"    [{word_index}..{TOTAL_SIZE-1}] : 00000000;\n")
        outfile.write(FOOTER)
