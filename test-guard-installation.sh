#!/bin/bash

#
# Usage: test-guard-installation.sh
#
# If user try to install wrong release of debian/ubuntu, it should cause
# abort as a fool-proof. This test script checks sh/install-*.sh behavior.
#

function test_deb() {
    for d in $DEB_TARGETS; do
	if [ $d = "dummy" ]; then
	    continue
	fi
        if [ $d = "" ]; then
            continue
        fi
        SUPPORTED_TARGETS="debian:bookworm debian:trixie ubuntu:jammy ubuntu:noble ubuntu:resolute"
	for s in $SUPPORTED_TARGETS; do
            if [ $d = "$s" ]; then
                # skip successful case
                continue
            fi
	    echo "TEST: install $s on $d"
            for pkg in fluent-package6 fluent-package6-lts; do
                test_script=sh/install-${s/:/-}-${pkg}.sh
                launcher_script=test-install-failure-in-docker.sh
                if [ -f ${test_script} ]; then
	            chmod 755 ${test_script}
                else
                    echo -e "[\e[35;40mSKIP\e[0m] no such ${test_script}"
                    continue
                fi
                docker run --rm -v $(pwd):/host $DOCKER_CLI_EXTRA_OPTIONS $d /host/${launcher_script} $USER /host/${test_script}
                if [ ${PIPESTATUS[0]} -eq 0 ]; then
                    MSG="[\e[31;40mFAIL\e[0m] succeeded ${test_script} on $d (unexpected)"
		    echo -e $MSG
                    RESULTS="$RESULTS\n$MSG"
	        else
		    # expected to be failed.
                    MSG="[\e[32;40mPASS\e[0m] failed ${test_script} on $d (expected)"
                    echo -e $MSG
                    RESULTS="$RESULTS\n$MSG"
	        fi
            done
	done
    done
}

if [ -z "$DEB_TARGETS" ]; then
    DEB_TARGETS="debian:bookworm debian:trixie ubuntu:jammy ubuntu:noble ubuntu:resolute"
fi
echo "DEB_TARGETS: $DEB_TARGETS"
RESULTS=""
test_deb
echo -e $RESULTS
