# vagrant-helpers
[Vagrant](https://www.vagrantup.com) environment customization helpers.

## Problem
Sometimes you have several Vagrant environments for the one project, and these environments differ (e.g. one has bridged network, another has NAT network). You may write `Vagrantfile` for each of your environment, but you won't be able to add it to source control.

## Approach
So, the approach is quite simple. All environment settings (e.g. network) are stored in `opts.yaml` file in the directory where `Vagrantfile` exists. `Vagrantfile` parses this file and sets the specified options. You can add `Vagrantfile` to source control without exposing specific information about you environment.

Each `opts.yaml` file is stored in its own environment. It is not added to source control. You may create `opts.yaml.example` file (and add it to the repository) with a sample configuration. Thus people cloning your project would be able to set up things fast by copying this file.
