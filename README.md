#stack1

* This cookbook is designed to setup two backend webservers and one frontend nginx server via Vagrant.

The frontend will proxy all requests to the backend servers (round robin).

* The webserver is https://github.com/richardbowden/websrvtest

* Vagrant will set all servers to a private network of 10.0.0.x

* To access the system, once provisioned, hit http://localhost:8080



**This has been tested using the following Requirements on an OS X 10.11 host**

##Requirements
* ChefDK 0.9.0
* vagrant 1.7.4
* VirtualBox 4.3.32 (ensure the VirtualBox Extension Pack is installed)

###Vagrant plugins
these will be install automatically if not installed when `vagrant up` is used

* vagrant-berkshelf
* vagrant-cachier (nice to have)
* vagrant-omnibus


##Assumptions

* be as simple as possible for the user to run the demo stack
* only controlled via the vagrant command
* IP addresses are hard coded for this demo


##Issues
###chef-zero
chef-zero would be perfect for this, however, the current vagrant - chef-zero implementation is not yet suited (from a chef point of view) for correct modelling of multi machine vagrant setups

* chef-zero is started within each machine at provision time which means no data can be shared between multiple vm's via chef-zero
* cannot specify a node.json file to allow you to mock existing nodes, this prevents you from testing search with in recipe correctly, fix added but not in release yet, https://github.com/mitchellh/vagrant/pull/6049

chef-zero could be used external to Vagrant, this is out of the scope of this demo, as the ability to use bridged networking for vagrant machines, starting chef-zero on the host, binding to the primary nic would be required, cannot assume that would be allowed.


**To this end, ip addresses are hardcoded for the purpose of this demo**


#Cookbook

##Recipes

###default
intentionally does nothing

###backend
this recipe will configure a server to run the backend web server

1. runs apt-get update at chef compile time
1. installs golang, for node attributes see https://github.com/NOX73/chef-golang
  1. sets the go path for the vagrant user
1. checkout https://github.com/richardbowden/websrvtest at ['backend']['websrvtest']['tag_commit_id_or_branch'] to /home/vagrant/go/src/githib.com/richardbowden/websrvtest
1. build the websrvtest binary and installs to /home/vagrant/webserver/websrvtest
1. creates upstart config to start and stop the websrvtest at boot and shutdown

####Attributes

To select which version of the webserevr to install, set the following to one of the following

In the Vagrantfile, on line 105, set the value to one of the following from repo https://github.com/richardbowden/websrvtest

**default is v0.0.2**

* branch_name (checks out head)
* commit id (will search each branch for specified commit, no need to mention branch for commit id)
* tag


###frontend
This recipe will install and configure nginx to load balance between the backend servers

1. runs apt-get update at chef compile time to ensure apt caches are up to date
1. installs nginx
1. creates and enables nginx config

####Attributes

no use configurable attributes for this demo.

#Usage

1. clone repo `git clone git@github.com:richardbowden/stack1.git`

2. `cd stack1`

3. ensure the Requirements are installed, then run `vagrant up`

You should start to see the following text:

```
± % vagrant up                                                                                                                                                                                         
Moving the .vagrant directory to /Users/richard/vagrant_vm_tmp incase we are working out of dropbox or other file syncing service, this will stop the uploading of vagrant temp files and box images

changing metadata directory to /Users/richard/vagrant_vm_tmp
removing default metadata directory .vagrant

The following plugins are required and will be installed
-------------------------------------------------------
vagrant-omnibus
vagrant-berkshelf

Installing the 'vagrant-omnibus' plugin. This can take a few minutes...
Installed the plugin 'vagrant-omnibus (1.4.1)'!
Installing the 'vagrant-cachier' plugin. This can take a few minutes...
Installed the plugin 'vagrant-cachier (1.2.1)'!
Installing the 'vagrant-berkshelf' plugin. This can take a few minutes...
Installed the plugin 'vagrant-berkshelf (4.1.0)'!
Post install message from the 'vagrant-berkshelf' plugin:

The Vagrant Berkshelf plugin requires Berkshelf from the Chef Development Kit.
You can download the latest version of the Chef Development Kit from:

    https://downloads.chef.io/chef-dk/

Installing Berkshelf via other methods is not officially supported.

Bringing machine 'backend001' up with 'virtualbox' provider...
Bringing machine 'backend002' up with 'virtualbox' provider...
Bringing machine 'frontend001' up with 'virtualbox' provider...
    backend001: The Berkshelf shelf is at "/Users/richard/.berkshelf/vagrant-berkshelf/shelves/berkshelf20151102-47374-1awv754-backend001"
==> backend001: Sharing cookbooks with VM
==> backend001: Importing base box 'bento/ubuntu-14.04'...
==> backend001: Matching MAC address for NAT networking...
==> backend001: Checking if box 'bento/ubuntu-14.04' is up to date...
==> backend001: Setting the name of the VM: stack1_backend001_1446479200370_16549
==> backend001: Updating Vagrant's Berkshelf...
==> backend001: Resolving cookbook dependencies...
==> backend001: Fetching 'stack1' from source at .
```

4 . You may be asked for your user password, if you have vagrant-cachier installed...
```
==> backend001: Machine booted and ready!
==> backend001: Checking for guest additions in VM...
==> backend001: Setting hostname...
==> backend001: Configuring and enabling network interfaces...
==> backend001: Exporting NFS shared folders...
==> backend001: Preparing to edit /etc/exports. Administrator privileges will be required...
Password:
```  

5 . Once provisioned, you should be able to browse to `http://localhost:8080` you should see `Hi there, I'm served from 10.0.2.2!` This IP will be shown as this is a side effect of Vagrants network routing within the virtual machines.

**To view which host rendered the webpage, view the Response Headers in your browser and look for header `x-backend`**

6 . refresh the webpage, you will see which host is serving the current page

7 . to upgrade the backend to commit `492f907e92ad6f7cce8db3abce63c564a5df3871`, this is on the dev branch, locate line 105, change `v0.0.1` to commit id, now save the file

8. run `vagrant provision backend001 backend002`

9 . Once backend001 has finished, refresh the browser on http://localhist8080, you will see a new webpage presented, once backend002 has finished, both servers will have been upgraded.

#Tests

There are some basic serverspec tests...

these can be run as follows

`kitchen test all`
