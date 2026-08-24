# intel-x86-matrix-processor

[![Architecture](https://img.shields.io/badge/Architecture-Intel%20x86%2016--bit-blue.svg)](https://en.wikipedia.org/wiki/x86)
[![Environment](https://img.shields.io/badge/Environment-DOSBox%20%2F%20MS--DOS-orange.svg)](https://www.dosbox.com/)
[![Assembler](https://img.shields.io/badge/Assembler-MASM-green.svg)](https://mremoteng.org/)

Program written in **Intel Assembly x86** developed for the **Computer Architecture and Organization I** course at UFRGS.

The project consists of loading, processing, displaying, and manipulating integer matrices stored in text files, supporting row-wise arithmetic operations, an undo history, and file saving.

## Summary
- [Author](#-author)
- [Features](#-features)
- [Supported Commands](#-supported-commands)
- [Input File Format](#-input-file-format)
- [Accepted File Example](#-accepted-file-example)


## Author:
Lara Moreira

## Features

- **Reading and validation**: Loads the matrix from the standard `MAT.TXT` file, checking the format's integrity and dimensions.
- **Dimension identification**: Detects the matrix dimension $N$ ($N$ rows by $N+1$ columns, where $2 \le N \le 7$).
- **Arithmetic operations**:
  - Row multiplication by a scalar (`MUL`).
  - Addition of two rows with replacement of the destination row (`ADD`).
  - Undo System (`UNDO`): Allows reverting the last change made to the matrix.
  - Export (`WRITE`): Writes the matrix's current state to the end of an output file specified by the user.
  - Text Mode Interface: Displays the formatted matrix with right alignment and spacing.

## Input Format (MAT.TXT)

The input file must follow these rules:
1. **Standard name**: `MAT.TXT`.
2. **Dimensions**: ($N$ rows and $N+1$) columns ($2 \le N \le 7$).
3. **Delimiter**: Semicolon character (`;`) between numbers.
4. **No Spaces**: No spaces, tabs, or additional invisible characters are allowed.
5. **Numeric Representation**: Signed 16-bit integers (in two's complement). Negative numbers have a `-` prefix.

### Example of `MAT.TXT` ($N = 3$)
```text
4;-2;1;3
2;1;-1;1
1;-1;3;8
