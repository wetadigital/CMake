# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file LICENSE.rst or https://cmake.org/licensing for details.


# support for the nasm assembler

set(CMAKE_ASM_NASM_SOURCE_FILE_EXTENSIONS nasm asm)

if(NOT CMAKE_ASM_NASM_OBJECT_FORMAT)
  if(WIN32)
    if(DEFINED CMAKE_C_SIZEOF_DATA_PTR AND CMAKE_C_SIZEOF_DATA_PTR EQUAL 8)
      set(CMAKE_ASM_NASM_OBJECT_FORMAT win64)
    elseif(DEFINED CMAKE_CXX_SIZEOF_DATA_PTR AND CMAKE_CXX_SIZEOF_DATA_PTR EQUAL 8)
      set(CMAKE_ASM_NASM_OBJECT_FORMAT win64)
    elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
      set(CMAKE_ASM_NASM_OBJECT_FORMAT win64)
    else()
      set(CMAKE_ASM_NASM_OBJECT_FORMAT win32)
    endif()
  elseif(APPLE)
    if(DEFINED CMAKE_C_SIZEOF_DATA_PTR AND CMAKE_C_SIZEOF_DATA_PTR EQUAL 8)
      set(CMAKE_ASM_NASM_OBJECT_FORMAT macho64)
    elseif(DEFINED CMAKE_CXX_SIZEOF_DATA_PTR AND CMAKE_CXX_SIZEOF_DATA_PTR EQUAL 8)
      set(CMAKE_ASM_NASM_OBJECT_FORMAT macho64)
    elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
      set(CMAKE_ASM_NASM_OBJECT_FORMAT macho64)
    else()
      set(CMAKE_ASM_NASM_OBJECT_FORMAT macho)
    endif()
  else()
    if(DEFINED CMAKE_C_SIZEOF_DATA_PTR AND CMAKE_C_SIZEOF_DATA_PTR EQUAL 8)
      set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
    elseif(DEFINED CMAKE_CXX_SIZEOF_DATA_PTR AND CMAKE_CXX_SIZEOF_DATA_PTR EQUAL 8)
      set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
    elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
      set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
    else()
      set(CMAKE_ASM_NASM_OBJECT_FORMAT elf)
    endif()
  endif()
endif()

if(NOT CMAKE_ASM_NASM_COMPILE_OBJECT)
  set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> <DEFINES> <INCLUDES> <FLAGS> -f ${CMAKE_ASM_NASM_OBJECT_FORMAT} -o <OBJECT> <SOURCE>")
endif()

if(NOT CMAKE_ASM_NASM_LINK_EXECUTABLE)
  set(CMAKE_ASM_NASM_LINK_EXECUTABLE
    "<CMAKE_LINKER> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
endif()

if(CMAKE_ASM_NASM_COMPILER_ID STREQUAL "NASM")
  set(CMAKE_DEPFILE_FLAGS_ASM_NASM "-MD <DEP_FILE> -MT <DEP_TARGET>")

  if((NOT DEFINED CMAKE_DEPENDS_USE_COMPILER OR CMAKE_DEPENDS_USE_COMPILER)
      AND CMAKE_GENERATOR MATCHES "Makefiles|WMake")
    # dependencies are computed by the compiler itself
    set(CMAKE_ASM_NASM_DEPFILE_FORMAT gcc)
    set(CMAKE_ASM_NASM_DEPENDS_USE_COMPILER TRUE)
  endif()
endif()

# Load the generic ASMInformation file:
set(ASM_DIALECT "_NASM")
include(CMakeASMInformation)
set(ASM_DIALECT)
