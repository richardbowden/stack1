include_recipe 'stack1::base'
include_recipe 'nginx'

# disable the default site
nginx_site 'default' do
  enable false
  notifies :reload, 'service[websrvtest]', :delayed
end

#This would be generated dynamicly in production and access to a full Chef Server or other service discovery service such as consul or etcd
template "/etc/nginx/sites-available/websrvtest" do
  source "websrvtest_nginx.erb"
end

nginx_site 'websrvtest' do
  enable true
  notifies :reload, 'service[nginx]', :delayed
end
