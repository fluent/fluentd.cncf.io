#!/bin/bash

#
# Usage: test-verify-repo.sh 6.0.0
#
# It try to verify whether fluent-package is installable or not
# from test/experimental/6, test/experimental/lts/6 and so on.
#
# You can customize test targets via environment variables.
#
# REPO_TARGETS: It specify the target repositories (e.g. lts/5, lts/6, exp/6, exp/lts/6)
# DEB_TARGETS: It specify the target debian releases (e.g. debian:trixie, ubuntu:noble)
#              If you want to skip it, set DEB_TARGETS=dummy
# RPM_TARGETS: It specify the target RHEL compatible releases (e.g. almalinux:8)
#              If you want to skip it, set RPM_TARGETS=dummy
#
# Case 1: test recent v5/LTS
#
#   REPO_TARGETS=lts/5 ./test-verify-repo.sh 5.0.8
#
# Case 2: test recent v6/LTS (only deb) on test/experimental/lts/6
#
#   REPO_TARGETS=exp/lts/6 RPM_TARGETS=dummy ./test-verify-repo.sh 6.0.0
#
# Case 3: test recent v6/LTS (only rpm) on test/experimental/lts/6
#
#   REPO_TARGETS=exp/lts/6 DEB_TARGETS=dummy ./test-verify-repo.sh 6.0.0
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
