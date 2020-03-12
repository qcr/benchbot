# Start from the official Ubuntu image
FROM ubuntu:bionic

# Setup a base state with needed packages & useful default settings
SHELL ["/bin/bash", "-c"]
RUN apt update && apt install -yq wget gnupg2 software-properties-common git \
    vim ipython tmux iputils-ping
ARG TZ
RUN echo "$TZ" > /etc/timezone && ln -s /usr/share/zoneinfo/"$TZ" \
    /etc/localtime && apt update && apt -y install tzdata

# Install Nvidia software (Cuda & drivers)
ARG NVIDIA_DRIVER_VERSION
ARG CUDA_VERSION
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,display,graphics,utility
RUN add-apt-repository ppa:graphics-drivers && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin && \
    mv -v cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /" && \
    CUDA_NAME="cuda-$(echo "${CUDA_VERSION}" | sed 's/\([0-9]*\)\.\([0-9]*\).*/\1\.\2/')" && \
    apt update && DEBIAN_FRONTEND=noninteractive apt install -yq \
    "nvidia-driver-$(echo "${NVIDIA_DRIVER_VERSION}" | sed 's/\(^[0-9]*\).*/\1/')=${NVIDIA_DRIVER_VERSION}*" \
    "$(echo "$CUDA_NAME" | sed 's/\./-/')=${CUDA_VERSION}" && \
    ln -sv lib /usr/local/"${CUDA_NAME}"/targets/x86_64-linux/lib64 && \
    ln -sv /usr/local/"${CUDA_NAME}"/targets/x86_64-linux /usr/local/cuda

