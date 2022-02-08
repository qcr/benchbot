# Extend NVIDIA's official Docker Image for Isaac Sim. Download instructions:
#   https://catalog.ngc.nvidia.com/orgs/nvidia/containers/isaac-sim
FROM  nvcr.io/nvidia/isaac-sim:2021.2.1

# Overrides to make things play nicely with the BenchBot ecosystem
ENTRYPOINT /bin/bash
SHELL ["/bin/bash", "-c"]
ENV ACCEPT_EULA="Y"

# Expects to be built with shared_tools.Dockerfile added to the end
