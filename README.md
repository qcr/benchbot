# BenchBot Software Stack

![benchbot_web](./docs/benchbot_web.gif)

The BenchBot software stack is a collection of software packages that allow end users to control robots in real or simulated environments with a simple python API. It leverages the simple "observe, act, repeat" approach to robot problems prevalent in reinforcement learning communities ([OpenAI Gym](https://gym.openai.com/) users will find the BenchBot API interface very similar).

BenchBot has been created primarily as a tool to assist in the research challenges faced by the Semantic Scene Understanding community; challenges including understanding a scene in simulation, transferring algorithms to real world systems, & meaningfully evaluating algorithm performance. The "bench" in "BenchBot" refers to benchmarking, with our goal to provide a system that greatly simplifies the benchmarking of novel algorithms in both realistic 3D simulation & on real robot platforms. 

Users performing tasks other than Semantic Scene Understanding (like object detection, 3D mapping, RGB to depth reconstruction, active vision, etc.) will also find elements of the BenchBot software stack valuable. 

This repository contains the software stack needed to develop solutions for BenchBot tasks on your local machine. It installs & configures a significant amount of software for you, wraps software in stable Docker images (~120GB), and provides simple interaction with the stack through 4 basic scripts: `benchbot_install`, `benchbot_run`, `benchbot_submit`, & `benchbot_eval`.

## System recommendations & requirements

The BenchBot software stack is designed to run seamlessly on a wide number of system configurations (currently limited to Ubuntu 18.04+). System hardware requirements are relatively high due to the nature of the software run for 3D simulation (Unreal Engine, Nvidia Isaac, Vulkan, etc.):

- Nvidia Graphics card (GeForce GTX 1080 minimum, Titan XP+ / GeForce RTX 2070+ recommended)
- CPU with multiple cores (Intel i7-6800K minimum)
- 32GB+ RAM
- 128GB+ spare storage (an SSD storage device is **strongly** recommended)

Having a system that meets the above hardware requirements is all that is required to begin installing the BenchBot software stack. The install script analyses your system configuration & offers to install any missing software components interactively. The list of 3rd party software components involved includes:

- Nvidia Driver (4.18+ required, 4.30+ recommended)
- CUDA with GPU support (10.0+ required, 10.1+ recommended)
- Docker Engine - Community Edition (19.03+ required, 19.03.2+ recommended)
- Nvidia Container Toolkit (1.0+ required, 1.0.5 recommended)
- ISAAC 2019.2 SDK (requires an Nvidia developer login)

## Managing your installation

Installation is simple:

```
u@pc:~$ git clone https://github.com/RoboticVisionOrg/benchbot && cd benchbot
u@pc:~$ ./install
```

Any missing software components, or configuration issues with your system, should be detected by the install script & resolved interactively. 

The BenchBot software stack will frequently check for updates & can update itself automatically. To update simply run the install script again (add the `--force-clean` flag if you would like to install from scratch):

```
u@pc:~$ benchbot_install
```

If you decide to uninstall the BenchBot software stack, run:

```
u@pc:~$ benchbot_install --uninstall
```

## Getting started

Getting a solution up & running with BenchBot is as simple as 1,2,3:

1. Run a simulator with the BenchBot software stack by selecting a valid environment & task definition. See `--help`, `--list-tasks`, & `--list-envs` for details on valid options. As an example:

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

See [benchbot_examples](https://github.com/RoboticVisionOrg/benchbot_examples) for more examples & further details of how to get up & running with the BenchBot software stack.

## Power tools for autonomous algorithm evaluation

Once you are confident your algorithm is a solution to the chosen task, the BenchBot software stack's power tools allow you to comprehensively explore your algorithm's performance. You can autonomously run your algorithm over multiple environments, & evaluate it holistically to produce a single summary statistic of your algorithm's performance:

1. Use the `benchbot_batch` script to autonomously run your algorithm over a number of environments & produce a set of results. The script has a number of toggles available to customise the process. See `benchbot_batch --help` for full details. Here's a basic example for autonomously running your `semantic_slam:active:ground_truth` algorithm over 3 environments:
    ```
    u@pc:~$ benchbot_batch --task semantic_slam:active:ground_truth --envs miniroom:1,miniroom:3,house:5 --native python <MY_ALGORITHM>
    ```
    Alternatively, you can use one of the pre-defined environment batches included through [benchbot_batches](https://github.com/roboticvisionorg/benchbot_batches):
    ```
    u@pc:~$ benchbot_batch --task semantic_slam:active:ground_truth --envs-file <BENCHBOT_ROOT>/batches/develop/sslam_active_gt --native python <MY_ALGORITHM>
    ```
    Additionally, you can request a results ZIP to be created & even create an overall evaluation score at the end of the batch:
    ```
    u@pc:~$ benchbot_batch --task semantic_slam:active:ground_truth --envs miniroom:1,miniroom:3,house:5 --zip --score-results --native python <MY_ALGORITHM>
    ```
    Lastly, both native & containerised submissions are supported exactly as in `benchbot_submit`:
    ```
    u@pc:~$ benchbot_batch --task semantic_slam:active:ground_truth --envs miniroom:1,miniroom:3,house:5 --containerised <MY_ALGORITHM_FOLDER>
    ```
2. The holistic evaluation performed internally by `benchbot_batch` above, can also be directly called through the `benchbot_eval` script. The script supports single result files, multiple results files, or a ZIP of multiple results files. See `benchbot_eval --help` for full details. Below are examples calling `benchbot_eval` with a series of results & a ZIP of results respectively:
    ```
    u@pc:~$ benchbot_eval -o my_jsons_scores result_1.json result_2.json result_3.json
    ```
    ```
    u@pc:~$ benchbot_eval -o my_zip_scores results.zip
    ```

## Components of the BenchBot software stack

The BenchBot software stack is split into a number of standalone components, each with their own GitHub repository & documentation. This repository glues them all together for you into a working system. The components of the stack are:

- **[benchbot_simulator](https://github.com/RoboticVisionOrg/benchbot_simulator):** a realistic 3D simulator employing Nvidia's Isaac framework, in combination with Unreal Engine environments
- **[benchbot_supervisor](https://github.com/RoboticVisionOrg/benchbot_supervisor):** a HTTP server facilitating communication between user-facing interfaces & the low-level ROS components of a simulator or real robot
- **[benchbot_api](https://github.com/RoboticVisionOrg/benchbot_api):** user-facing Python interface to the BenchBot system, allowing the user to control simulated or real robots in simulated or real world environments through simple commands
- **[benchbot_examples](https://github.com/RoboticVisionOrg/benchbot_examples):** a series of example submissions that use the API to drive a robot interactively, autonomously step through environments, evaluate dummy results, attempt semantic slam, & more
- **[benchbot_eval](https://github.com/RoboticVisionOrg/benchbot_eval):** Python library for evaluating the performance in a task, based on the results produced by a submission
- **[benchbot_batches](https://github.com/RoboticVisionOrg/benchbot_batches):** Collection of static environment lists for each of the tasks, used to produce repeatable result sets & consistent evaluation requirements

## Further information

- **[FAQs](https://github.com/RoboticVisionOrg/benchbot/wiki/FAQs):** Wiki page where answers to frequently asked questions & resolutions to common issues will be provided
- **[Semantic SLAM Tutorial](https://github.com/RoboticVisionOrg/benchbot/wiki/Tutorial:-Performing-Semantic-SLAM-with-Votenet):** a tutorial stepping through creating a semantic SLAM system in BenchBot that utilises the 3D object detector [VoteNet](https://github.com/facebookresearch/votenet)
