#set node attributes specific to to this recipe, plus they can be versioned
node.set['go']['owner'] = 'vagrant'
node.set['go']['group'] = 'vagrant'
node.set['go']['version'] = '1.5'
home_dir = "/home/#{node['go']['owner']}"
node.set['go']['gopath'] = File.join(home_dir, 'go')
node.set['go']['gobin'] = File.join("#{node['go']['gopath']}", 'bin')
node.set['go']['gosrc'] = File.join(node['go']['gopath'], 'src', node['backend']['websrvtest']['git_repo_path'])

node.set['backend']['websrvtest']['websrvtest_bin_path'] = File.join(home_dir, 'webserver')
node.set['backend']['websrvtest']['websrvtest_bin_name'] = 'websrvtest'
node.set['backend']['websrvtest']['websrvtest_full_path'] = File.join(node['backend']['websrvtest']['websrvtest_bin_path'], node['backend']['websrvtest']['websrvtest_bin_name'])


include_recipe 'stack1::base'
include_recipe 'golang'


req_dirs = [node['backend']['websrvtest']['websrvtest_bin_path'], node['go']['gosrc']]
req_dirs.each do |d|
  directory d do
    owner node['go']['owner']
    group node['go']['group']
    recursive true
  end
end

# we checkout the go code with git, this allows us to target specific versions
# to set what is checked out from git, revision can be either, commit id, tag, or branch name, if branch name, head will be checked out
git node['go']['gosrc'] do
  repository node['backend']['websrvtest']['git_repo_url']
  revision node['backend']['websrvtest']['tag_commit_id_or_branch']
  destination node['go']['gosrc']
  user node['go']['owner']
  group node['go']['group']
  notifies :stop, 'service[websrvtest]', :immediately
  notifies :run, 'bash[build_server]', :immediately
end


#create upstart file
template '/etc/init/websrvtest.conf' do
  source 'websrvtest_upstart.erb'
  owner 'root'
  group 'root'
  variables(
    :webserver_exec => node['backend']['websrvtest']['websrvtest_full_path']
  )
end

# this is to catch an edge case that appeared during dev, in that the compile stage failed due to the go path
# not loading correctly after install in the chef run process, running vagrant provision again things would work due
# to evn being re loaded.
bash 'build_server_if_binary_missing' do
  cwd node['go']['gosrc']
  code <<-EOH
source /etc/profile.d/golang.sh
go build -o #{node['backend']['websrvtest']['websrvtest_full_path']}
  EOH
  not_if {::File.exists?(node['backend']['websrvtest']['websrvtest_full_path'])}
  user node['go']['owner']
  group node['go']['group']
end

bash 'build_server' do
  cwd node['go']['gosrc']
  code <<-EOH
source /etc/profile.d/golang.sh
go build -o #{node['backend']['websrvtest']['websrvtest_full_path']}
  EOH
  action :nothing
  user node['go']['owner']
  group node['go']['group']
end

service 'websrvtest' do
  action [:enable, :start]
end
