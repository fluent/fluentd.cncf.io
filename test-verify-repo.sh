#!/bin/bash

#
# Usage: test-verify-repo.sh 6.0.0
#
# It try to verify whether fluent-package is installable or not
# from test/experimental/6, test/experimental/lts/6
#

function test_deb() {
    for d in $DEB_TARGETS; do
	if [ $d = "dummy" ]; then
	    continue
	fi
	for r in $REPO_TARGETS; do
	    echo "TEST: on $d $r"
	    LOG=logs/install-${d/:/-}-on-${r//\//-}.log
	    docker run --rm -v $(pwd):/host $d /host/test-install-in-docker.sh $USER $r $VERSION 2>&1 | tee $LOG
	    if [ ${PIPESTATUS[0]} -eq 0 ]; then
		RESULTS="$RESULTS\nOK: $d $r"
	    else
		RESULTS="$RESULTS\nNG: $d $r"
	    fi
	done
    done
}

function test_rpm() {
    for d in $RPM_TARGETS; do
	if [ $d = "dummy" ]; then
	    continue
	fi
	for r in $REPO_TARGETS; do
	    echo "TEST: on $d $r"
	    LOG=logs/install-${d/:/-}-on-${r//\//-}.log
	    docker run --rm -v $(pwd):/host $d /host/test-install-in-docker.sh $USER $r $VERSION 2>&1 | tee $LOG
	    if [ ${PIPESTATUS[0]} -eq 0 ]; then
		RESULTS="$RESULTS\nOK: $d $r"
	    else
		RESULTS="$RESULTS\nNG: $d $r"
	    fi
	done
    done
}

if [ $# -ne 1 ]; then
    echo "Usage: test-verify-repo 5.0.3"
    exit 1
fi

VERSION=$1

if [ -z "$REPO_TARGETS" ]; then
    REPO_TARGETS="exp/6 exp/lts/6"
fi
if [ -z "$DEB_TARGETS" ]; then
    case $REPO_TARGETS in
	*6*)
	    DEB_TARGETS="debian:bookworm debian:trixie ubuntu:jammy ubuntu:noble"
	    ;;
	*5*)
	    DEB_TARGETS="debian:bullseye debian:bookworm ubuntu:jammy ubuntu:noble"
	    ;;
    esac
fi
if [ -z "$RPM_TARGETS" ]; then
    case $REPO_TARGETS in
	*6*)
	    RPM_TARGETS="rockylinux:8 almalinux:9 almalinux:10 amazonlinux:2023"
	    ;;
	*5*)
	    RPM_TARGETS="rockylinux:8 almalinux:9 amazonlinux:2 amazonlinux:2023"
	    ;;
    esac
fi
echo "DEB_TARGETS: $DEB_TARGETS"
echo "RPM_TARGETS: $RPM_TARGETS"
echo "REPO_TARGETS: $REPO_TARGETS"
# give a grace period to terminate (Ctrl+C)
sleep 3
RESULTS=""
mkdir -p logs
test_deb
test_rpm
grep "Failed to install" logs/install-*.log
echo -e $RESULTS
