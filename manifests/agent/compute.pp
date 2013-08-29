# The ceilometer::agent::compute class installs the ceilometer compute agent
# Include this class on all nova compute nodes
#
# == Parameters
#  [*auth_url*]
#    the keystone public endpoint
#    Optional. Defaults to 'http://localhost:5000/v2.0'
#
#  [*auth_region*]
#    the keystone region of this compute node
#    Optional. Defaults to 'RegionOne'
#
#  [*auth_user*]
#    the keystone user for ceilometer services
#    Optional. Defaults to 'ceilometer'
#
#  [*auth_password*]
#    the keystone password for ceilometer services
#    Optional. Defaults to 'password'
#
#  [*auth_tenant_name*]
#    the keystone tenant name for ceilometer services
#    Optional. Defaults to 'services'
#
#  [*auth_tenant_id*]
#    the keystone tenant id for ceilometer services.
#    Optional. Defaults to empty.
#
#  [*auth_cacert*]
#    Certificate chain for SSL validation. Optional; Defaults to 'None'
#
#  [*enabled*]
#    should the service be started or not
#    Optional. Defaults to true
#
class ceilometer::agent::compute (
  $auth_url         = 'http://localhost:5000/v2.0',
  $auth_region      = 'RegionOne',
  $auth_user        = 'ceilometer',
  $auth_password    = 'password',
  $auth_tenant_name = 'services',
  $auth_tenant_id   = '',
  $auth_cacert      = undef,
  $enabled          = true,
) inherits ceilometer {

  include ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-agent-compute']

  Package['ceilometer-agent-compute'] -> Service['ceilometer-agent-compute']
  package { 'ceilometer-agent-compute':
    ensure => installed,
    name   => $::ceilometer::params::agent_compute_package_name,
  }

  if ! $auth_cacert {
    ceilometer_config { 'DEFAULT/os_cacert': ensure => absent }
  } else {
    ceilometer_config { 'DEFAULT/os_cacert': value => $auth_cacert }
  }


  if $::ceilometer::params::libvirt_group {
    User['ceilometer'] {
      groups +> [$::ceilometer::params::libvirt_group]
    }
  }


  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Package['ceilometer-common'] -> Service['ceilometer-agent-compute']
  service { 'ceilometer-agent-compute':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::agent_compute_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

  ceilometer_config {
    'DEFAULT/os_auth_url'         : value => $auth_url;
    'DEFAULT/os_auth_region'      : value => $auth_region;
    'DEFAULT/os_username'         : value => $auth_user;
    'DEFAULT/os_password'         : value => $auth_password;
    'DEFAULT/os_tenant_name'      : value => $auth_tenant_name;
  }

  if ($auth_tenant_id != '') {
    ceilometer_config {
      'DEFAULT/os_tenant_id'        : value => $auth_tenant_id;
    }
  }

  nova_config {
    'DEFAULT/instance_usage_audit'        : value => 'True';
    'DEFAULT/instance_usage_audit_period' : value => 'hour';
  }

  #NOTE(dprince): This is using a custom (inline) file_line provider
  # until this lands upstream:
  # https://github.com/puppetlabs/puppetlabs-stdlib/pull/174
  Nova_config<| |> {
    before +> File_line_after[
      'nova-notification-driver-common',
      'nova-notification-driver-ceilometer'
    ],
  }

  file_line_after {
    'nova-notification-driver-common':
      line   =>
        'notification_driver=nova.openstack.common.notifier.rpc_notifier',
      path   => '/etc/nova/nova.conf',
      after  => '\[DEFAULT\]',
      notify => Service['nova-compute'];
    'nova-notification-driver-ceilometer':
      line   => 'notification_driver=ceilometer.compute.nova_notifier',
      path   => '/etc/nova/nova.conf',
      after  => '\[DEFAULT\]',
      notify => Service['nova-compute'];
  }

}
