<p align=center><strong>~ Our <a href="https://evalai.cloudcv.org/web/challenges/challenge-page/625/overview">Semantic Scene Understanding Challenge is live on EvalAI</a> ~<br>(prizes include $2,500USD provided by <a href="https://www.roboticvision.org/">ACRV</a> & GPUs provided by sponsors <a href="https://www.nvidia.com/en-us/research/robotics/">Nvidia</a>)</strong></p>
<p align=center><strong>~ Our <a href="https://github.com/RoboticVisionOrg/benchbot/wiki/Tutorial:-Performing-Semantic-SLAM-with-Votenet">BenchBot tutorial</a> is the best place to get started developing with BenchBot ~</strong></p>

# BenchBot Software Stack

![benchbot_web](./docs/benchbot_web.gif)

The BenchBot software stack is a collection of software packages that allow end users to control robots in real or simulated environments with a simple python API. It leverages the simple "observe, act, repeat" approach to robot problems prevalent in reinforcement learning communities ([OpenAI Gym](https://gym.openai.com/) users will find the BenchBot API interface very similar).

BenchBot was created as a tool to assist in the research challenges faced by the semantic scene understanding community; challenges including understanding a scene in simulation, transferring algorithms to real world systems, & meaningfully evaluating algorithm performance. We've since realised though, these are challenges prevalent in a wide range of robotic problems, not just semantic scene understanding.

This led us to create version 2 of BenchBot with a focus on allowing users to define their own functionality for BenchBot through [add-ons](https://github.com/roboticvisionorg/benchbot_addons). Want to integrate your own environments? Plug-in new robot platforms? Define new tasks? Share examples with others? Add evaluation measures? This all now possible with add-ons, and you don't have to do anything more than add some YAML and Python files defining your new content!

The "bench" in "BenchBot" refers to benchmarking, with our goal to provide a system that greatly simplifies the benchmarking of novel algorithms in both realistic 3D simulation & on real robot platforms. If there is something else you would like to use BenchBot for (like integrating different simulators), please let us know. We're very interested in BenchBot being the glue between your novel robotics research and whatever your robot platform may be.

This repository contains the software stack needed to develop solutions for BenchBot tasks on your local machine. It installs & configures a significant amount of software for you, wraps software in stable Docker images (~120GB), and provides simple interaction with the stack through 4 basic scripts: `benchbot_install`, `benchbot_run`, `benchbot_submit`, & `benchbot_eval`.

## System recommendations & requirements

The BenchBot software stack is designed to run seamlessly on a wide number of system configurations (currently limited to Ubuntu 18.04+). System hardware requirements are relatively high due to the nature of the software run for 3D simulation (Unreal Engine, Nvidia Isaac, Vulkan, etc.):

- Nvidia Graphics card (GeForce GTX 1080 minimum, Titan XP+ / GeForce RTX 2070+ recommended)
- CPU with multiple cores (Intel i7-6800K minimum)
- 32GB+ RAM
- 128GB+ spare storage (an SSD storage device is **strongly** recommended)

Having a system that meets the above hardware requirements is all that is required to begin installing the BenchBot software stack. The install script analyses your system configuration & offers to install any missing software components interactively. The list of 3rd party software components involved includes:

- Nvidia Driver (4.18+ required, 4.50+ recommended)
- CUDA with GPU support (10.0+ required, 10.1+ recommended)
- Docker Engine - Community Edition (19.03+ required, 19.03.2+ recommended)
- Nvidia Container Toolkit (1.0+ required, 1.0.5+ recommended)
- ISAAC 2019.2 SDK (requires an Nvidia developer login)

## Managing your installation

Installation is simple:

```
u@pc:~$ git clone https://github.com/roboticvisionorg/benchbot && cd benchbot
u@pc:~$ ./install
```

Any missing software components, or configuration issues with your system, should be detected by the install script & resolved interactively. The installation asks if you want to add BenchBot helper scripts to your `PATH`. Choosing yes will make the following commands available from any directory: `benchbot_install` (same as `./install` above), `benchbot_run`, `benchbot_submit`, `benchbot_eval`, and `benchbot_batch`.

BenchBot installs a default set of add-ons (currently `'benchbot-addons/ssu'`), but this can be changed based on how you want to use BenchBot. For example, the following will also install the `'benchbot-addons/sqa'` add-ons:

```
u@pc:~$ benchbot_install --addons benchbot-addons/ssu,benchbot-addons/sqa
```

See documentation for the [BenchBot Add-ons Manager](https://github.com/roboticvisionorg/benchbot_addons) for more information on using add-ons. The BenchBot software stack will frequently check for updates & can update itself automatically. To update simply run the install script again (add the `--force-clean` flag if you would like to install from scratch):

```
u@pc:~$ benchbot_install
```

If you decide to uninstall the BenchBot software stack, run:

```
u@pc:~$ benchbot_install --uninstall
```

There are a number of other options to customise your BenchBot installation, which are all documented under the `--help` flag:

```
u@pc:~$ benchbot_install --help
```

## Getting started

Getting a solution up & running with BenchBot is as simple as 1,2,3. Here's how to use BenchBot with content from the [semantic scene understanding add-on](https://github.com/benchbot-addons/ssu):

1. Run a simulator with the BenchBot software stack by selecting an available robot, environment, & task definition: See `--help`, `--list-robots`, `--list-tasks`, `--list-envs`, `--show-robot ROBOT_NAME` `--show-task` for details on installed options. As an example:

   ```
   u@pc:~$ benchbot_run --robot carter --env miniroom:1 --task semantic_slam:active:ground_truth
   ```

   A number of useful flags exist to help you explore what content is available in your installation (see `--help` for full details). For example, you can list what tasks are available via `--list-tasks` and view the task specification via `--show-task TASK_NAME`.

2. Create a solution to a BenchBot task, & run it against the software stack. To run a solution you must select a mode. For example, if you've created a solution in `my_solution.py` that you would like to run natively:

   ```
   u@pc:~$ benchbot_submit --native python my_solution.py
   ```

   See `--help` for other options. You also have access to all of the examples available with your installation. For instance, you can run the `hello_active` example in containerised mode via:

   ```
   u@pc:~$ benchbot_submit --containerised --example hello_active
   ```

   See `--list-examples` and `--show-example EXAMPLE_NAME` for full details on what's available out of the box.

3. Evaluate the performance of your system using a supported evaluation method (see `--list-methods`). To use the `omq` evaluation method on `my_results.json`:

   ```
   u@pc:~$ benchbot_eval --method omq my_results.json
   ```

   You can also simply run evaluation automatically after your submission completes:

   ```
   u@pc:~$ benchbot_submit --evaluate-results omq --native --example hello_eval_semantic_slam
   ```

The [BenchBot Tutorial](https://github.com/roboticvisionorg/benchbot/wiki/Tutorial:-Performing-Semantic-SLAM-with-Votenet) is a great place to start working with BenchBot; the tutorial takes the user all the way from a blank system to a working Semantic SLAM solution, with many educational steps along the way. Also remember to use the examples in your installation ([`benchbot-addons/examples_base`](https://github.com/benchbot-addons/examples_base) is a good starting point) for more examples of how to get up and running with the BenchBot software stack.

## Power tools for autonomous algorithm evaluation

Once you are confident your algorithm is a solution to the chosen task, the BenchBot software stack's power tools allow you to comprehensively explore your algorithm's performance. You can autonomously run your algorithm over multiple environments, & evaluate it holistically to produce a single summary statistic of your algorithm's performance. Here are some examples again with content from the [semantic scene understanding add-on](https://github.com/benchbot-addons/ssu):

- Use `benchbot_batch` to autonomously run your algorithm over a number of environments & produce a set of results. The script has a number of toggles available to customise the process. See `benchbot_batch --help` for full details. Here's a basic example for autonomously running your `semantic_slam:active:ground_truth` algorithm over 3 environments:

  ```
  u@pc:~$ benchbot_batch --robot carter --task semantic_slam:active:ground_truth --envs miniroom:1,miniroom:3,house:5 --native python my_solution.py
  ```

  Or you can use one of the pre-defined environment batches installed via add-ons (e.g. [`benchbot-addons/batches_isaac`](https://github.com/benchbot-addons/batches_isaac):

  ```
  u@pc:~$ benchbot_batch --robot carter --task semantic_slam:active:ground_truth --envs-batch develop_1 --native python my_solution.py
  ```

  Additionally, you can request a results ZIP to be created & even create an overall evaluation score at the end of the batch:

  ```
  u@pc:~$ benchbot_batch --robot carter --task semantic_slam:active:ground_truth --envs miniroom:1,miniroom:3,house:5 --zip --score-results omq --native python my_solution.py
  ```

  Lastly, both native & containerised submissions are supported exactly as in `benchbot_submit`:

  ```
  u@pc:~$ benchbot_batch --robot carter --task semantic_slam:active:ground_truth --envs miniroom:1,miniroom:3,house:5 --containerised my_solution_folder/
  ```

- The holistic evaluation performed internally by `benchbot_batch` above, can also be directly called through the `benchbot_eval` script. The script supports single result files, multiple results files, or a ZIP of multiple results files. See `benchbot_eval --help` for full details. Below are examples calling `benchbot_eval` with a series of results & a ZIP of results respectively:
  ```
  u@pc:~$ benchbot_eval --method omq -o my_jsons_scores result_1.json result_2.json result_3.json
  ```
  ```
  u@pc:~$ benchbot_eval --method omq -o my_zip_scores results.zip
  ```

## Using BenchBot in your research

BenchBot was made to enable & assist the development of high quality, repeatable research results. We welcome any & all use of the BenchBot software stack in your research.

To use our system, we just ask that you cite our paper on the BenchBot system. This will help us follow uses of BenchBot in the research community, & understand how we can improve the system to help support future research results. Citation details are as follows:

```
@misc{talbot2020benchbot,
    title={BenchBot: Evaluating Robotics Research in Photorealistic 3D Simulation and on Real Robots},
    author={Ben Talbot and David Hall and Haoyang Zhang and Suman Raj Bista and Rohan Smith and Feras Dayoub and Niko Sünderhauf},
    year={2020},
    eprint={2008.00635},
    archivePrefix={arXiv},
    primaryClass={cs.RO}
}
```

## Components of the BenchBot software stack

The BenchBot software stack is split into a number of standalone components, each with their own GitHub repository & documentation. This repository glues them all together for you into a working system. The components of the stack are:

- **[benchbot_api](https://github.com/roboticvisionorg/benchbot_api):** user-facing Python interface to the BenchBot system, allowing the user to control simulated or real robots in simulated or real world environments through simple commands
- **[benchbot_addons](https://github.com/roboticvisionorg/benchbot_addons):** a Python manager for add-ons in a BenchBot system with full documentation on how to create & add your own add-ons
- **[benchbot_supervisor](https://github.com/roboticvisionorg/benchbot_supervisor):** a HTTP server facilitating communication between user-facing interfaces & the underlying robot controller
- **[benchbot_robot_controller](https://github.com/roboticvisionorg/benchbot_robot_controller):** a wrapping script which controls the low-level ROS functionality of a simulator or real robot, handles automated subprocess management, & exposes interaction via a HTTP server
- **[benchbot_simulator](https://github.com/roboticvisionorg/benchbot_simulator):** a realistic 3D simulator employing Nvidia's Isaac framework, in combination with Unreal Engine environments
- **[benchbot_eval](https://github.com/roboticvisionorg/benchbot_eval):** Python library for evaluating the performance in a task, based on the results produced by a submission

## Further information

- **[FAQs](https://github.com/roboticvisionorg/benchbot/wiki/FAQs):** Wiki page where answers to frequently asked questions & resolutions to common issues will be provided
- **[Semantic SLAM Tutorial](https://github.com/roboticvisionorg/benchbot/wiki/Tutorial:-Performing-Semantic-SLAM-with-Votenet):** a tutorial stepping through creating a semantic SLAM system in BenchBot that utilises the 3D object detector [VoteNet](https://github.com/facebookresearch/votenet)

## Supporters

Development of the BenchBot software stack was directly supported by:

[![Australian Centre for Robotic Vision](./docs/acrv_logo_small.png)](https://www.roboticvision.org/)&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;[![QUT Centre for Robotics](./docs/qcr_logo_small.png)](https://research.qut.edu.au/qcr/)
