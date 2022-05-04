# Start from the official Ubuntu image
FROM ubuntu:bionic

# Setup a base state with needed packages & useful default settings
SHELL ["/bin/bash", "-c"]
ARG TZ
RUN echo "$TZ" > /etc/timezone && ln -s /usr/share/zoneinfo/"$TZ" \
    /etc/localtime && apt update && apt -y install tzdata
RUN apt update && apt install -yq wget gnupg2 software-properties-common git \
    vim ipython3 tmux iputils-ping

# Install Nvidia software (cuda & drivers)
# Note: the disgusting last RUN could entirely be replaced by 'apt satisfy ...'
# on Ubuntu 20.04 (apt version 2)... I cant find a pre v2 way to make apt 
# install the required version of dependencies (as opposed to just the latest)
ARG NVIDIA_DRIVER_VERSION
ARG CUDA_DRIVERS_VERSION
ARG CUDA_VERSION
ENV NVIDIA_VISIBLE_DEVICES="all"
ENV NVIDIA_DRIVER_CAPABILITIES="compute,display,graphics,utility"
RUN add-apt-repository ppa:graphics-drivers && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin && \
    mv -v cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub && \
    add-apt-repository -n "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /" && \
    apt update
RUN CUDA_NAME="cuda-$(echo "${CUDA_VERSION}" | \
    sed 's/\([0-9]*\)\.\([0-9]*\).*/\1\.\2/; s/\./-/')" && \
    NVIDIA_NAME="nvidia-driver-$(echo "${NVIDIA_DRIVER_VERSION}" | \
    sed 's/\(^[0-9]*\).*/\1/')" && \
    NVIDIA_DEPS="$(apt depends "$NVIDIA_NAME=$NVIDIA_DRIVER_VERSION" 2>/dev/null | \
    grep '^ *Depends:' | sed 's/.*Depends: \([^ ]*\) (.\?= \([^)]*\))/\1 \2/' | \
    while read d; do read a b <<< "$d"; v=$(apt policy "$a" 2>/dev/null | \
    grep "$b" | grep -vE "(Installed|Candidate)" | sed "s/.*\($b[^ ]*\).*/\1/"); \
    echo "$a=$v"; done)" && \
    CUDA_DRIVERS_DEPS="$(apt depends "cuda-drivers=$CUDA_DRIVERS_VERSION" 2>/dev/null | \
    grep '^ *Depends:' | sed 's/.*Depends: \([^ ]*\) (.\?= \([^)]*\))/\1 \2/' | \
    while read d; do read a b <<< "$d"; v=$(apt policy "$a" 2>/dev/null | \
    grep "$b" | grep -vE "(Installed|Candidate)" | sed "s/.*\($b[^ ]*\).*/\1/"); \
    echo "$a=$v"; done)" && \
    CUDA_DEPS="$(apt depends "$CUDA_NAME=$CUDA_VERSION" 2>/dev/null | \
    grep '^ *Depends:' | sed 's/.*Depends: \([^ ]*\) (.\?= \([^)]*\))/\1 \2/' | \
    while read d; do read a b <<< "$d"; v=$(apt policy "$a" 2>/dev/null | \
    grep "$b" | grep -vE "(Installed|Candidate)" | sed "s/.*\($b[^ ]*\).*/\1/"); \
    echo "$a=$v"; done)" && \
    TARGETS="$(echo "$NVIDIA_DEPS $NVIDIA_NAME=$NVIDIA_DRIVER_VERSION" \
    "$CUDA_DRIVERS_DEPS cuda-drivers=$CUDA_DRIVERS_VERSION" \
    "$CUDA_DEPS $CUDA_NAME=$CUDA_VERSION" | \
    tr '\n' ' ')" && \
    DEBIAN_FRONTEND=noninteractive apt install -yq $TARGETS
