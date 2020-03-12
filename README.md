# BenchBot Software Stack

This repository contains the software stack needed to develop solutions for BenchBot challenges on your local machine. It builds a mammoth Docker image (~190GB) that contains all of the software components needed to perform benchmarking in realistic 3D simulation, with all of the interfacing & configuration done for you. 

## System Recommendations & Requirements

Hardware:

- Nvidia Graphics card (GeForce GTX 1080 minimum, Titan XP+ / GeForce RTX 2070 recommended)
- CPU with multiple cores (Intel i7-6800K minimum)
- 32GB+ RAM
- 128GB+ spare storage (SSD storage device **strongly** recommended)

Software (installation script will guide you through installing these if they are not detected):

- Nvidia Driver (4.18+ required, 4.30+ recommended)
- CUDA with GPU support (10.0+ required, 10.1+ recommended)
- Docker Engine - Community Edition (19.03+ required, 19.03.2+ recommended)
- Nvidia Container Toolkit (1.0+ required, 1.0.5 recommended)

Downloaded files (again, installation script will guide you through how to get them if missing):

- ISAAC 2019.2 SDK (requires Nvidia login)

## Getting Started

Getting a solution up & running with BenchBot is as simple as 1,2,3:

1. Install the BenchBot Software Stack via the install script (the script will examine your system, & provide you with suggestions for how to install / download / fix any missing components):

    ```
    ./install
    ```

2. Run a simulator with the BenchBot Software stack by selecting a valid environment & task definition. For example (also see `--help`, `--list-tasks`, & `--list-envs` for more details of options):

    ```
    benchbot_run --env office:1 --task semantic_slam:active:ground_truth
    ```

3. Create a solution to a BenchBot task, & run it against the software stack. The `<BENCHBOT_ROOT>/examples` directory contains some basic 'hello_world' style solutions. For example, the following commands run the `hello_active` example in either a container or natively respectively (see `--help` for more details of options):

    ```
    benchbot_submit --containerised <BENCHBOT_ROOT>/examples/hello_active/ 
    ```

    ```
    benchbot_submit --native python <BENCHBOT_ROOT>/examples/hello_active/hello_active
    ```

Note: Run `benchbot_install --uninstall` to remove the BenchBot software stack from your system 
