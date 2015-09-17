# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'logger'


class MissingOptsFileError < Vagrant::Errors::VagrantError
  def initialize(filename)
    @filename = filename
    super
  end

  def error_message
    "Cannot find opts file `#{@filename}`!"
  end
end


class MissingVMBoxOptionError < Vagrant::Errors::VagrantError
  def error_message
    "Missing vm.box option in `opts.yaml` file!"
  end
end


class MissingVMNameOptionError < Vagrant::Errors::VagrantError
  def error_message
    "Missing vm.name option in `opts.yaml` file!"
  end
end


def get_opts
  filename = File.join __dir__, 'opts.yaml'
  if File.exists? filename
    YAML.load File.open filename
  else
    raise MissingOptsFileError.new filename
  end
end


def set_vm_box(config, opts)
  vm_box = opts.fetch('vm', {}).fetch('box', nil)
  if vm_box.nil?
    raise MissingVMBoxOptionError.new
  end

  config.vm.box = vm_box
end


def set_vm_name(config, opts, provider = :virtualbox)
  vm_name = opts.fetch('vm', {}).fetch('name', nil)
  if vm_name.nil?
    raise MissingVMNameOptionError.new
  end

  config.vm.provider provider do |v|
      v.name = vm_name
  end
end


Vagrant.configure(2) do |config|
  opts = get_opts

  set_vm_box config, opts
  set_vm_name config, opts
end
