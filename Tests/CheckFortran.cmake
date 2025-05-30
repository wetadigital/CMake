# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file LICENSE.rst or https://cmake.org/licensing for details.


if(NOT DEFINED CMAKE_Fortran_COMPILER)
  set(_desc "Looking for a Fortran compiler")
  message(STATUS ${_desc})
  file(REMOVE_RECURSE ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CheckFortran)
  file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CheckFortran/CMakeLists.txt"
    "cmake_minimum_required(VERSION 3.10)
project(CheckFortran Fortran)
file(WRITE \"\${CMAKE_CURRENT_BINARY_DIR}/result.cmake\"
  \"set(CMAKE_Fortran_COMPILER \\\"\${CMAKE_Fortran_COMPILER}\\\")\\n\"
  \"set(CMAKE_Fortran_COMPILER_ID \\\"\${CMAKE_Fortran_COMPILER_ID}\\\")\\n\"
  \"set(CMAKE_Fortran_FLAGS \\\"\${CMAKE_Fortran_FLAGS}\\\")\\n\"
  \"set(CMAKE_Fortran_COMPILER_SUPPORTS_F90 \\\"\${CMAKE_Fortran_COMPILER_SUPPORTS_F90}\\\")\\n\"
  )
")
  if(CMAKE_GENERATOR_INSTANCE)
    set(_D_CMAKE_GENERATOR_INSTANCE "-DCMAKE_GENERATOR_INSTANCE:INTERNAL=${CMAKE_GENERATOR_INSTANCE}")
  else()
    set(_D_CMAKE_GENERATOR_INSTANCE "")
  endif()
  execute_process(
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CheckFortran
    COMMAND ${CMAKE_COMMAND} . -G ${CMAKE_GENERATOR}
                               -A "${CMAKE_GENERATOR_PLATFORM}"
                               -T "${CMAKE_GENERATOR_TOOLSET}"
                               ${_D_CMAKE_GENERATOR_INSTANCE}
    TIMEOUT 60
    OUTPUT_VARIABLE output
    ERROR_VARIABLE output
    RESULT_VARIABLE result
    )
  include(${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/CheckFortran/result.cmake OPTIONAL)
  # FIXME: Replace with message(CONFIGURE_LOG) when CMake version is high enough.
  if(CMAKE_Fortran_COMPILER AND "${result}" STREQUAL "0")
    file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
      "${_desc} passed with the following output:\n"
      "${output}\n")
  else()
    set(CMAKE_Fortran_COMPILER NOTFOUND)
    file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
      "${_desc} failed with the following output:\n"
      "${output}\n")
  endif()
  message(STATUS "${_desc} - ${CMAKE_Fortran_COMPILER}")
  set(CMAKE_Fortran_COMPILER "${CMAKE_Fortran_COMPILER}" CACHE FILEPATH "Fortran compiler")
  mark_as_advanced(CMAKE_Fortran_COMPILER)
  set(CMAKE_Fortran_COMPILER_ID "${CMAKE_Fortran_COMPILER_ID}" CACHE STRING "Fortran compiler Id")
  mark_as_advanced(CMAKE_Fortran_COMPILER_ID)
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS}" CACHE STRING "Fortran flags")
  mark_as_advanced(CMAKE_Fortran_FLAGS)
  set(CMAKE_Fortran_COMPILER_SUPPORTS_F90 "${CMAKE_Fortran_COMPILER_SUPPORTS_F90}" CACHE BOOL "Fortran compiler supports F90")
  mark_as_advanced(CMAKE_Fortran_COMPILER_SUPPORTS_F90)
endif()
