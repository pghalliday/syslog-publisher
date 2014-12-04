require 'serverspec'

set :backend, :exec

describe service('syslog-publisher') do
  it { should be_enabled }
  it { should be_running }
end
