# vagrant-helpers
[Vagrant](https://www.vagrantup.com) environment customization helpers.

## Problem
Sometimes you have several Vagrant environments for one project, and these environments differ (e.g. one has bridged network, another has NAT network). More often, several people can be working on the project at the same time on their local machines. You may write `Vagrantfile` for each of your environments, but you won't be able to add this file to source control.

## Approach
The approach I came up with is quite simple. All environment settings (e.g. network) are stored in `opts.yaml` file in the directory where `Vagrantfile` exists. `Vagrantfile` parses this file and sets the specified options. You can add `Vagrantfile` to source control without exposing specific information about your environment.

Each `opts.yaml` file is stored in its own environment. It should not be added to source control. You may create `opts.yaml.example` file (and add it to source control) with a sample configuration. Thus people cloning your project would be able to set up things fast by copying this file.

## Setup
For now, there is no convenient installation method available. Basically, you should copy this stuff from `Vagrantfile` in this repo to your `Vagrantfile`:
- `MissingOptsFileError` class,
- `get_opts` method,
- other methods you need, e.g. `set_vm_box`, `set_vm_memory` etc.

## Usage
1. Prepare `Vagrantfile` (see previous chapter);
2. Prepare `opts.yaml` file applicable to your specific environment and make your source control system ignore it;
3. Create `opts.yaml.example` file and provide it with sample environment values (like recommended Vagrant box to use and so on);
4. Use [Vagrant](https://www.vagrantup.com) as usual.

## License
MIT © [Alexander Pyatkin](https://github.com/aspyatkin)
