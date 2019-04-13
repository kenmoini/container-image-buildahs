# Container Image Registry

Welcome to the Fierce Software Container Image Registry!

Here you'll find Docker container images that are used in our development programs, for our workshops, and whatever else we or our partners might need them for.

The corresponding scripts and files that are used to create the container images are also included as part of the Git repository.

## Using the scripts

Instead of Docker, **Buildah** is used to create the containers.  Oddly enough, Buildah generates a final Docker-format container images instead of an OCI-format image because most registries (like GitLab's) can't handle OCI-format images yet.  Better safe than sorry, but changing to OCI format is as easy as removing a flag in the last line of the _buildah.sh_ scripts.

You'll need Podman, Buildah, and Skopeo

````
# yum install podman buildah skopeo
````

Then run whatever buildah.sh script you'd like.

## Container Hierarchy

These containers are built upon each other - the _base-rhel-7_ container is used in the _nginx-base-rhel-7_ container, which is then used by the _php7-nginx-rhel-7_ container, and so on.

 - base-rhel-7
   - nginx-base-rhel-7
     - php7-nginx-base-rhel-7
   - mysql-base-rhel-7
     - mysql-master-rhel-7
     - mysql-replica-rhel-7
   - redis-base-rhel-7
     - redis-master-rhel-7
     - redis-sentinel-rhel-7
     - redis-slave-rhel-7
 - base-fedora-29
   - nginx-base-fedora-29
     - php7-nginx-base-fedora-29
   - mysql-base-fedora-29
     - mysql-master-fedora-29
     - mysql-replica-fedora-29
   - redis-base-fedora-29
     - redis-master-fedora-29
     - redis-sentinel-fedora-29
     - redis-slave-fedora-29

## To do

 - Better README
 - Moar DOCS
 - Remove packages after installing in containers for compilation
 - Variablize a few things
