# vagrant-helpers
[![Gem](https://img.shields.io/gem/v/vagrant-helpers.svg?style=flat-square)]() [![License](https://img.shields.io/github/license/aspyatkin/vagrant-helpers.svg?style=flat-square)](https://github.com/aspyatkin/vagrant-helpers/blob/master/LICENSE)  
[Vagrant](https://www.vagrantup.com) environment customization helpers.

## Problem
Sometimes you have several Vagrant environments for one project, and these environments differ (e.g. one has bridged network, another has NAT network). More often, several people can be working on the project at the same time on their local machines. You may write `Vagrantfile` for each of your environments, but you won't be able to add this file to source control.

## Approach
The approach I came up with is quite simple. All environment settings (e.g. network) are stored in `opts.yaml` file in the directory where `Vagrantfile` exists. Vagrant parses this file and sets the specified options. You can add `Vagrantfile` to source control without exposing specific information about your environment.

Each `opts.yaml` file is stored in its own environment. It should not be added to source control. You may create `opts.example.yaml` file (and add it to source control) with a sample configuration. Thus people cloning your project would be able to set up things fast by copying this file.

## Setup
```
$ vagrant plugin install vagrant-helpers
$ cd /path/to/my/vagrant/project
$ echo "VagrantPlugins::Helpers::setup __dir__" > Vagrantfile
```

## Usage
1. Prepare `opts.yaml` file applicable to your specific environment and make your source control system ignore it;
2. Create `opts.example.yaml` file and provide it with sample environment values (like recommended Vagrant box to use and so on);
3. Use [Vagrant](https://www.vagrantup.com) as usual.

## Tips
### opts file location
If you don't want `opts.yaml` file to be located in vagrant project's directory, you can specify an other path to your opts file via `VAGRANT_HELPERS_OPTS` environment variable. This feature has been introduced in `v1.2.0`.

You have two options:
- add an environment variable before each vagrant command
`VAGRANT_HELPERS_OPTS=my-awesome-opts.yaml vagrant up`
- put an environment variable to `.env` file located in vagrant project's directory. For instance, this file may contain
`VAGRANT_HELPERS_OPTS=/absolute/path/to/my/opts/file`

`VAGRANT_HELPERS_OPTS` may contain either absolute or relative path. If relative path is specified, it is considered relative to vagrant projects's directory.

### bridged networks
To connect your virtual machine instance to the Internet via bridged interface, host computer must be connected to a routed network (home or office Wi-Fi, for example). If your router has DHCP enabled, please consider choosing and address beyond DHCP range. For instance, network is `192.168.163.0/24`, DHCP range is from `192.168.163.2` to `192.168.163.200`, so the first address for your VM to use would be `192.168.163.201`.

If you move often between different places, you might find it helpful to specify a different IP address for each of the networks you connect to. This feature has been introduced in `v1.3.0`. This is the sample configuration:
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

## License
MIT © [Alexander Pyatkin](https://github.com/aspyatkin)
