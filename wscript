#! /usr/bin/env python
# -*- coding: utf-8 -*-
'Build definition and execution'

from waflib import Configure, Logs

# -------------------------------------------------<END IMPORTS | START GLOBALS>

APP_NAME = 'cmake'

# -------------------------------------------------<END GLOBALS | START OPTIONS>

def options(opt):
    opt.load('wak.tools')
    opt.load('compiler_cxx')
    opt.load('buildmatrix_wak')

# -------------------------------------------------<END OPTIONS | START HELPERS>


def make_app_version(conf):

    app_version = conf.makePak(
        variables={
            "PATH": {
                'value': '${PREFIX}/bin',
                'action': 'env_prp'
            }
        }
    )

    return app_version


# ---------------------------------------------------<HELPERS | START CONFIGURE>


def configure(conf):

    conf.env.WAK_APP_NAME = APP_NAME
    conf.env.WAK_SCM_TAG_PREFIX = 'weta/'
    conf.env.WAK_NON_CI_RELEASE_CMDS = ['tag']

    conf.load('wak.tools')
    conf.load('buildmatrix_wak')

    # Make the pak
    make_app_version(conf)

    for _ in conf.buildmatrix_make_variants('ABI', filter_variants=["L171"]):

        # Don't install into a variant specific dir
        conf.setVariantFolder("")
        requires = [
            'gcc',              # Constrained by the ABI variant
            'cmake-3.27<4',     # Building cmake with cmake!!
            'ninja-1.10<2',
        ]

        # This must happen before any other env changes to avoid over writing.
        conf.buildmatrix_oz(area='/', limits=requires)

        # Load the C++ compiler tool after a compiler has been selected via oz paks
        conf.load('compiler_cxx')
        conf.load("wak.tools.cmake")

        conf.buildmatrix_set_flags(flavor_override="opt")

        Logs.warn(f"Calling generate - this can take a few minutes!")

        # Generate the CMake project files using the wak cmake tool
        conf.cmakeGenerate(
            source_dir=conf.path,

            # Disabled to ensure that cmake does not attempt to upload build data to the public cdash server
            CMAKE_TESTS_CDASH_SERVER="NOTFOUND",

            # Disabled as cmake itself does not follow its own best practice, and links to `ld` without finding it via
            # a package first.
            CMAKE_LINK_LIBRARIES_ONLY_TARGETS="Off",
        )


# -------------------------------------------------<END CONFIGURE | START BUILD>


def build(bld):

    for _ in bld.iterVariants(category='ABI'):

        build_task = bld.cmakeBuild(
            name="build",
        )

        # Setting these to empty to avoid interference with the tests.
        #
        # The cmake tests will subprocess out, calling the version of cmake that has just been built.
        # The subprocess will then execute a number of builds as part of the tests, going all the way from generate
        # through to pack.
        #
        # Sadly, these tests assume that there are no flags being passed in. However - cmake itself will also default
        # the flags from the CXXFLAGS and CFLAGS envvars - meaning that having these set in the test environment will
        # cause a whole bunch of tests to fail.....
        #
        # The build is completed at this point, and it passes the flags via the command line anyway, so unsetting here
        # has no side effects.
        bld.env.env["CXXFLAGS"] = ""
        bld.env.env["CFLAGS"] = ""

        tests_to_skip = [
            "^CMake.CheckSourceTree$",            # Well of course the source tree is dirty, we are iterating on it....
            "^CMakeOnly.AllFindModules$",         # Uses `/usr/bin/msgmerge` which cannot be run from within an oz env.
            "^CPackComponents.*",                 # Uses incorrect version of gomp within the tests. We don't use cpack anyway
            "^RunCMake.CPack.*",                  # Same as `CPackComponents`
            "^CTestTestUpload$",                  # Attempts to upload test data to a public server
            "^FortranC.Flags$",                   # We do not have a valid fortran toolchain setup
        ]

        test_task = bld.cmakeTest(
            name="test",
            dependsOn=[build_task],
            other_args=["--output-on-failure"],
            exclude_regex=tests_to_skip,
        )

        bld.cmakeInstall(
            name="install",
            dependsOn=[build_task, test_task],
        )

    # set or update the oz app details for the app catalog
    app_options = {
        'contacts': {
            'Department': 'Engineering',
            'Maintainer': 'nlenihan@wetafx.co.nz'
        },
        'description': 'A cross-platform, open-source build system generator.',
        'info': {
            'OSS_REPO': 'https://github.com/Kitware/CMake',
            'JIRA': 'https://jira.wetafx.co.nz/projects/HABITAT',
        },
        'third_party': True,
        'license': 'BSD-3-Clause'
    }

    bld.setOzAppDetails(
        app=f'{bld.env.WAK_APP_NAME}',
        options=app_options,
        description='set/refresh the app metadata'
    )
