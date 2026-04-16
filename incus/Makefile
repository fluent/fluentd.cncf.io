all:

clean:
	./build.sh clean

build:
	./build.sh image

simplestreams:
	sudo rm -rf images streams
	sudo incus-simplestreams add --alias ubuntu/20.04 --alias ubuntu/focal ./build/focal-amd64/incus.tar.xz ./build/focal-amd64/rootfs.squashfs
	sudo incus-simplestreams add --alias ubuntu/20.04 --alias ubuntu/focal ./build/focal-arm64/incus.tar.xz ./build/focal-arm64/rootfs.squashfs
	sudo incus-simplestreams add --alias ubuntu/26.04 --alias ubuntu/resolute ./build/resolute-amd64/incus.tar.xz ./build/resolute-amd64/rootfs.squashfs
	sudo incus-simplestreams add --alias ubuntu/26.04 --alias ubuntu/resolute ./build/resolute-arm64/incus.tar.xz ./build/resolute-arm64/rootfs.squashfs
