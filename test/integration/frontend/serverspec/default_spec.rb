require 'spec_helper'

describe 'nginx service' do
  it 'enables the nginx service' do
    expect(service('nginx')).to be_enabled
  end
  it 'starts the nginx service' do
    expect(service('nginx')).to be_running
  end
end

describe 'nginx conf for websrvtest' do

  let(:nginx_config) { file('/etc/nginx/sites-available/websrvtest') }

  it 'creates the local configuration files' do
    expect(nginx_config).to be_a_file
    expect(nginx_config.content).to match(%r{server 10.0.0.11:8484 max_fails=1 fail_timeout=10s;})
  end
end
