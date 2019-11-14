# BenchBot Development Software Stack

This repository contains the software stack needed to develop solutions for BenchBot challenges on your local machine. It builds a mammoth Docker image (~190GB) that contains all of the software components needed to perform benchmarking in realistic 3D simulation, with all of the interfacing & configuration done for you. 

## System Recommendations & Requirements

Hardware:

- Nvidia Graphics card (GeForce GTX 1080 minimum, Titan XP+ / GeForce RTX 2070 recommended)
- CPU with multiple cores (Intel i7-6800K minimum)
- 32GB+ RAM
- 256GB storage (SSD storage device **strongly** recommended)

Software (installation script will guide you through installing these if they are not detected):

- Nvidia Driver (4.18+ required, 4.30+ recommended)
- CUDA with GPU support (10.0+ required, 10.1+ recommended)
- Docker Engine - Community Edition (19.03+ required, 19.03.2+ recommended)
- Nvidia Container Toolkit (1.0+ required, 1.0.5 recommended)

Downloaded files (again, installation script will guide you through how to get them if missing):

- ISAAC 2019.2 SDK (requires Nvidia login)
- ISAAC 2019.2 SIM - note: **not** NavSim (requires Nvidia login)
- ISAAC SIM branch of Unreal Engine 4 (requires GitHub account, & linking to EpicGames)

## Getting Started

**NOTE: Repositories are not yet public as we are still in the development stages. This means you need to have an SSH key setup with the ACRV Bitbucket, be a member of the "BenchBot" user group in the ACRV Bitbucket team, & run the following command to copy your SSH key into the root of this repository before starting installation (ask Ben or Steve for help getting added to the Bitbucket team / group):**

```bash
cp -v ~/.ssh/id_rsa <ROOT_FOLDER_OF_THIS_REPOSITORY>
```

Getting a solution up & running with BenchBot is as simple as 1,2,3:

1. Install containerised BenchBot Development Software Stack via the install script (the script will examine your system, & provide you with suggestions for how to install / download / fix any missing components):

    ```bash
    ./install
    ```

2. Run the BenchBot Development stack by selecting a valid environment & task definition. For example (also see `--help`, `--list-tasks`, & `--list-envs` for more details of options):

    ```bash
    benchbot_run --env office:1 --task semantic_slam:active:ground_truth
    ```

3. Develop a solution to the BenchBot task, & run into against the software stack. See [benchbot_examples](https://bitbucket.org/acrv/benchbot_examples/src/master/) for some basic 'hello_world' style solutions. To run your solution (also see `--help` for more details of options):

    ```bash
    benchbot_submit --native python <PATH_TO_YOUR_SOLUTION_PYTHON_SCRIPT>
    ```

Note: Run `benchbot_install --uninstall` to remove from your system (**TODO this is it not currently implemented... for now a `docker rm $(docker ps -a -q); sudo rm -v /usr/local/bin/benchbot_*; sudo vim /etc/hosts` should be a blunt hammer to get rid of everything... be careful of the first command if you have other Docker containers installed you care about)
