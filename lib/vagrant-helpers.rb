require 'vagrant'
require 'yaml'
require 'dotenv'
require 'socket'
require 'ipaddr'
require 'ip'


module VagrantPlugins
  module Helpers
    class MissingOptsFileError < ::Vagrant::Errors::VagrantError
      def initialize(filename)
        @filename = filename
        super
      end

      def error_message
        "Cannot find opts file `#{@filename}`!"
      end
    end

    class MissingVMBoxOptionError < ::Vagrant::Errors::VagrantError
      def error_message
        "Missing vm.box option in `opts.yaml` file!"
      end
    end

    class MissingVMNameOptionError < ::Vagrant::Errors::VagrantError
      def error_message
        "Missing vm.name option in `opts.yaml` file!"
      end
    end

    class AmbiguousConfigurationError < ::Vagrant::Errors::VagrantError
      def error_message
        "Ambiguous configuration found in `opts.yaml` file! Specify either `vm` or `vms` key, not both of them!"
      end
    end

    def self.get_opts(dir)
      filename = ::File.expand_path(ENV['VAGRANT_HELPERS_OPTS'] || 'opts.yaml', dir)
      if ::File.exists? filename
        ::YAML.load ::File.open filename
      else
        raise MissingOptsFileError.new filename
      end
    end

    def self.set_vm_box(config, vm_box)
      if vm_box.nil?
        raise MissingVMBoxOptionError.new
      end

      config.vm.box = vm_box
    end

    def self.set_vm_name(config, vm_name)
      if vm_name.nil?
        raise MissingVMNameOptionError.new
      end

      config.vm.provider :virtualbox do |v|
        v.name = vm_name
      end
    end

    def self.set_vm_memory(config, vm_memory)
      config.vm.provider :virtualbox do |v|
        v.memory = vm_memory
      end
    end

    def self.set_vm_cpus(config, vm_cpus)
      config.vm.provider :virtualbox do |v|
        v.cpus = vm_cpus
      end
    end

    def self.set_vm_hostname(config, vm_hostname)
      unless vm_hostname.nil?
        config.vm.hostname = vm_hostname
      end
    end

    def self.set_vm_forwarded_ports(config, vm_forwarded_ports)
      vm_forwarded_ports.each do |options|
        prepared_options = ::Hash[options.map { |(k, v)| [k.to_sym, v] }]
        config.vm.network :forwarded_port, **prepared_options
      end
    end

    def self.get_cidr_mask(mask)
       Integer(32 - Math.log2((IPAddr.new(mask, Socket::AF_INET).to_i ^ 0xffffffff) + 1))
    end

    def self.get_host_networks
      host_networks = []

      Socket.getifaddrs.each do |ifaddr|
        if ifaddr.addr.ipv4? && ifaddr.addr.ipv4_private? && ifaddr.netmask.ipv4?
          machine_address = IP.new ifaddr.addr.ip_address
          netmask = IP.new ifaddr.netmask.ip_address
          network_address = machine_address & netmask
          host_networks << IP.new("#{network_address}/#{get_cidr_mask ifaddr.netmask.ip_address}")
        end
      end

      host_networks
    end

    def self.host_in_network?(network_addr)
      get_host_networks.any? { |host_network| host_network.eql? network_addr }
    end

    def self.set_vm_public_networks(config, vm_public_networks)
      network_list = []

      vm_public_networks.each do |options|
        if options.has_key? 'network'
          network_addr = IP.new options.delete 'network'
          if host_in_network? network_addr
            network_list << options
            break
          end
        else
          network_list << options
        end
      end

      network_list.each do |network_options|
        options_sym_hash = ::Hash[network_options.map { |(k, v)| [k.to_sym, v] }]
        config.vm.network :public_network, **options_sym_hash
      end
    end

    def self.set_vm_private_networks(config, vm_private_networks)
      vm_private_networks.each do |options|
        prepared_options = ::Hash[options.map { |(k, v)| [k.to_sym, v] }]
        config.vm.network :private_network, **prepared_options
      end
    end

    def self.set_vm_synced_folders(config, vm_synced_folders)
      vm_synced_folders.each do |entry|
        prepared_options = ::Hash[entry.fetch('opts', {}).map { |(k,v)| [k.to_sym, v] }]
        config.vm.synced_folder entry['host'], entry['guest'], **prepared_options
      end
    end

    def self.set_vm_extra_storage(config, vm_storage_drives)
      config.vm.provider :virtualbox do |v|
        vm_storage_drives.each_with_index do |entry, ndx|
          unless ::File.exists? entry['filename']
            # create hdd
            v.customize [
              'createhd',
              '--filename',
              entry['filename'],
              '--size',
              entry['size']
            ]
          end

          # attach hdd
          v.customize [
            'storageattach',
            :id,
            '--storagectl',
            entry['controller'] || 'SATA',
            '--port',
            ndx + 1,
            '--device',
            0,
            '--type',
            'hdd',
            '--medium',
            entry['filename']
          ]
        end
      end
    end

    def self.each_vm(opts)
      if opts.has_key?('vm') and opts.has_key?('vms')
        raise AmbiguousConfigurationError.new
      end

      if opts.has_key? 'vm'
        vm_opts = opts['vm']
        yield nil, vm_opts
      end

      if opts.has_key? 'vms'
        opts['vms'].each do |name, vm_opts|
          yield name, vm_opts
        end
      end
    end

    def self.setup_instance(config, vm_opts)
      set_vm_box config, vm_opts.fetch('box', nil)
      set_vm_name config, vm_opts.fetch('name', nil)
      set_vm_memory config, vm_opts.fetch('memory', 512)
      set_vm_cpus config, vm_opts.fetch('cpus', 1)
      set_vm_hostname config, vm_opts.fetch('hostname', nil)
      set_vm_forwarded_ports config, vm_opts.fetch('network', {}).fetch('forwarded_ports', [])
      set_vm_public_networks config, vm_opts.fetch('network', {}).fetch('public', [])
      set_vm_private_networks config, vm_opts.fetch('network', {}).fetch('private', [])
      set_vm_synced_folders config, vm_opts.fetch('synced_folders', [])
      set_vm_extra_storage config, vm_opts.fetch('storage', [])
    end

    def self.setup(dir)
      dotenv_filename = ::File.join dir, '.env'
      ::Dotenv.load

      ::Vagrant.configure(2) do |config|
        opts = get_opts dir

        each_vm(opts) do |name, vm_opts|
          if name.nil?
            # there is one instance only
            setup_instance config, vm_opts
          else
            # there are several instances
            config.vm.define name do |instance_config|
              setup_instance instance_config, vm_opts
            end
          end
        end
      end
    end
  end
end
