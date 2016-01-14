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

    class MissingVMNameOptionError < Vagrant::Errors::VagrantError
      def error_message
        "Missing vm.name option in `opts.yaml` file!"
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

    def self.set_vm_box(config, opts)
      vm_box = opts.fetch('vm', {}).fetch('box', nil)
      if vm_box.nil?
        raise MissingVMBoxOptionError.new
      end

      config.vm.box = vm_box
    end

    def self.set_vm_name(config, opts)
      vm_name = opts.fetch('vm', {}).fetch('name', nil)
      if vm_name.nil?
        raise MissingVMNameOptionError.new
      end

      config.vm.provider :virtualbox do |v|
          v.name = vm_name
      end
    end

    def self.set_vm_memory(config, opts)
      vm_memory = opts.fetch('vm', {}).fetch('memory', 512)

      config.vm.provider :virtualbox do |v|
        v.memory = vm_memory
      end
    end

    def self.set_vm_cpus(config, opts)
      vm_cpus = opts.fetch('vm', {}).fetch('cpus', 1)

      config.vm.provider :virtualbox do |v|
        v.cpus = vm_cpus
      end
    end

    def self.set_vm_hostname(config, opts)
      vm_hostname = opts.fetch('vm', {}).fetch('hostname', nil)

      unless vm_hostname.nil?
        config.vm.hostname = vm_hostname
      end
    end

    def self.set_vm_forwarded_ports(config, opts)
      vm_forwarded_ports = opts.fetch('vm', {}).fetch('network', {}).fetch('forwarded_ports', [])

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
        if ifaddr.addr.ipv4? && ifaddr.addr.ipv4_private?
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

    def self.set_vm_public_networks(config, opts)
      vm_public_networks = opts.fetch('vm', {}).fetch('network', {}).fetch('public', [])

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

    def self.set_vm_private_networks(config, opts)
      vm_private_networks = opts.fetch('vm', {}).fetch('network', {}).fetch('private', [])

      vm_private_networks.each do |options|
        prepared_options = ::Hash[options.map { |(k, v)| [k.to_sym, v] }]
        config.vm.network :private_network, **prepared_options
      end
    end

    def self.set_vm_synced_folders(config, opts)
      vm_synced_folders = opts.fetch('vm', {}).fetch('synced_folders', [])

      vm_synced_folders.each do |entry|
        prepared_options = ::Hash[entry.fetch('opts', {}).map { |(k,v)| [k.to_sym, v] }]
        config.vm.synced_folder entry['host'], entry['guest'], **prepared_options
      end
    end

    def self.set_vm_extra_storage(config, opts)
      vm_storage_drives = opts.fetch('vm', {}).fetch('storage', [])

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

    def self.setup(dir)
      dotenv_filename = ::File.join dir, '.env'
      ::Dotenv.load

      ::Vagrant.configure(2) do |config|
        opts = get_opts dir

        set_vm_box config, opts
        set_vm_name config, opts
        set_vm_memory config, opts
        set_vm_cpus config, opts
        set_vm_hostname config, opts
        set_vm_forwarded_ports config, opts
        set_vm_public_networks config, opts
        set_vm_private_networks config, opts
        set_vm_synced_folders config, opts
        set_vm_extra_storage config, opts
      end
    end
  end
end
