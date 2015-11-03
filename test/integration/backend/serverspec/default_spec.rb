require 'spec_helper'

describe 'websrvtest service' do
  it 'enables the websrvtest service' do
    expect(service('websrvtest')).to be_enabled
  end
  it 'starts the websrvtest service' do
    expect(service('websrvtest')).to be_running
  end
end

describe 'upstart conf for websrvtest' do

  let(:upstart_config) { file('/etc/init/websrvtest.conf') }

  it 'creates the local configuration files' do
    expect(upstart_config).to be_a_file
    expect(upstart_config.content).to match(%r{exec /home/vagrant/webserver/websrvtest})
  end
end
