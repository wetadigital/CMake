cmake_minimum_required(VERSION 3.10)
project(FindPackageCMakeTest)

# Protect tests from running inside the default install prefix.
set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/NotDefaultPrefix")

# Disable built-in search paths.
set(CMAKE_FIND_USE_PACKAGE_ROOT_PATH OFF)
set(CMAKE_FIND_USE_CMAKE_ENVIRONMENT_PATH OFF)
set(CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH OFF)
set(CMAKE_FIND_USE_INSTALL_PREFIX OFF)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})

find_package(ZLIB QUIET)

# Look for a package that has a find module and may be found.
find_package(OpenGL QUIET)

# Look for a package that has no find module and will not be found.
find_package(NotAPackage QUIET)

# Look for a package that has an advanced find module.
find_package(Boost QUIET)

add_executable(FindPackageCMakeTest FindPackageTest.cxx)

# test behavior of cmFindBase wrt. the CMAKE_PREFIX_PATH variable
# foo.h should be found in ${CMAKE_CURRENT_SOURCE_DIR}/include:

set(CMAKE_PREFIX_PATH /blub /blah "${CMAKE_CURRENT_SOURCE_DIR}")
find_path(FOO_DIR foo.h)

if(NOT FOO_DIR)
  message(FATAL_ERROR "Did not find foo.h which is in ${CMAKE_CURRENT_SOURCE_DIR}/include
  CMAKE_PREFIX_PATH = ${CMAKE_PREFIX_PATH}")
endif()

find_package(VersionTestA 1)
find_package(VersionTestB 1.2)
find_package(VersionTestC 1.2.3)
find_package(VersionTestD 1.2.3.4)


find_package(LotsOfComponents COMPONENTS AComp OPTIONAL_COMPONENTS BComp CComp)
if(NOT LOTSOFCOMPONENTS_FOUND)
  message(SEND_ERROR "LotsOfComponents not found !")
endif()

find_package(SomePackage)
if(NOT SomePackage_FOUND)
  message(SEND_ERROR "SomePackage not found !")
endif()
if(NOT SOMEPACKAGE_FOUND)
  message(SEND_ERROR "SomePackage compatibility name SOMEPACKAGE_FOUND not set!")
endif()

find_package(UpperCasePackage)
if(NOT UpperCasePackage_FOUND)
  message(SEND_ERROR "UpperCasePackage not found!")
endif()
if(NOT UPPERCASEPACKAGE_FOUND)
  message(SEND_ERROR "SomePackage compatibility name SOMEPACKAGE_FOUND not set!")
endif()

#-----------------------------------------------------------------------------
# Test system package registry if possible.
set(CMakeTestSystemPackage "")
if(WIN32 AND NOT CYGWIN)
  # Try writing a value to the system package registry.
  set(_data "${FindPackageCMakeTest_SOURCE_DIR}/SystemPackage")
  set(_key "HKLM\\Software\\Kitware\\CMake\\Packages\\CMakeTestSystemPackage")
  set(_file "${FindPackageCMakeTest_BINARY_DIR}/CMakeTestSystemPackage.data")
  file(WRITE ${_file} "${_data}\n")
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E md5sum ${_file}
    OUTPUT_VARIABLE _output ERROR_VARIABLE _error RESULT_VARIABLE _failed
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  string(REGEX REPLACE " .*" "" _value "${_output}")
  if(NOT _failed AND _value)
    execute_process(
      COMMAND reg add "${_key}" /v "${_value}" /t REG_SZ /d "${_data}" /f
      OUTPUT_VARIABLE _output ERROR_VARIABLE _output RESULT_VARIABLE _failed
      )
  endif()
  # If the above worked, add the rest of the test and a rule to
  # cleanup the value.
  if(NOT _failed)
    message(STATUS "HKLM is writable: enabling CMakeTestSystemPackage")
    set(CMakeTestSystemPackage_CLEANUP reg delete "${_key}" /v "${_value}" /f)
    set(CMakeTestSystemPackage CMakeTestSystemPackage)
  else()
    message(STATUS "HKLM is readonly: disabling CMakeTestSystemPackage")
  endif()
endif()

#-----------------------------------------------------------------------------

#set(CMAKE_FIND_DEBUG_MODE 1)

# For purposes of the test wipe out previous find results.
set(PACKAGES
  foo Foo Bar Blub TFramework Tframework TApp Tapp Special
  VersionedA VersionedB VersionedC VersionedD VersionedE
  VersionedF VersionedG VersionedH
  WrongA WrongB WrongC WrongD
  wibbleA wibbleB
  RecursiveA RecursiveB RecursiveC
  ArchA ArchB ArchC ArchD
  EnvA EnvB
  SetFoundTRUE SetFoundFALSE
  ${CMakeTestSystemPackage}
  )
foreach(p ${PACKAGES})
  set(${p}_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
endforeach()

# Enable framework and bundle searching.  Make sure bundles are found
# before unix-style packages.
set(CMAKE_FIND_FRAMEWORK LAST)
set(CMAKE_FIND_APPBUNDLE FIRST)

# Set the wrong answer for a find to make sure it re-finds.
set(VersionedA_DIR ${CMAKE_CURRENT_SOURCE_DIR}/lib/cmake/zot-4.0)

# Test that CMAKE_IGNORE_PATH can ignore the purposely bad package
# files in the lib/cmake/zot-3.1 directory.
set(CMAKE_IGNORE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/lib/cmake/zot-3.1)

# Look for packages with new-style signatures.
find_package(foo NO_MODULE)
find_package(Foo CONFIGS FooConfig.cmake)
find_package(Bar)
set(CMAKE_DISABLE_FIND_PACKAGE_Blub TRUE)
find_package(Blub NO_MODULE)
find_package(TFramework CONFIGS TFrameworkConfig.cmake)
find_package(Tframework)
find_package(TApp)
find_package(Tapp CONFIGS tapp-config.cmake)
find_package(Special NAMES Suffix SuffixTest PATH_SUFFIXES test)
find_package(VersionedA 2 NAMES zot)
find_package(VersionedB 3.1 EXACT NAMES zot)
find_package(VersionedC 4.0 EXACT NAMES zot)
find_package(VersionedD 1.1 EXACT NAMES Baz)
find_package(VersionedE 1.2 EXACT NAMES Baz)
find_package(VersionedF 1.3 EXACT NAMES Baz)
find_package(VersionedG 2.0 EXACT NAMES Baz)
find_package(VersionedH 2.1 EXACT NAMES Baz)


# Test Config files which set Xyz_FOUND themselves:
find_package(SetFoundTRUE NO_MODULE)
find_package(SetFoundFALSE NO_MODULE)

# Test wrong initial path when result is present.
set(WrongA_DIR "${VersionedD_DIR}")
find_package(WrongA 1.2 EXACT NAMES Baz)

# Test wrong initial cache entry of UNINITIALIZED type when result is present.
set(WrongB_DIR "${VersionedD_DIR}" CACHE UNINITIALIZED "Wrong Value" FORCE)
get_property(type CACHE WrongB_DIR PROPERTY TYPE)
find_package(WrongB 1.2 EXACT NAMES Baz)

# Test wrong initial path when result is missing.
set(WrongC_DIR "${VersionedD_DIR}")
find_package(WrongC 1.4 EXACT QUIET NAMES Baz)

# Test wrong initial cache entry of UNINITIALIZED type when result is missing.
set(WrongD_DIR "${VersionedD_DIR}" CACHE UNINITIALIZED "Wrong Value" FORCE)
get_property(type CACHE WrongD_DIR PROPERTY TYPE)
find_package(WrongD 1.4 EXACT QUIET NAMES Baz)

# HINTS should override the system but PATHS should not
list(INSERT CMAKE_SYSTEM_PREFIX_PATH 0 "${CMAKE_CURRENT_SOURCE_DIR}/A")
find_package(wibbleA NAMES wibble PATHS B)
find_package(wibbleB NAMES wibble HINTS B)

# Look for package with recursive find-modules.
find_package(RecursiveA COMPONENTS A)
find_package(RecursiveB 2)
find_package(RecursiveC 3.1 EXACT)

# Test architecture-specific search directories.
set(CMAKE_LIBRARY_ARCHITECTURE arch)
find_package(ArchA NAMES Bar)
find_package(ArchB NAMES Foo CONFIGS FooConfig.cmake)
find_package(ArchC 3.1 EXACT NAMES zot)
find_package(ArchD 4.0 EXACT NAMES zot)
unset(CMAKE_LIBRARY_ARCHITECTURE)

# Test find_package() with CMAKE_FIND_PACKAGE_RESOLVE_SYMLINKS enabled
if(UNIX
    AND NOT MSYS # FIXME: This works on CYGWIN but not on MSYS
    )
  # Create ./symlink pointing back here.
  execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink
      . "${CMAKE_CURRENT_SOURCE_DIR}/symlink")
  # Make find_package search through the symlink
  set(CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/symlink")

  # First, test the default behavior where symlinks are preserved.
  set(SetFoundResolved_DIR "")
  find_package(SetFoundResolved)
  # The result must preserve the /symlink/ path.
  set(SetFoundResolved_EXPECTED "${CMAKE_CURRENT_SOURCE_DIR}/symlink/cmake")
  if(NOT "${SetFoundResolved_DIR}" STREQUAL "${SetFoundResolved_EXPECTED}")
    message(SEND_ERROR "SetFoundResolved_DIR set by find_package() is set to\n  \"${SetFoundResolved_DIR}\"\nnot the expected\n  \"${SetFoundResolved_EXPECTED}\"")
  endif()

  # This part of the test only works if there are no symlinks in our path.
  get_filename_component(real_src_dir "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)
  if(real_src_dir STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    # Resolve symlinks when finding the package.
    set(CMAKE_FIND_PACKAGE_RESOLVE_SYMLINKS TRUE)
    set(SetFoundResolved_DIR "")
    find_package(SetFoundResolved)
    # ./symlink points back here so it should be gone when resolved.
    set(SetFoundResolved_EXPECTED "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
    if(NOT "${SetFoundResolved_DIR}" STREQUAL "${SetFoundResolved_EXPECTED}")
      message(SEND_ERROR "SetFoundResolved_DIR set by find_package() is set to\n  \"${SetFoundResolved_DIR}\"\nnot the expected\n  \"${SetFoundResolved_EXPECTED}\"")
    endif()
  endif()

  # Cleanup.
  unset(CMAKE_FIND_PACKAGE_RESOLVE_SYMLINKS)
  file(REMOVE "${CMAKE_CURRENT_SOURCE_DIR}/symlink")
endif()

# Test <PackageName>_DIR environment variable.
# We erase the main prefix path to ensure the env var is used.
set(CMAKE_PREFIX_PATH)
set(CMAKE_FIND_USE_CMAKE_ENVIRONMENT_PATH ON)
set(ENV{EnvA_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/lib/zot-3.1")
find_package(EnvA 3.1 EXACT QUIET NAMES zot) # Should Work
find_package(EnvB 3.1 EXACT QUIET NAMES zot) # Should Fail
set(CMAKE_FIND_USE_CMAKE_ENVIRONMENT_PATH OFF)

# Test system package registry if available.
if(CMakeTestSystemPackage)
  find_package(CMakeTestSystemPackage)
  execute_process(COMMAND ${CMakeTestSystemPackage_CLEANUP}
    OUTPUT_VARIABLE _output ERROR_VARIABLE _error)
endif()

# Expected locations at which packages should be found.
set(foo_EXPECTED "lib/foo-1.2/foo-config.cmake")
set(Foo_EXPECTED "lib/foo-1.2/CMake/FooConfig.cmake")
set(Bar_EXPECTED "lib/Bar/BarConfig.cmake")
set(Blub_MISSING "")
set(Special_EXPECTED "lib/suffix/test/SuffixTestConfig.cmake")
set(TFramework_EXPECTED
  "TFramework.framework/Versions/A/Resources/CMake/TFrameworkConfig.cmake")
set(Tframework_EXPECTED
  "TFramework.framework/Versions/A/Resources/tframework-config.cmake")
set(TApp_EXPECTED
  "TApp.app/Contents/Resources/TAppConfig.cmake")
set(Tapp_EXPECTED
  "TApp.app/Contents/Resources/cmake/tapp-config.cmake")
set(VersionedA_EXPECTED "lib/zot-2.0/zot-config.cmake")
set(VersionedB_EXPECTED "lib/zot-3.1/zot-config.cmake")
set(VersionedC_EXPECTED "lib/cmake/zot-4.0/zot-config.cmake")
set(VersionedD_EXPECTED "Baz 1.1/BazConfig.cmake")
set(VersionedE_EXPECTED "Baz 1.2/CMake/BazConfig.cmake")
set(VersionedF_EXPECTED "Baz 1.3/lib/cmake/Baz/BazConfig.cmake")
set(VersionedG_EXPECTED "Baz 2.0/share/Baz 2/BazConfig.cmake")
set(VersionedH_EXPECTED "Baz 2.1/lib/Baz 2/cmake/BazConfig.cmake")
set(WrongA_EXPECTED "${VersionedE_EXPECTED}")
set(WrongB_EXPECTED "${VersionedE_EXPECTED}")
set(WrongC_MISSING "WrongC_DIR-NOTFOUND")
set(WrongD_MISSING "WrongD_DIR-NOTFOUND")
set(wibbleA_EXPECTED "A/wibble-config.cmake")
set(wibbleB_EXPECTED "B/wibble-config.cmake")
set(RecursiveA_EXPECTED "lib/RecursiveA/recursivea-config.cmake")
set(RecursiveB_EXPECTED "lib/zot-2.0/zot-config.cmake")
set(RecursiveC_EXPECTED "lib/zot-3.1/zot-config.cmake")
set(ArchA_EXPECTED "lib/arch/Bar/BarConfig.cmake")
set(ArchB_EXPECTED "lib/arch/foo-1.2/CMake/FooConfig.cmake")
set(ArchC_EXPECTED "lib/arch/zot-3.1/zot-config.cmake")
set(ArchD_EXPECTED "lib/arch/cmake/zot-4.0/zot-config.cmake")
set(EnvA_EXPECTED "lib/zot-3.1/zot-config.cmake")
set(EnvB_MISSING "EnvB_DIR-NOTFOUND")
set(SetFoundTRUE_EXPECTED "cmake/SetFoundTRUEConfig.cmake")
set(SetFoundFALSE_MISSING "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
set(CMakeTestSystemPackage_EXPECTED "SystemPackage/CMakeTestSystemPackageConfig.cmake")

# Check the results.
foreach(p ${PACKAGES})
  if(DEFINED ${p}_MISSING)
    # Check and report failure.
    if(NOT "${${p}_DIR}" STREQUAL "${${p}_MISSING}")
      message(SEND_ERROR
        "Package ${p} should have been [${${p}_MISSING}] but "
        "was [${${p}_DIR}]")
    endif()
    if(${p}_FOUND)
      message(SEND_ERROR
        "Package ${p} should not have been found, but ${p}_FOUND is set to "
        "\"${${p}_FOUND}\"")
    endif()
  elseif(${p}_FOUND)
    # Convert to relative path for comparison to expected location.
    file(RELATIVE_PATH REL_${p}_CONFIG "${CMAKE_CURRENT_SOURCE_DIR}"
      "${${p}_CONFIG}")

    # Debugging output.
    if(CMAKE_FIND_DEBUG_MODE)
      message("Package ${p} found [${REL_${p}_CONFIG}]")
    endif()

    # Check and report failure.
    if(NOT "${REL_${p}_CONFIG}" STREQUAL "${${p}_EXPECTED}")
      message(SEND_ERROR
        "Package ${p} should have been [${${p}_EXPECTED}] but "
        "was [${REL_${p}_CONFIG}]")
    endif()
  else()
    message(SEND_ERROR "Package ${p} not found!")
  endif()
endforeach()

# Check that version information was extracted.
if(NOT "${VersionedA_VERSION}" STREQUAL "2.0")
  message(SEND_ERROR
    "Package VersionedA is version [${VersionedA_VERSION}], not [2.0]")
endif()
if(NOT "${VersionedA_VERSION_MAJOR}" STREQUAL "2")
  message(SEND_ERROR
    "Package VersionedA is major version [${VersionedA_VERSION_MAJOR}], not [2]")
endif()
if(NOT "${VersionedA_VERSION_MINOR}" STREQUAL "0")
  message(SEND_ERROR
    "Package VersionedA is minor version [${VersionedA_VERSION_MINOR}], not [0]")
endif()

if(NOT "${VersionedB_VERSION}" STREQUAL "3.1")
  message(SEND_ERROR
    "Package VersionedB is version [${VersionedB_VERSION}], not [3.1]")
endif()
if(NOT "${VersionedB_VERSION_MAJOR}" STREQUAL "3")
  message(SEND_ERROR
    "Package VersionedB is major version [${VersionedB_VERSION_MAJOR}], not [3]")
endif()
if(NOT "${VersionedB_VERSION_MINOR}" STREQUAL "1")
  message(SEND_ERROR
    "Package VersionedB is minor version [${VersionedB_VERSION_MINOR}], not [1]")
endif()

if(NOT "${Special_VERSION}" STREQUAL "1.2")
  message(SEND_ERROR
    "Package Special is version [${Special_VERSION}], not [1.2]")
endif()
if(NOT "${Special_VERSION_MAJOR}" STREQUAL "1")
  message(SEND_ERROR
    "Package Special is major version [${Special_VERSION_MAJOR}], not [1]")
endif()
if(NOT "${Special_VERSION_MINOR}" STREQUAL "2")
  message(SEND_ERROR
    "Package Special is minor version [${Special_VERSION_MINOR}], not [2]")
endif()

# Test version number comparison.
if(NOT "1.2.3.4" VERSION_LESS "1.2.3.5")
  message(SEND_ERROR "1.2.3.4 VERSION_LESS 1.2.3.5 is not true!")
endif()
if(NOT "1.2" VERSION_LESS "1.10")
  message(SEND_ERROR "1.2 VERSION_LESS 1.10 is not true!")
endif()
if(NOT "1.02" VERSION_GREATER "1.1")
  message(SEND_ERROR "1.02 VERSION_GREATER 1.1 is not true!")
endif()
if("1.2.3" VERSION_GREATER "1.2.3.4")
  message(SEND_ERROR "1.2.3 VERSION_GREATER 1.2.3.4 is not false!")
endif()
if(NOT "1.2" VERSION_EQUAL "1.2.0.0")
  message(SEND_ERROR "1.2 VERSION_EQUAL 1.2.0.0 is not true!")
endif()

#-----------------------------------------------------------------------------
# Test export(PACKAGE) with find_package.

# Choose a unique version.
string(REGEX REPLACE "-.*$" "" version ${CMAKE_VERSION})
string(RANDOM LENGTH 4 ALPHABET "0123456789" v)
string(APPEND version ".${v}")

message(STATUS "Preparing export(PACKAGE) test project")
try_compile(EXPORTER_COMPILED
  ${FindPackageCMakeTest_BINARY_DIR}/Exporter-build
  ${FindPackageCMakeTest_SOURCE_DIR}/Exporter
  CMakeTestExportPackage dummy
  CMAKE_FLAGS "-UCMAKE_EXPORT_NO_PACKAGE_REGISTRY"
    "-DCMAKE_POLICY_DEFAULT_CMP0090:STRING=OLD"
    -Dversion=${version}
  OUTPUT_VARIABLE output)
message(STATUS "Searching for export(PACKAGE) test project")
set(CMakeTestExportPackage_DIR "" CACHE FILEPATH
  "Wipe out find results for testing." FORCE)

message(STATUS "Searching for export(PACKAGE) with CMAKE_FIND_USE_PACKAGE_REGISTRY=TRUE")
set(CMAKE_FIND_USE_PACKAGE_REGISTRY TRUE)
find_package(CMakeTestExportPackage 1.${version} EXACT REQUIRED)
if(NOT CMakeTestExportPackage_FOUND)
  message(SEND_ERROR "CMakeTestExportPackage should be FOUND!")
endif()
unset(CMAKE_FIND_USE_PACKAGE_REGISTRY)

message(STATUS "Searching for export(PACKAGE) with CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=FALSE")
set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY FALSE)
find_package(CMakeTestExportPackage 1.${version} EXACT REQUIRED)
if(NOT CMakeTestExportPackage_FOUND)
  message(SEND_ERROR "CMakeTestExportPackage should be FOUND!")
endif()
unset(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY)

message(STATUS "Searching for export(PACKAGE) with CMAKE_FIND_USE_PACKAGE_REGISTRY=TRUE and CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=TRUE")
set(CMAKE_FIND_USE_PACKAGE_REGISTRY TRUE)
set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY TRUE)
set(CMakeTestExportPackage_DIR FALSE)
find_package(CMakeTestExportPackage 1.${version} EXACT REQUIRED)
if(NOT CMakeTestExportPackage_FOUND)
  message(SEND_ERROR "CMakeTestExportPackage should be FOUND!")
endif()
unset(CMAKE_FIND_USE_PACKAGE_REGISTRY)
unset(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY)

message(STATUS "Searching for export(PACKAGE) with CMAKE_FIND_USE_PACKAGE_REGISTRY=FALSE and CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=FALSE")
set(CMAKE_FIND_USE_PACKAGE_REGISTRY FALSE)
set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY FALSE)
set(CMakeTestExportPackage_DIR "" CACHE FILEPATH
  "Wipe out find results for testing." FORCE)
find_package(CMakeTestExportPackage 1.${version} EXACT QUIET)
if(CMakeTestExportPackage_FOUND)
  message(SEND_ERROR "CMakeTestExportPackage should be not FOUND!")
endif()
unset(CMAKE_FIND_USE_PACKAGE_REGISTRY)
unset(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY)

message(STATUS "Remove export(PACKAGE) test project")
file(REMOVE_RECURSE ${FindPackageCMakeTest_BINARY_DIR}/Exporter-build)
set(CMakeTestExportPackage_DIR "" CACHE FILEPATH
  "Wipe out find results for testing." FORCE)
find_package(CMakeTestExportPackage QUIET) # Should clean the user package cache
#
message(STATUS "Preparing export(PACKAGE) test project with CMAKE_EXPORT_NO_PACKAGE_REGISTRY=TRUE")
try_compile(EXPORTER_COMPILED
  ${FindPackageCMakeTest_BINARY_DIR}/Exporter-build
  ${FindPackageCMakeTest_SOURCE_DIR}/Exporter
  CMakeTestExportPackage dummy
  CMAKE_FLAGS "-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY:BOOL=TRUE"
    -Dversion=${version}
  OUTPUT_VARIABLE output)
message(STATUS "Searching for export(PACKAGE) test project")
find_package(CMakeTestExportPackage 1.${version} EXACT QUIET)
if(CMakeTestExportPackage_FOUND)
  message(SEND_ERROR "CMakeTestExportPackage should not be FOUND!")
endif()

message(STATUS "Remove export(PACKAGE) test project")
file(REMOVE_RECURSE ${FindPackageCMakeTest_BINARY_DIR}/Exporter-build)

message(STATUS "Preparing export(PACKAGE) test project with POLICY CMP0090=NEW")
try_compile(EXPORTER_COMPILED
  ${FindPackageCMakeTest_BINARY_DIR}/Exporter-build
  ${FindPackageCMakeTest_SOURCE_DIR}/Exporter
  CMakeTestExportPackage dummy
  CMAKE_FLAGS
   "-DCMAKE_POLICY_DEFAULT_CMP0090:STRING=NEW"
    -Dversion=${version}
  OUTPUT_VARIABLE output)
message(STATUS "Searching for export(PACKAGE) test project")
find_package(CMakeTestExportPackage 1.${version} EXACT QUIET)
if(CMakeTestExportPackage_FOUND)
  message(SEND_ERROR "CMakeTestExportPackage should not be FOUND!")
endif()


#-----------------------------------------------------------------------------
# Test configure_package_config_file().

include(CMakePackageConfigHelpers)

# Generate a config file ready to be installed.
set(INCLUDE_INSTALL_DIR include )
set(SHARE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/share/" )
set(CURRENT_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}" )

configure_package_config_file(RelocatableConfig.cmake.in "${CMAKE_CURRENT_BINARY_DIR}/RelocatableConfig.cmake"
                              INSTALL_DESTINATION "${CMAKE_INSTALL_PREFIX}"
                              PATH_VARS INCLUDE_INSTALL_DIR SHARE_INSTALL_DIR CURRENT_BUILD_DIR
                             )

set(Relocatable_FIND_COMPONENTS AComp BComp CComp)
set(Relocatable_FIND_REQUIRED_BComp 1)
include("${CMAKE_CURRENT_BINARY_DIR}/RelocatableConfig.cmake")

if(NOT "${RELOC_INCLUDE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}/include")
  message(SEND_ERROR "RELOC_INCLUDE_DIR set by configure_package_config_file() is set to\n  \"${RELOC_INCLUDE_DIR}\"\nnot the expected\n  \"${CMAKE_CURRENT_BINARY_DIR}/include\"")
endif()

if(NOT "${RELOC_SHARE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}/share/")
  message(SEND_ERROR "RELOC_SHARE_DIR set by configure_package_config_file() is set to\n  \"${RELOC_SHARE_DIR}\"\nnot the expected\n  \"${CMAKE_CURRENT_BINARY_DIR}/share/\"")
endif()

if(NOT "${RELOC_BUILD_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}")
  message(SEND_ERROR "RELOC_BUILD_DIR set by configure_package_config_file() is set to\n  \"${RELOC_BUILD_DIR}\"\nnot the expected\n  \"${CMAKE_CURRENT_BINARY_DIR}\"")
endif()

if(NOT DEFINED Relocatable_FOUND)
  message(SEND_ERROR "Relocatable_FOUND not defined !")
endif()

if(Relocatable_FOUND)
  message(SEND_ERROR "Relocatable_FOUND set to TRUE !")
endif()

# Generate a config file for the build tree.
set(INCLUDE_INSTALL_DIR include )
set(SHARE_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/share/" )
set(CURRENT_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}" )

configure_package_config_file(RelocatableConfig.cmake.in "${CMAKE_CURRENT_BINARY_DIR}/RelocatableConfig.cmake"
                              INSTALL_DESTINATION "${CMAKE_CURRENT_BINARY_DIR}"
                              PATH_VARS INCLUDE_INSTALL_DIR SHARE_INSTALL_DIR CURRENT_BUILD_DIR
                              INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}"
                             )

set(Relocatable_FIND_COMPONENTS AComp BComp CComp)
set(Relocatable_FIND_REQUIRED_BComp 1)
include("${CMAKE_CURRENT_BINARY_DIR}/RelocatableConfig.cmake")

if(NOT "${RELOC_INCLUDE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}/include")
  message(SEND_ERROR "RELOC_INCLUDE_DIR set by configure_package_config_file() is set to\n  \"${RELOC_INCLUDE_DIR}\"\nnot the expected\n  \"${CMAKE_CURRENT_BINARY_DIR}/include\"")
endif()

if(NOT "${RELOC_SHARE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}/share/")
  message(SEND_ERROR "RELOC_SHARE_DIR set by configure_package_config_file() is set to\n  \"${RELOC_SHARE_DIR}\"\nnot the expected\n  \"${CMAKE_CURRENT_BINARY_DIR}/share/\"")
endif()

if(NOT "${RELOC_BUILD_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}")
  message(SEND_ERROR "RELOC_BUILD_DIR set by configure_package_config_file() is set to\n  \"${RELOC_BUILD_DIR}\"\nnot the expected\n  \"${CMAKE_CURRENT_BINARY_DIR}\"")
endif()

if(NOT DEFINED Relocatable_FOUND)
  message(SEND_ERROR "Relocatable_FOUND not defined !")
endif()

if(Relocatable_FOUND)
  message(SEND_ERROR "Relocatable_FOUND set to TRUE !")
endif()


############################################################################
##Test FIND_PACKAGE using sorting
set(CMAKE_PREFIX_PATH ${CMAKE_CURRENT_SOURCE_DIR})

foreach(CMAKE_FIND_PACKAGE_SORT_DIRECTION IN ITEMS "" ASC Bogus)
  set(SortLib_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
  SET(CMAKE_FIND_PACKAGE_SORT_ORDER NAME)
  FIND_PACKAGE(SortLib CONFIG)
  IF (NOT "${SortLib_VERSION}" STREQUAL "3.1.1")
    message(SEND_ERROR "FIND_PACKAGE_SORT_ORDER Name Asc! ${SortLib_VERSION}")
  endif()
  unset(SortLib_VERSION)
endforeach()


set(SortLib_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
SET(CMAKE_FIND_PACKAGE_SORT_ORDER NATURAL)
SET(CMAKE_FIND_PACKAGE_SORT_DIRECTION DEC)
FIND_PACKAGE(SortLib CONFIG)
IF (NOT "${SortLib_VERSION}" STREQUAL "3.10.1")
  message(SEND_ERROR "FIND_PACKAGE_SORT_ORDER Natural! Dec ${SortLib_VERSION}")
endif()
set(SortLib_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
unset(SortLib_VERSION)


set(SortLib_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
FIND_PACKAGE(SortLib 4.0 CONFIG)
IF (NOT "${SortLib_VERSION}" STREQUAL "4.0.0")
  message(SEND_ERROR "FIND_PACKAGE_SORT_ORDER gave up too soon! ${SortLib_VERSION}")
endif()
unset(SortLib_VERSION)


set(SortLib_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
# Expected to default to 'NATURAL' and 'DEC'
unset(CMAKE_FIND_PACKAGE_SORT_ORDER)
unset(CMAKE_FIND_PACKAGE_SORT_DIRECTION)
FIND_PACKAGE(SortLib CONFIG)
IF (NOT "${SortLib_VERSION}" STREQUAL "3.10.1")
  message(SEND_ERROR "FIND_PACKAGE_SORT_ORDER Default! ${SortLib_VERSION}")
endif()
unset(SortLib_VERSION)


set(SortFramework_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
SET(CMAKE_FIND_PACKAGE_SORT_ORDER NAME)
SET(CMAKE_FIND_PACKAGE_SORT_DIRECTION ASC)
FIND_PACKAGE(SortFramework CONFIG)
IF (NOT "${SortFramework_VERSION}" STREQUAL "3.1.1")
  message(SEND_ERROR "FIND_PACKAGE_SORT_ORDER Framework Name Asc! ${SortFramework_VERSION}")
endif()
set(SortLib_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
unset(SortFramework_VERSION)


set(SortFramework_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
SET(CMAKE_FIND_PACKAGE_SORT_ORDER NATURAL)
SET(CMAKE_FIND_PACKAGE_SORT_DIRECTION DEC)
FIND_PACKAGE(SortFramework CONFIG)
IF (NOT "${SortFramework_VERSION}" STREQUAL "3.10.1")
  message(SEND_ERROR "FIND_PACKAGE_SORT_ORDER Framework Natural! Dec ${SortFramework_VERSION}")
endif()
set(SortLib_DIR "" CACHE FILEPATH "Wipe out find results for testing." FORCE)
unset(SortFramework_VERSION)

unset(CMAKE_FIND_PACKAGE_SORT_ORDER)
unset(CMAKE_FIND_PACKAGE_SORT_DIRECTION)
set(CMAKE_PREFIX_PATH )

############################################################################
##Test FIND_PACKAGE CMAKE_FIND_PACKAGE_PREFER_CONFIG

set(CMAKE_PREFIX_PATH ${CMAKE_CURRENT_SOURCE_DIR}/PreferConfig)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/PreferConfig)

# prefer module mode
set(CMAKE_FIND_PACKAGE_PREFER_CONFIG OFF)
unset(ABC_FOUND)
unset(ABC_CONFIG)

find_package(ABC)
if(NOT ABC_FOUND)
    message(SEND_ERROR "Did not find ABC package")
endif()
if(ABC_CONFIG)
    message(SEND_ERROR "Incorrectly found ABC in CONFIG mode, expected to find it with MODULE mode")
endif()

# Now prefer config mode
set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON)
unset(ABC_FOUND)
unset(ABC_CONFIG)

find_package(ABC)
if(NOT ABC_FOUND)
    message(SEND_ERROR "Did not find ABC package")
endif()
if(NOT ABC_CONFIG)
    message(SEND_ERROR "Incorrectly found ABC in MODULE mode, expected to find it with CONFIG mode")
endif()

set(CMAKE_FIND_PACKAGE_PREFER_CONFIG OFF)
set(CMAKE_PREFIX_PATH)
set(CMAKE_MODULE_PATH)

############################################################################
##Test FIND_PACKAGE CMAKE_FIND_PACKAGE_PREFER_CONFIG - Do not recurse

# No CMAKE_PREFIX_PATH
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/PreferConfigRecurse)

# Now prefer config mode
set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON)
unset(ACME_FOUND)
unset(ACME_CONFIG)

find_package(ACME)
if(ACME_FOUND AND ACME_CONFIG)
    message(SEND_ERROR "Incorrectly found ACME in CONFIG mode, from the MODULE package")
endif()

set(CMAKE_FIND_PACKAGE_PREFER_CONFIG OFF)
set(CMAKE_MODULE_PATH)

############################################################################
##Test find_package CMAKE_FIND_PACKAGE_PREFER_CONFIG with module fallback

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/PreferConfigOnlyModule)

set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON)

find_package(ACME REQUIRED)

if(NOT ACME_FOUND)
    message(SEND_ERROR "Did not find ACME package")
endif()

############################################################################
##Test find_package CMAKE_FIND_PACKAGE_PREFER_CONFIG with NO_MODULE

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/PreferConfigOnlyModule)

set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON)

find_package(ACME NO_MODULE)

if(ACME_FOUND)
    message(SEND_ERROR "Should not find ACME package")
endif()

############################################################################
##Test find_package CMAKE_FIND_PACKAGE_PREFER_CONFIG with unknown package

set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON)
find_package(DoesNotExist)
