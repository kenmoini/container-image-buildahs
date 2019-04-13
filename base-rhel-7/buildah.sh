#!/bin/bash -e

container=$(buildah from registry.access.redhat.com/rhel7:latest)
mountpath=$(buildah mount $container)

trap "set +e; buildah umount $container; buildah delete $container" EXIT

# Install updates
buildah run $container yum update -y && yum clean all

# Tag the image
buildah config --label maintainer="Ken Moini <ken@kenmoini.com>" $container
buildah config --created-by "Ken Moini" $container
buildah config --author "ken@kenmoini.com" $container

buildah commit --format docker $container base-rhel-7:latest
