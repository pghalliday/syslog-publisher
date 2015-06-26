require_relative '../spec_helper'

describe 'syslog-publisher::default' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new do |node|
      node.set['syslog-publisher']['publisher_port'] =
        1234
      node.set['syslog-publisher']['receiver_udp_port'] =
        5678
      node.set['syslog-publisher']['receiver_tcp_port'] =
        6678
      node.set['syslog-publisher']['receiver_relp_port'] =
        7678
      node.set['syslog-publisher']['user'] =
        'test-user'
      node.set['syslog-publisher']['group'] =
        'test-group'
      node.set['syslog-publisher']['home'] =
        '/home/test-user'
      node.set['syslog-publisher']['install_dir'] =
        '/opt/test'
      node.set['syslog-publisher']['service_name'] =
        'test-name'
      node.set['syslog-publisher']['service_description'] =
        'test description'
      node.set['syslog-publisher']['repository'] =
        'test-repository'
      node.set['syslog-publisher']['revision'] =
        'test-branch'
    end.converge(described_recipe)
  end

  it 'should create the syslog-publisher user' do
    expect(chef_run).to create_group('test-group')
    expect(chef_run).to create_user('test-user').with(
      home: '/home/test-user',
      gid: 'test-group',
      supports: { manage_home: true }
    )
  end

  it 'should create the syslog-publisher config' do
    config_file = '/home/test-user/config.json'
    expect(chef_run).to create_template(config_file).with(
      source: 'config.json.erb',
      owner: 'test-user',
      group: 'test-group',
      mode: 0644,
      variables: {
        publisher_port: 1234,
        receiver_udp_port: 5678,
        receiver_tcp_port: 6678,
        receiver_relp_port: 7678
      }
    )
  end

  it 'should install nodejs and forever' do
    # need to override yum epel URLS as the centos 6.4 version of curl
    # does not like the HTTPS urls that are default
    expect(chef_run.node['yum']['epel']['mirrorlist']).to(
      eq('http://mirrors.fedoraproject.org/mirrorlist?repo=epel-$releasever&arch=$basearch')
    )
    expect(chef_run.node['yum']['epel']['gpgkey']).to(
      eq('http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-$releasever')
    )
    expect(chef_run).to include_recipe('nodejs::default')
    expect(chef_run).to install_nodejs_npm('forever')
    expect(chef_run).to install_nodejs_npm('coffee-script')
  end

  it 'should sync the syslog-publisher source' do
    expect(chef_run).to create_directory('/opt/test').with(
      owner: 'test-user',
      group: 'test-group',
      mode: 0755
    )
    expect(chef_run).to sync_git('/opt/test').with(
      repository: 'test-repository',
      revision: 'test-branch'
    )

    git_resource = chef_run.git('/opt/test')
    expect(git_resource).to(
      notify('service[test-name]').to(:restart).delayed
    )
  end

  it 'should start and enable the syslog-publisher service' do
    init_script = '/etc/init.d/test-name'
    expect(chef_run).to create_template(init_script).with(
      source: 'syslog-publisher.erb',
      mode: 0755,
      variables: {
        user: 'test-user',
        config: '/home/test-user/config.json',
        service_name: 'test-name',
        service_description: 'test description',
        install_dir: '/opt/test'
      }
    )
    expect(chef_run).to enable_service('test-name').with(
      supports: { restart: true, reload: true, status: true }
    )
    expect(chef_run).to start_service('test-name')
  end
end
