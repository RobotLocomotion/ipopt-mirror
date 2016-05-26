#!/bin/sh

# Download and build IPOPT from their SVN repository.

set -e

CMAKE_INSTALL_PREFIX=$1

IPOPT_VERSION=3.12

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
