#!/usr/bin/bash

function error()
{
    MSG="$1"
    echo -e "\e[31;40m[ERROR]\e[0m $MSG"
}

function info()
{
    MSG="$1"
    echo -e "\e[32;40m[INFO]\e[0m $MSG"
}

function clean()
{
    sudo rm -fr build images streams focal.arm64.yaml resolute.arm64.yaml focal.amd64.yaml resolute.amd64.yaml
}

function usage()
{
    echo  "Usage: $0 image"
    exit 0
}


function build_image()
{
    TARGET_CODE=$1
    TARGET_VARIANT=$2
    TARGET_ARCH=$3
    OUTPUT_DIR="build/${TARGET_CODE}-${TARGET_ARCH}"
    mkdir -p build
    sudo distrobuilder build-incus "${TARGET_CODE}.${TARGET_ARCH}.yaml" "$OUTPUT_DIR"
    printf "ubuntu\n${TARGET_CODE}\n${TARGET_VARIANT}\n${TARGET_ARCH}\n\n" | sudo incus-simplestreams generate-metadata "$OUTPUT_DIR/incus.tar.xz"
}

function build_all_images()
{
    for code in focal resolute; do
        for arch in amd64 arm64; do
            if [ -f "build/${code}-${arch}/rootfs.squashfs" ] && [ -f "build/${code}-${arch}/incus.tar.xz" ]; then
                info "skip ${code} ${arch}"
                continue
            fi
            info "generate ${code}.${arch}.yaml"
            rm -f ${code}.${arch}.yaml
            case $arch in
                arm64)
                    sed -e "s/architecture: amd64/architecture: ${arch}/g" \
	                -e "s/focal-amd64/${code}-arm64/g" \
	                -e "s/release: focal/release: ${code}/g" \
	                -e 's,url: http://ftp.riken.jp/Linux/ubuntu,url: https://linux.yz.yamagata-u.ac.jp/pub/linux/ubuntu-ports/,' \
	                template.yaml > ${code}.${arch}.yaml
                    ;;
                amd64)
                    sed -e "s/architecture: amd64/architecture: ${arch}/g" \
	                -e "s/release: focal/release: ${code}/g" \
	                -e "s/focal-amd64/${code}-amd64/g" \
	                template.yaml > ${code}.${arch}.yaml
                    ;;
            esac
            case $code in
                focal)
                    build_image ${code} 20.04 ${arch}
                    ;;
                resolute)
                    build_image ${code} 26.04 ${arch}
                    ;;
	    esac
        done
    done
}

case $1 in
    clean)
        clean
        ;;
    image)
        build_all_images
        ;;
    *)
        usage
        ;;
esac
