AC_DEFUN([AX_THOR_LIB_SELECT],
[
    THOR_TARGETLIBS=""
    AS_IF(
          [test "x$enable_shared" == "xyes"],
          [THOR_TARGETLIBS+=" slib"]
    )
    AS_IF(
          [test "x$enable_static" == "xyes"],
          [THOR_TARGETLIBS+=" a"]
    )
    AC_SUBST([THOR_TARGETLIBS],[${THOR_TARGETLIBS}])
])
AC_DEFUN([AX_THOR_BUILD_ON_TRAVIS_OPTION],
[
    AC_ARG_WITH(
        [thor-build-on-travis],
        AS_HELP_STRING([--with-thor-build-on-travis], [Used by travis to install and do some configuration])
    )
])
AC_DEFUN([AX_THOR_BUILD_ON_TRAVIS_OPTION_UPDATE_SUB],
[
(
    cd $1
    AS_IF(
        [test "${with_thor-build-on-travis}" == ""],
        [],
        [
    mv .gitmodules gitmodules.old
    sed -e 's#git@\([^:]*\):#https://\1/#' gitmodules.old > .gitmodules
    rm gitmodules.old
        ]
    )
    git submodule init
    AS_IF(
        [git submodule update],
        [],
        [AC_MSG_ERROR([

git submodule updated failed:
Currently all Loki-Astari submodules are retrieved using ssh.
If the above command failed it probably means that you have not registered your "public key" with github.com

See this article on StackOverflow for simple instructions:
http://stackoverflow.com/questions/25828483/github-permission-denied-publickey


Once you have installed the keys you can restart the configuration with:
git submodule update
./configure <Same Flags You had before>

        ])]
    )
)
])
AC_DEFUN([AX_THOR_BUILD_ON_TRAVIS_OPTION_BUILD_VERA],
[
    AS_IF(
        [test "${with_thor-build-on-travis}" == ""],
        [],
        [
(
    ./build/third/vera-install
)

        ]
    )
])


AC_DEFUN([AX_THOR_FUNC_USE_VERA],
[
    AC_ARG_ENABLE(
        [vera],
        AS_HELP_STRING([--disable-vera], [Disable vera. Disable Static analysis of source.])
    )
    AS_IF([test "$with_thor-build-local-vera" == ""],
        [AS_IF(
            [test "x$enable_vera" == "xno"],
            [
                AC_SUBST(VERA, ['echo "Disabled Static Analysis" ||'])
            ],
            [
                AC_SUBST(VERA, [vera++])
                AC_CHECK_PROGS([TestVera], [vera++], [:])
                AS_IF(
                    [test "$TestVera" == ":"],
                    [
                        AC_MSG_ERROR([


By default the build tools use vera++ for static analysis of C++ code to ensure the project
maintains a consistent style when people add pull requests. The configuration tests have
detected that "vera++" (the static analysis tool) is not currently installed.

If you don't care about static analysis the feel free to disable this feature using the flag

    --disable-vera

Alternatively you can install vera++

    https://bitbucket.org/verateam/vera/wiki/Home

Note: Pull requests that do not pass static analysis will be rejected.

])
                    ],
                    [
                    ]
                )
            ]
        )
        ]
    )
])

AC_DEFUN([AX_THOR_FUNC_BUILD],
[
    AC_CHECK_PROGS([WGET], [wget], [:])
    if test "$WGET" = :; then
        AC_MSG_ERROR([This package needs wget.])
    fi
    AC_CHECK_PROGS([UNZIP], [unzip], [:])
    if test "$UNZIP" = :; then
        AC_MSG_ERROR([This package needs unzip.])
    fi

    AC_PROG_CXX

    AX_THOR_BUILD_ON_TRAVIS_OPTION
    AX_THOR_BUILD_ON_TRAVIS_OPTION_UPDATE_SUB(.)
    AX_THOR_BUILD_ON_TRAVIS_OPTION_UPDATE_SUB(build)
    AX_THOR_BUILD_ON_TRAVIS_OPTION_BUILD_VERA(build)

    AX_THOR_FUNC_USE_VERA

    pushd build/third
    ./setup "$CXX" || AC_MSG_ERROR([Failed to set up the test utilities], [1])
    popd

])

AC_DEFUN([AX_THOR_PROG_LEX],
[
    AC_PROG_LEX
    if test "${LEX}" != "flex"; then
        AC_MSG_ERROR([

Error: This package uses flex (and is not compatible with lex).
Please make sure flex is installed.

If it is installed an autotools is picking the wrong lex you explicitly specify it via
the environment variable LEX.

Eg.
    LEX=<path to flex> ./configure <other flags>

    ])
    fi
])

AC_DEFUN([AX_THOR_FUNC_USE_YAML],
[
    AC_ARG_WITH(
        [yamlroot],
        AS_HELP_STRING([--with-yamlroot=<location>], [Directory of YAML_ROOT])
    )
    AC_ARG_ENABLE(
        [yaml],
        AS_HELP_STRING([--disable-yaml], [Disable yaml serialization])
    )
    AS_IF(
        [test "x$enable_yaml" != "xno"],

        if test "${with_yamlroot}" == ""; then
            with_yamlroot="/usr/local"
        fi
        ORIG_LDFLAGS="${LDFLAGS}"
        LDFLAGS="$LDFLAGS -L$with_yamlroot/lib"

        AC_CHECK_LIB(
            [yaml],
            [yaml_parser_initialize],
            [
                AC_DEFINE([HAVE_YAML], 1, [When on Yaml Serialization code will be compiled])
                AC_SUBST([yaml_ROOT_DIR], [$with_yamlroot])
                AC_SUBST([yaml_ROOT_LIB], [yaml])
            ],
            [AC_MSG_ERROR([
 
Error: Could not find libyaml

You can solve this by installing libyaml
    see http://pyyaml.org/wiki/LibYAML

Alternately specify install location with:
    --with-yamlroot=<location of yaml installation>

If you do not want to use yaml serialization then it
can be disabled with:
    --disable-yaml

                ], [1])]
        )

        LDFLAGS="${ORIG_LDFLAGS}"
    )
])

AC_DEFUN([AX_THOR_FUNC_USE_EVENT],
[
    AC_ARG_WITH(
        [eventroot],
        AS_HELP_STRING([--with-eventroot=<location>], [Directory of EVENT_ROOT])
    )
    if test "${with_eventroot}" == ""; then
        with_eventroot="/usr/local"
    fi
    ORIG_LDFLAGS="${LDFLAGS}"
    LDFLAGS="$LDFLAGS -L$with_eventroot/lib"

    AC_CHECK_LIB(
        [event],
        [event_dispatch],
        [
            AC_DEFINE([HAVE_EVENT], 1, [We have found libevent library])
            AC_SUBST([event_ROOT_DIR], [$with_eventroot])
            AC_SUBST([event_ROOT_LIB], [event])
        ],
        [AC_MSG_ERROR([

Error: Could not find libevent

You can solve this by installing libevent
see http://libevent.org/

If libevent is not installed in the default location (/usr/local) then you will need to specify its location.
--with-eventroot=<location of event installation>

            ], [1])]
    )

    LDFLAGS="${ORIG_LDFLAGS}"
])

AC_DEFUN(
    [AX_THOR_FUNC_TEST_COMP],
    [
        AS_IF([test "$1" != ""],
            [
                AC_MSG_CHECKING([Checking Compiler Compatibility ${CXX} ${CXX_STD_FLAG}])
                AC_LANG(C++)
                CXXFLAGS_SAVE="${CXXFLAGS}"
                AC_SUBST([CXXFLAGS], [${CXX_STD_FLAG}])
                AC_COMPILE_IFELSE([AC_LANG_SOURCE([$1])],
                [
                    AC_MSG_RESULT([good])
                ],
                [
                    AC_MSG_ERROR([

Error: Your compiler does not seem to support the language features required.
       Try updating your compiler to use a more recent version.

       Compiler used: ${CXX} ${CXX_STD_FLAG}
                    ])
                ])
                AC_SUBST([CXXFLAGS], [${CXXFLAGS_SAVE}])
            ])
    ]
)
AC_DEFUN(
    [AX_THOR_FUNC_LANG_FLAG],
    [
        minLangFeature=$1
        AS_IF([test "$2" = ""], [maxLangFeature=17], [maxLangFeature=$2])
        AS_IF([test $minLangFeature -gt $maxLangFeature], AC_MSG_ERROR([Invalid Language Value],[1]))
        
        AC_LANG(C++)
        CXXMaxLanguage=03
        CXXExpLanguage=03
        AX_CHECK_COMPILE_FLAG([-std=c++11], [AC_SUBST([CXXMaxLanguage],11) AC_SUBST([StdFlag11],[-std=c++11])])
        AX_CHECK_COMPILE_FLAG([-std=c++14], [AC_SUBST([CXXMaxLanguage],14) AC_SUBST([StdFlag14],[-std=c++14])])
        AX_CHECK_COMPILE_FLAG([-std=c++17], [AC_SUBST([CXXMaxLanguage],17) AC_SUBST([StdFlag17],[-std=c++17])])
        AX_CHECK_COMPILE_FLAG([-std=c++1x], [AC_SUBST([CXXExpLanguage],11) AC_SUBST([ExpFlag11],[-std=c++1x])])
        AX_CHECK_COMPILE_FLAG([-std=c++1y], [AC_SUBST([CXXExpLanguage],14) AC_SUBST([ExpFlag14],[-std=c++1y])])
        AX_CHECK_COMPILE_FLAG([-std=c++1z], [AC_SUBST([CXXExpLanguage],17) AC_SUBST([ExpFlag17],[-std=c++1z])])

        #CXX_STD_FLAG
        #CXXSTDVER

        AS_IF(
            [test $minLangFeature -le $CXXMaxLanguage],
            [
                AS_IF(
                    [test $maxLangFeature -le $CXXMaxLanguage],
                    [AC_SUBST([CXXSTDVER], [$maxLangFeature])],
                    [AC_SUBST([CXXSTDVER], [$CXXMaxLanguage])]
                )
                AC_SUBST([CXX_STD_FLAG], [$(eval echo "\${StdFlag${CXXSTDVER}}")])
            ],
            [AS_IF(
                [test $minLangFeature -le $CXXExpLanguage],
                [
                    AS_IF(
                        [test $maxLangFeature -le $CXXExpLanguage],
                        [AC_SUBST([CXXSTDVER], [$maxLangFeature])],
                        [AC_SUBST([CXXSTDVER], [$CXXExpLanguage])]
                    )
                    AC_SUBST([CXX_STD_FLAG], [$(eval echo "\${ExpFlag${CXXSTDVER}}")])
                ],
                [AC_MSG_ERROR([

Error: Need C++${minLangFeature} but the compiler only supports ${CXXMaxLanguage} (Experimental ${CXXExpLanguage})

                    ], [1])]
            )]
        )
    ]
)
AC_DEFUN([AX_THOR_PROG_COV],
    [AS_IF(
        [test "x${COV}x" = "xx"],
        [AS_IF(
            [test "${CXX}" = "g++"],
            [AC_SUBST([COV],[gcov])],
            [AS_IF(
                [test "${CXX}" = "clang++"],
                [AC_SUBST([COV],[llvm-cov])],
                [AC_MSG_ERROR([

Could not determine the coverage tool.

For g++ we default to gcov
For clang++ we default to llvm-cov

The compiler currently defined is "${CXX}" and we do not know what coverage tool to use.

One alternatives is to specify a know compiler before calling configure.

    CXX=clang++ ./configure

Another alternative is to explicitly specify the coverage tool to use.

    COV=gcov ./confgiure

                    ])
                ]
            )]
        )]
    )
    ${COV} --version 2>&1 | grep -Eo '(\d+\.)+\d+' || ${COV} --version 2>&1 | grep -Po '(\d+\.)+\d+' > /dev/null
    AS_IF(
        [test $? != 0],
        [AC_MSG_ERROR([

The coverage tool "${COV}" does not seem to be working.

         ])
        ]
    )]
)

dnl
dnl

AC_DEFUN([AX_THOR_FUNC_USE_BINARY],
[
    AC_ARG_WITH(
        [thors-network-byte-order],
        AS_HELP_STRING([--with-thors-network-byte-order], [Use internal tools to convert 64/128 bit values to network byte order])
    )
    AC_ARG_ENABLE(
        [binary],
        AS_HELP_STRING([--disable-binary], [Disable binary serialization])
    )
    AS_IF(
        [test "x$enable_binary" != "xno"],
        [
            networkbyteorderfunction=""
            AC_C_BIGENDIAN(
                [networkbyteorderfunction="identity"],
                [
                    AS_IF(
                        [test "${with_thors_network_byte_order}" == "yes"],
                        [networkbyteorderfunction="thorsNetworkByteOrder"],
                        [
                            AX_BSWAP64
                            networkbyteorderfunction = bswap64_function;
                        ]
                    )
                ]
            )
            AS_IF(
                [test "x$networkbyteorderfunction" != "x"],
                [
                    AC_DEFINE([NETWORK_BYTE_ORDER], 1, [We have functions to convert host to network byte order for 64/128 bit values])
                    AC_DEFINE_UNQUOTED([BSWAP64], [${bswap64_function}], [Name of the 64/128 bit endian swapping function])
                ],
                [AC_MSG_ERROR([

Error: Could not find a way to convert 64 bit values to big endian for transport

You can ignore this error by disable binary serialization.

If you do not want to use binary serialization then it
can be disabled with:
    --disable-binary

Alternatively you can use some non standard functions implemented in ThorsSerializer
    --with-thors-network-byte-order

NOTE:
    When using binary format we need a consistent representation.
    Since the standard for 16/32 bit values is network byte order
    I want to be consistent and do the same for 64/128 bit values.

    There are standard libraries for 16/32 bit conversion between
    host and network byte order
    
        htonl() ntohl()     # 32 bit
        htons() ntohs()     # 16 bit

    But there is no standard way for larger values.
    So we use the configuration script to look for some semi-standard techniques
    The configuration script could not find any of these semi standard formats.

    If you want to use a non standard technique (implemented by Loki) you must
    explicitly ask for it with (though it is tested as correct it will not be
    faster than the semi standard ways as they rely on assembler while this code
    is standard C++ only).

        --with-thors-network-byte-order

                ])]
            )
        ]
    )
])


