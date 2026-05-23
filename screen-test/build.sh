#!/bin/bash

mkdir -p bin
../../Frost64/cmake-build-release/Assembler/Assembler -p src/startup.asm -o bin/screen-test.bin -f binary
