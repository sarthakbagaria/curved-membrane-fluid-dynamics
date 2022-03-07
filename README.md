## Initial Setup

1. Install Julia Lang.
2. Install Visual Studio Code.
3. Install 'Julia' extension for Visual Studio Code.
4. (For new package) Run Julia Lang application and then enter `] generate <pkg name>` to generate a new project folder with julia environment.


## Running Project
  
1. Open project folder in VS Code. 
2. Start Julia REPL using `Julia: Start REPL` in VS Code command pallete.
3. Set the Julia enviroment to project name in VS Code using `Julia: Activate This  Environment` in VS Code command pallete.
4. (First time) For a newly downloaded package, run `using Package; Pkg.instantiate()` in Julia REPL to install the packages needed for this project. 
5. Can use VS Code command pallete to run selected code via `Julia: Execute Code in REPL` or entire .jl file via `Julia: Execute Active File in REPL`.

## Using Package Manager

- To add package: `] add <package>`.

## Reference

This code was written to study the dynamics of force dipoles in spherical fluid membranes and was used for research in writing the paper:
- Bagaria, S., & Samanta, R. (2021). Dynamics of Force Dipoles in Curved Biological Membranes. arXiv preprint [arXiv:2110.05460](https://arxiv.org/abs/2110.05460).

Please refer to the paper for details.