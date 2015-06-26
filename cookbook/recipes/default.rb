syslog_publisher_publisher_port =
  node['syslog-publisher']['publisher_port']
syslog_publisher_receiver_udp_port =
  node['syslog-publisher']['receiver_udp_port']
syslog_publisher_receiver_tcp_port =
  node['syslog-publisher']['receiver_tcp_port']
syslog_publisher_receiver_relp_port =
  node['syslog-publisher']['receiver_relp_port']
syslog_publisher_user =
  node['syslog-publisher']['user']
syslog_publisher_group =
  node['syslog-publisher']['group']
syslog_publisher_home =
  node['syslog-publisher']['home']
syslog_publisher_install_dir =
  node['syslog-publisher']['install_dir']
syslog_publisher_service_name =
  node['syslog-publisher']['service_name']
syslog_publisher_service_description =
  node['syslog-publisher']['service_description']
syslog_publisher_repository =
  node['syslog-publisher']['repository']
syslog_publisher_revision =
  node['syslog-publisher']['revision']

init_script = ::File.join('/etc/init.d', syslog_publisher_service_name)
config_file = ::File.join(syslog_publisher_home, 'config.json')

group syslog_publisher_group

user syslog_publisher_user do
  home syslog_publisher_home
  gid syslog_publisher_group
  supports manage_home: true
end

node.override['yum']['epel']['mirrorlist'] =
  'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-$releasever&arch=$basearch'
node.override['yum']['epel']['gpgkey'] =
  'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-$releasever'
include_recipe 'nodejs::default'

nodejs_npm 'forever'
nodejs_npm 'coffee-script'

directory syslog_publisher_install_dir do
  owner syslog_publisher_user
  group syslog_publisher_group
  mode 0755
end
git syslog_publisher_install_dir do
  repository syslog_publisher_repository
  revision syslog_publisher_revision
  notifies(
    :restart,
    "service[#{syslog_publisher_service_name}]",
    :delayed
  )
end

template config_file do
  source 'config.json.erb'
  owner syslog_publisher_user
  group syslog_publisher_group
  mode 0644
  variables(
    publisher_port: syslog_publisher_publisher_port,
    receiver_udp_port: syslog_publisher_receiver_udp_port,
    receiver_tcp_port: syslog_publisher_receiver_tcp_port,
    receiver_relp_port: syslog_publisher_receiver_relp_port
  )
  notifies(
    :restart,
    "service[#{syslog_publisher_service_name}]",
    :delayed
  )
end

template init_script do
  source 'syslog-publisher.erb'
  mode 0755
  variables(
    user: syslog_publisher_user,
    config: config_file,
    service_name: syslog_publisher_service_name,
    service_description: syslog_publisher_service_description,
    install_dir: syslog_publisher_install_dir
  )
  notifies(
    :restart,
    "service[#{syslog_publisher_service_name}]",
    :delayed
  )
end

service syslog_publisher_service_name do
  supports restart: true, reload: true, status: true
  action [:enable, :start]
end
