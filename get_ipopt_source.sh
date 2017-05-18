#!/bin/sh

# Download and build IPOPT from their SVN repository.

set -e

if [ $(dirname "$0") != "." ]; then
    echo "$0: error: must be run from top-level ipopt-mirror directory"
    exit 1
fi

IPOPT_VERSION=3.12

if [ "$1" = "--rm-before-starting" ]; then
    # Remove upstream's top-level files.
    cat <<EOF | xargs -n1 --verbose rm -f
.travis.yml
ChangeLog
Dependencies
INSTALL
LICENSE
Makefile.am
Makefile.in
README
appveyor.yml
config.guess
config.sub
configure
configure.ac
depcomp
downloaded.ASL
downloaded.Blas
downloaded.HSL
downloaded.Lapack
downloaded.Metis
downloaded.Mumps
install-sh
ltmain.sh
missing
EOF
    # Remove upstream's top-level directories.
    cat <<EOF | xargs -n1 --verbose rm -rf
.svn
BuildTools
doxydoc
Ipopt
ThirdParty
EOF
    # Ensure that only RobotLocomotion-related files exist.
    touch expected-files existing-files
cat <<EOF > expected-files
.
..
.git
.gitignore
README.md
existing-files
expected-files
get_ipopt_source.sh
remove-pedantic-errors.diff
EOF
    ls -a | LC_ALL=C sort > existing-files
    diff -U 999 existing-files expected-files
    rm -f existing-files expected-files
elif [ -n "$1" ]; then
    echo "$0: error: unknown argment"
    exit 1
fi

if [ -r "configure.ac" ]; then
    echo "$0: error: checkout is not clean; consider --rm-before-starting"
    exit 1
fi

svn checkout --non-interactive --trust-server-cert https://projects.coin-or.org/svn/Ipopt/stable/$IPOPT_VERSION .

# IPOPT needs to download yet more code for third-party depenencies,
# so do that now.
ORIG_PWD=$PWD
for i in ThirdParty/*; do
    THIRD_PARTY_LIB=`echo $i | cut -d / -f 2;`
    echo Dowloading $THIRD_PARTY_LIB...
    if [ -e downloaded.$THIRD_PARTY_LIB ]; then
	echo Already downloaded $THIRD_PARTY_LIB
	continue
    fi
    GET_SCRIPT_NAME=./get.$THIRD_PARTY_LIB
    cd $i
    if [ -x $GET_SCRIPT_NAME ]; then
	$GET_SCRIPT_NAME
    fi
    cd $ORIG_PWD
    echo Download of $THIRD_PARTY_LIB complete.
    touch downloaded.$THIRD_PARTY_LIB
done

patch -p1 < remove-pedantic-errors.diff
