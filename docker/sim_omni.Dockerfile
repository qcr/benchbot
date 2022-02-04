# Extend NVIDIA's official Docker Image for Isaac Sim. Download instructions:
#   https://catalog.ngc.nvidia.com/orgs/nvidia/containers/isaac-sim
FROM  nvcr.io/nvidia/isaac-sim:2021.2.1

SHELL ["/bin/bash", "-c"]
# Expects to be built with shared_tools.Dockerfile added to the end
