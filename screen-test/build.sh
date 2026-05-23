#!/bin/bash

mkdir -p bin
frost64-asm -p src/startup.asm -o bin/screen-test.bin -f binary
