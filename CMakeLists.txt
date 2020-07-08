cmake_minimum_required(VERSION 2.8)

project(asm)

set(CMAKE_ASM_SOURCE_FILE_EXTENSIONS "asm")
enable_language(ASM)

set(CMAKE_ASM_COMPILE_OBJECT "nasm -f elf32 -g -F dwarf -o <OBJECT> <SOURCE>")

# set 32bit level for C-code
set(CMAKE_C_FLAGS "-m32")

# set C linker
set(CMAKE_ASM_LINK_EXECUTABLE "/usr/bin/gcc -m32 <OBJECTS> -o <TARGET>")

add_executable(simple_test hex_to_dec.asm main.c)
