#!/usr/bin/bash

#
# Usage: check-repository-metadata.sh VERSION PATH_TO_REPOSITORY
#
# check-repository-metadata.sh 6.0.0 ../fluent-package-release/lts/6
#
# Note: Requires dnf-plugins-core to be installed to use the download command
#
# dnf install dnf-plugins-core

VERSION=$1
REPOSITORY_DIR=$2

function usage() {
    echo "Usage: check-repository-metadata.sh VERSION PATH_TO_REPOSITORY"
}

if [ -z "$(command -v dnf)" ]; then
    echo "ERROR: dnf command must be available"
    exit 1
fi

if [ ! -d "$REPOSITORY_DIR" ]; then
    echo "ERROR: $REPOSITORY_DIR does not exist"
    usage
    exit 1
fi

# Clean temporary files and dnf cache
rm -f *.rpm
dnf --disableplugin=system_upgrade clean all

for path in $(find $REPOSITORY_DIR -name 'repodata'); do
    relative_dir=${path%/*}
    echo $relative_dir
    rpm_file=$(find "$relative_dir" -maxdepth 1 -name "fluent-package-${VERSION}*.rpm" | head -n 1)
    if [ -z "$rpm_file" ]; then
        echo "Warning: No RPM file found in $relative_dir"
        continue
    fi
    target_arch=$(basename "$relative_dir")
    base_name=$(basename "$rpm_file")
    pkg_name="${base_name%.${target_arch}.rpm}"
    echo "Package name: ${pkg_name}"
    LANG=C dnf --disableplugin=system_upgrade --releasever=$VERSION --disablerepo="*" --repofrompath wip,$relative_dir --enablerepo wip download $pkg_name
done