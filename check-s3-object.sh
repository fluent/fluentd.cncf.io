#!/usr/bin/bash

#
# Usage: check-s3-object.sh OPTIONS...
#
# e.g. ./check-s3-object.sh \
#           --channel 'lts/6' --repo_dir ../fluent-package-release/test/experimental \
#           --bucket fluentd --profile fluentd-r2 --pattern "fluent-package-6.0.3*.rpm" \
#           --endpoint_url https://ACCOUNT_ID.r2.cloudflarestorage.com
#
# e.g. ./check-s3-object.sh \
#           --channel '6' --repo_dir ../fluent-package-release \
#           --bucket fluentd --profile fluentd-r2 --pattern "fluent-package-6.0.0*.rpm" \
#           --endpoint_url https://ACCOUNT_ID.r2.cloudflarestorage.com
#
# It will check local files and already uploaded S3 object consistency.

OPTS=$(getopt -o c: -l debug,channel:,repo_dir:,endpoint_url:,pattern:,bucket:,profile: -- "$@")

eval set -- "$OPTS"

CHECK_ETAG=1
ENDPOINT_URL=""
BUCKET=""
PROFILE=""
DEBUG=0
ERROR_COUNT=0

while true; do
    case "$1" in
        --channel)
            CHANNEL="$2"
            shift 2
            ;;
        --repo_dir)
            REPO_DIR="${2%/}"
            shift 2
            ;;
        --endpoint_url)
            ENDPOINT_URL="$2"
            shift 2
            ;;
        --pattern)
            PATTERN="$2"
            shift 2
            ;;
        --bucket)
            BUCKET="$2"
            shift 2
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

if [ ! -d "$REPO_DIR" ]; then
    echo -e "\e[31;40m[ERROR]\e[0m --repo_dir should not be empty"
    exit 1
fi
if [ -z "$CHANNEL" ]; then
    echo -e "\e[31;40m[ERROR]\e[0m --channel should not be empty (e.g. lts/6)"
    exit 1
fi
if [ -z "$BUCKET" ]; then
    echo -e "\e[31;40m[ERROR]\e[0m --bucket should not be empty (e.g. fluentd)"
    exit 1
fi
if [ -z "$PROFILE" ]; then
    echo -e "\e[31;40m[ERROR]\e[0m --profile should not be empty (e.g. fluentd)"
    exit 1
fi
if [ -z "$ENDPOINT_URL" ]; then
    echo -e "\e[31;40m[ERROR]\e[0m --endpoint_url should not be empty"
    exit 1
fi
if [ -z "$PATTERN" ]; then
    echo -e "\e[31;40m[ERROR]\e[0m --pattern should not be empty (e.g. fluent-package-6.0.3*.rpm)"
    exit 1
fi

WORKING_DIR=$(mktemp -d)

echo "channel: $CHANNEL"
echo "endpoint_url: $ENDPOINT_URL"
echo "pattern: $PATTERN"
echo "bucket: $BUCKET"
echo "profile: $PROFILE"
echo "repo_dir: $REPO_DIR"

export AWS_PAGER=""
mkdir -p $WORKING_DIR

for channel in $CHANNEL; do
    echo "checking $channel"
    for pkg in $(find $REPO_DIR/$channel -name "$PATTERN"); do
        case $REPO_DIR in
            *test/experimental*)
                relative_path="test/experimental/${pkg##*test/experimental/}"
                ;;
            *)
                case $channel in
                    *lts*)
                        relative_path="lts${pkg##*lts}"
                        ;;
                    *6*)
                        relative_path="6/${pkg##*6/}"
                        ;;
                esac
                ;;
        esac
        relative_dir=${relative_path%/*}
        mkdir -p $WORKING_DIR/$relative_dir
        rm -fr $WORKING_DIR/$relative_path
        etag_curl=$(curl --silent -I https://fluentd.cdn.cncf.io/$relative_path | \grep -i etag | cut -d' ' -f2 | sed -e 's/"//g' | tr -d '\r\n')
        response=$(aws s3api head-object --bucket $BUCKET --profile $PROFILE --endpoint-url $ENDPOINT_URL --key $relative_path)
        if [ $DEBUG -eq 1 ]; then
            echo "etag via curl: ${etag_curl}"
            echo "relative path: $relative_path"
            echo "head-object: $response"
        fi
        etag_api=$(echo "$response" | jq --raw-output .ETag | sed -e 's/"//g' | tr -d '\n')
        if [ "${etag_curl}" = "${etag_api}" ]; then
            echo -e "\e[32;40m[PASS]\e[0m etag <$etag_api> $relative_path"
        else
            echo -e "\e[31;40m[FAIL]\e[0m etag <$etag_curl> <> <$etag_api> $relative_path"
            echo -e " r2: |$etag_curl|"
            echo -e "api: |$etag_api|"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi

        
        curl --silent -o $WORKING_DIR/$relative_path https://fluentd.cdn.cncf.io/$relative_path
        r2_md5sum=$(md5sum $WORKING_DIR/$relative_path | cut -d' ' -f1)
        if [ "$etag_api" = "$r2_md5sum" ]; then
            echo -e "\e[32;40m[PASS]\e[0m etag <$etag_api> equal to md5sum checksum, no multipart upload $relative_path"
        else
            echo -e "\e[31;40m[FAIL]\e[0m etag <$etag_api> multipart upload $relative_path"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi

        local_sha256=$(sha256sum $pkg | cut -d' ' -f1)
        r2_sha256=$(sha256sum $WORKING_DIR/$relative_path | cut -d' ' -f1)
        if [ "$local_sha256" = "$r2_sha256" ]; then
            echo -e "\e[32;40m[PASS]\e[0m checksum $local_sha256 $relative_path"
        else
            echo -e "\e[31;40m[FAIL]\e[0m checksum $relative_path"
            echo -e "  local: $local_sha256"
            echo -e "     r2: $r2_sha256"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi

        pop=$(curl --silent -I https://fluentd.cdn.cncf.io/$relative_path | \grep -i cf-ray | tr -d '\r\n')
        echo -e "\e[35;40m[INFO]\e[0m PoP $pop"
    done
done
rm -rf $WORKING_DIR
exit $ERROR_COUNT
