# BenchBot Software Stack

![benchbot_web](./docs/benchbot_web.gif)

The BenchBot Software Stack is a collection of software packages that allow end users to control robots in real or simulated environments with a simple python API. It leverages the simple "observe, act, repeat" approach to robot problems prevalent in reinforcement learning communities ([OpenAI Gym](https://gym.openai.com/) will find the BenchBot interface extremely familiar).

DETAILS ABOUT SEMANTIC SCENE UNDERSTANDING / CHALLENGE.

This repository contains the software stack needed to develop solutions for BenchBot challenges on your local machine. It builds a mammoth Docker image (~190GB) that contains all of the software components needed to perform benchmarking in realistic 3D simulation, with all of the interfacing & configuration done for you. 

## System recommendations & requirements

The BenchBot Software Stack is designed to run seamlessly on a wide number of system configurations (currently limited to Ubuntu 18.04+). System hardware requirements are relatively high due to the nature of software being run for simulation (Unreal Engine, Nvidia Isaac, Vulkan, etc.):

- Nvidia Graphics card (GeForce GTX 1080 minimum, Titan XP+ / GeForce RTX 2070+ recommended)
- CPU with multiple cores (Intel i7-6800K minimum)
- 32GB+ RAM
- 128GB+ spare storage (an SSD storage device **strongly** recommended)

Once your system has the above requirements it should be ready to install. The install script analyses your system configuration & offers to install any missing software components interactively. The list of 3rd party software components involved includes:

- Nvidia Driver (4.18+ required, 4.30+ recommended)
- CUDA with GPU support (10.0+ required, 10.1+ recommended)
- Docker Engine - Community Edition (19.03+ required, 19.03.2+ recommended)
- Nvidia Container Toolkit (1.0+ required, 1.0.5 recommended)
- ISAAC 2019.2 SDK (requires an Nvidia developer login)

## Managing your installation

Installation is simple:

```
u@pc:~$ git clone https://github.com/RoboticVisionOrg/benchbot
u@pc:~$ benchbot/install
```

Any missing software components, or configuration issues with your system, should be detected by the install script & resolved interactively. 

The BenchBot Software Stack will frequently check for updates & can update itself automatically. To update simply run the install script again (add the `--force-clean` flag if you would like to install from scratch):

```
u@pc:~$ benchbot_install
```

If you decide to uninstall the BenchBot Software Stack, run:

```
u@pc:~$ benchbot_install --uninstall
```

## Getting started

Getting a solution up & running with BenchBot is as simple as 1,2,3:

1. Run a simulator with the BenchBot Software Stack by selecting a valid environment & task definition. For example (also see `--help`, `--list-tasks`, & `--list-envs` for more details of options):

    ```
    u@pc:~$ benchbot_run --env miniroom:1 --task semantic_slam:active:ground_truth
    ```

2. Create a solution to a BenchBot task, & run it against the software stack. The `<BENCHBOT_ROOT>/examples` directory contains some basic "hello_world" style solutions. For example, the following commands run the `hello_active` example in either a container or natively respectively (see `--help` for more details of options):

    ```
    u@pc:~$ benchbot_submit --containerised <BENCHBOT_ROOT>/examples/hello_active/ 
    ```
    ```
    u@pc:~$ benchbot_submit --native python <BENCHBOT_ROOT>/examples/hello_active/hello_active
    ```

3. Evaluate the performance of your system either directly, or automatically after your submission completes respectively:

    ```
    u@pc:~$ benchbot_eval <RESULTS_FILENAME>
    ```
    ```
    u@pc:~$ benchbot_submit --evaluate-results --native python <MY_SOLUTION>
    ```

See [benchbot_examples](https://github.com/RoboticVisionOrg/benchbot_examples) for more examples & further details of how to get up & running with the BenchBot Software Stack.

## Components of the BenchBot Software Stack

The BenchBot Software Stack is split into a number of standalone components, each with their Github repository & documentation. This repository glues them all together for you into a working system. The components of the stack are:

- **[benchbot_simulator](https://github.com/RoboticVisionOrg/benchbot_simulator):** TODO
- **[benchbot_supervisor](https://github.com/RoboticVisionOrg/benchbot_supervisor):** TODO
- **[benchbot_api](https://github.com/RoboticVisionOrg/benchbot_api):** TODO
- **[benchbot_examples](https://github.com/RoboticVisionOrg/benchbot_examples):** TODO
- **[benchbot_eval](https://github.com/RoboticVisionOrg/benchbot_eval):** TODO
