# -*- mode: ruby -*-
# vi: set ft=ruby :

# Here we modify the .vagrant location, this is by deafult in the same dir as
# the Vagrantfile, this is problematic when cookbooks are stored in services like
# dropbox, copy.com. created and detroying machines will force these sync serices
# to constantly uploads thes big files which is no desired.
VAGRANT_DOTFILE_PATH = File.expand_path('~/vagrant_vm_tmp')

if(ENV['VAGRANT_DOTFILE_PATH'].nil? && '.vagrant' != VAGRANT_DOTFILE_PATH)
    puts "Moving the .vagrant directory to #{VAGRANT_DOTFILE_PATH} incase we are working out of dropbox or other file syncing service, this will stop the uploading of vagrant temp files and box images\n\n"
    puts "changing metadata directory to #{VAGRANT_DOTFILE_PATH}"

    ENV['VAGRANT_DOTFILE_PATH'] = VAGRANT_DOTFILE_PATH

    puts "removing default metadata directory #{FileUtils.rm_r('.vagrant').join("\n")}\n\n"
    system 'vagrant ' + ARGV.join(' ')

    ENV['VAGRANT_DOTFILE_PATH'] = nil #for good measure
    abort 'Finished'
end

required_plugins = %w(vagrant-omnibus vagrant-berkshelf)
missing_plugins = []

required_plugins.each do |plugin|
  if !Vagrant.has_plugin?(plugin)
    missing_plugins << plugin
  end
end

if missing_plugins.length > 0
  puts 'The following plugins are required and will be instlled'
  puts '-------------------------------------------------------'
  puts missing_plugins
  puts ""

  #kill current process and rexecute
  exec "vagrant #{ARGV.join(" ")}" if ARGV[0] == 'plugin'

  missing_plugins.each do |plugin|
      # call plugin install from current process
      system("vagrant plugin install #{plugin}")
  end

  #kill current process and rexecute
  exec "vagrant #{ARGV.join(" ")}"
end

backend_boxes = [
  {
    :name => "backend001",
    :eth1 => "10.0.0.11",
    :mem => "512",
    :cpu => "2"
  },
  {
    :name => "backend002",
    :eth1 => "10.0.0.12",
    :mem => "512",
    :cpu => "2"
  }
]

frontend_boxes = [
  {
    :name => "frontend001",
    :eth1 => "10.0.0.10",
    :mem => "512",
    :cpu => "2"
  }
]

Vagrant.configure(2) do |config|
  config.omnibus.chef_version = :latest
  config.berkshelf.enabled = true

  config.vm.box = "bento/ubuntu-14.04"

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :machine
    config.cache.synced_folder_opts = {
      type: :nfs,
      mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
    }
  end

  backend_boxes.each do | box_config |
    config.vm.define box_config[:name] do |config|
      config.vm.hostname = box_config[:name]

      config.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", box_config[:mem]]
        v.customize ["modifyvm", :id, "--cpus", box_config[:cpu]]
      end
      config.vm.network :private_network, ip: box_config[:eth1]
      # config.vm.network "forwarded_port", guest: 8484, host: 8484

      config.vm.provision :chef_zero do |chef|
        chef.cookbooks_path = "cookbooks"
        chef.add_recipe "stack1::backend"
        chef.json = {
          "backend" => {
            "websrvtest" => {
              "tag_commit_id_or_branch" => "492f907e92ad6f7cce8db3abce63c564a5df3871"
            }
          }
        }

      end
    end

  end

  frontend_boxes.each do | box_config |
    config.vm.define box_config[:name] do | config |
      config.vm.hostname = box_config[:name]

      config.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", box_config[:mem]]
        v.customize ["modifyvm", :id, "--cpus", box_config[:cpu]]
      end
      config.vm.network :private_network, ip: box_config[:eth1]
      config.vm.network "forwarded_port", guest: 80, host: 8080

      config.vm.provision :chef_zero do |chef|
        chef.cookbooks_path = "cookbooks"
        chef.add_recipe "stack1::frontend"
      end
    end
  end
end
