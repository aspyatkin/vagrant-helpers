# vagrant-helpers
[![Gem](https://img.shields.io/gem/v/vagrant-helpers.svg?style=flat-square)]() [![License](https://img.shields.io/github/license/aspyatkin/vagrant-helpers.svg?style=flat-square)](https://github.com/aspyatkin/vagrant-helpers/blob/master/LICENSE)  
[Vagrant](https://www.vagrantup.com) environment customization helpers for [VirtualBox](https://www.virtualbox.org/).

## Problem
Sometimes you have several Vagrant environments for one project (development, staging), and these environments differ significantly (e.g. number of VM instances, network settings). More often, several people can be working on the project at the same time on their own machines. You may write `Vagrantfile` for each of your environments, but you won't be able to add this file to source control.

## Approach
The approach I came up with is quite simple. All environment settings are written down in `opts.yaml` file in the project directory. Then, a special code in `Vagrantfile` parses this file and sets the necessary options. Now you can add `Vagrantfile` to source control without exposing specific information about your environment.

Each `opts.yaml` file is stored in its own environment. It should not be added to source control. You may create `opts.example.yaml` file with the sample configuration and add it to source control. Thus people cloning your project would be able to set up things fast by copying this file.

## Setup
```sh
$ vagrant plugin install vagrant-helpers
$ cd /path/to/my/vagrant/project
$ echo "VagrantPlugins::Helpers::setup __dir__" > Vagrantfile
```

## Usage
1. Prepare `opts.yaml` file applicable to your specific environment and make your source control system ignore it;
2. Create `opts.example.yaml` file and provide it with sample environment values (like recommended Vagrant box to use and so on);
3. Use [Vagrant](https://www.vagrantup.com) as usual.

## Tips
### networking
By default, Vagrant sets one NAT network adapter. If you don't want to complicate things with forwarded ports (e.g. for web server), your VM instance should have another network adapter, either Host-only or Bridged.

If you are developing the project on your own, you may use Host-only network adapter. You should create a Host-only network in Virtualbox, and then set the IP address from that network to a VM instance via `opts.yaml` file. However, your VM instance will only be accessed from your host computer.

If your VM instance is supposed to be available on the entire network (e.g. office network) you have no other choice but to use Bridged network adapter. The host computer must be connected to a routed network (home or office Wi-Fi, for example). If your router has DHCP enabled, please consider choosing an IP address beyond the DHCP range. For instance, network is `192.168.163.0/24`, router leases addresses from `192.168.163.2` to `192.168.163.200`, so the first address for your VM to use would be `192.168.163.201`.

### opts file location
*This feature has been introduced in `v1.2.0`*

If you don't want `opts.yaml` file to be located in Vagrant project's directory, you can specify an other path to your opts file via `VAGRANT_HELPERS_OPTS` environment variable.

You have two options:
- add an environment variable before each Vagrant command
`VAGRANT_HELPERS_OPTS=my-awesome-opts.yaml vagrant up`
- put an environment variable to `.env` file located in Vagrant project's directory. For instance, this file may contain
`VAGRANT_HELPERS_OPTS=/absolute/path/to/my/opts/file`

`VAGRANT_HELPERS_OPTS` may contain either absolute or relative path. If relative path is specified, it is considered relative to vagrant projects's directory.

### bridged networking on demand
*This feature has been introduced in `v1.3.0`*

If you move often between different places, you may find it helpful to specify a different IP address for each of the networks you connect to. Here is the sample configuration:
```
    ...
    public:
      # At home
      - network: 192.168.163.0/24
        ip: 192.168.163.100
        bridge: 'en0: Wi-Fi (AirPort)'
      # At the office
      - network: 172.16.0.0/16
        ip: 172.16.0.17
        bridge: 'en0: Wi-Fi (AirPort)'
    ...
```
When your computer is at home (network is `192.168.163.0/24`), Vagrant will be told to set `192.168.163.100` as an IP address for your virtual machine. When your computer is at the office (network is `172.16.0.0/16`), Vagrant will be told to set `172.16.0.17` as an IP address for your virtual machine.

### multi machine configuration
*This feature has been introduced in `v1.4.0`*

You can specify the configuration for several VM instances. For more information, please refer to an example configuration file `opts.multimachine-example.yaml`.

## License
MIT © [Alexander Pyatkin](https://github.com/aspyatkin)
