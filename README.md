WebGL Forward+ and Clustered Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 4**

* Deze Lyu
* Tested on: **Google Chrome Version 129.0.6668.101** on macOS Sonoma Version 14.5, Apple M1 16GB

### Final Demo

The final demo is deployed as a GitHub Pages website and can be accessed [here](https://dezelyu.github.io/CIS565-Project4/).

![](img/image0.gif)

The scene was constructed in **Unity**, utilizing an environment asset purchased from the Unity Asset Store, which was modified to suit the project's objectives. The character model was designed and released by Hoyoverse for non-commercial use in compliance with their legal guidelines.

![](img/image1.png)

Please note that the final demo scene has been created on a separate branch named **creative**, as the base code was extensively modified to achieve the objectives.

### Basic Demo

This is a screen recording of the basic demo showcasing the togglable rendering techniques: forward rendering, forward+ rendering (which clusters lights in a compute pass), and clustered deferred rendering, which also utilizes the clustered light data.

![](img/image2.gif)

The basic demo is located on the **main** branch. The animated image above showcases the clustered deferred rendering, achieving approximately 30 FPS in a fullscreen Chrome browser on my MacBook Pro. In comparison, the forward+ rendering achieves around 10 FPS, while the pure forward rendering reaches only 1 FPS.

### Performance Analysis

In progress...

### Credits

- [Vite](https://vitejs.dev/): A fast build tool and development server for modern web projects.
- [loaders.gl](https://loaders.gl/): A suite of libraries for loading and processing geospatial data.
- [dat.GUI](https://github.com/dataarts/dat.gui): A lightweight GUI for changing variables in JavaScript.
- [stats.js](https://github.com/mrdoob/stats.js): A performance monitor for tracking frames per second and memory usage.
- [wgpu-matrix](https://github.com/greggman/wgpu-matrix): A WebGPU matrix math library for efficient computations.
