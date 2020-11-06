# Start from the official Ubuntu image
ARG OS_VERSION
FROM ubuntu:${OS_VERSION}

# Setup a base state with needed packages & useful default settings
SHELL ["/bin/bash", "-c"]
ARG TZ
RUN echo "$TZ" > /etc/timezone && ln -s /usr/share/zoneinfo/"$TZ" \
    /etc/localtime && apt update && apt -y install tzdata
RUN apt update && apt install -yq wget gnupg2 software-properties-common git \
    vim ipython3 tmux iputils-ping

# Install Nvidia software (Cuda & drivers)
ARG NVIDIA_DRIVER_VERSION
ARG CUDA_DRIVERS_VERSION
ARG CUDA_VERSION
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,display,graphics,utility
RUN add-apt-repository ppa:graphics-drivers && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin && \
    mv -v cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    add-apt-repository -n "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /" && \
    CUDA_NAME="cuda-$(echo "${CUDA_VERSION}" | \
    sed 's/\([0-9]*\)\.\([0-9]*\).*/\1\.\2/; s/\./-/')" && \
    NVIDIA_NAME="nvidia-driver-$(echo "${NVIDIA_DRIVER_VERSION}" | \
    sed 's/\(^[0-9]*\).*/\1/')" && \
    REQ="${NVIDIA_NAME} (>=${NVIDIA_DRIVER_VERSION}), " && \
    REQ+="cuda-drivers (>=${CUDA_DRIVERS_VERSION}), ${CUDA_NAME} (>=${CUDA_VERSION})" && \
    apt update && DEBIAN_FRONTEND=noninteractive apt satisfy -yq "$REQ"
