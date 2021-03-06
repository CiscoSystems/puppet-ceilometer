# Parameters for puppet-ceilometer
#
class ceilometer::params {

  $dbsync_command =
    'ceilometer-dbsync --config-file=/etc/ceilometer/ceilometer.conf'
  $log_dir        = '/var/log/ceilometer'

  case $::osfamily {
    'RedHat': {
      # package names
      $agent_central_package_name = 'openstack-ceilometer-central'
      $agent_compute_package_name = 'openstack-ceilometer-compute'
      $api_package_name           = 'openstack-ceilometer-api'
      $collector_package_name     = 'openstack-ceilometer-collector'
      $common_package_name        = 'openstack-ceilometer-common'
      $client_package_name        = 'python-ceilometerclient'
      # service names
      $agent_central_service_name = 'openstack-ceilometer-central'
      $agent_compute_service_name = 'openstack-ceilometer-compute'
      $api_service_name           = 'openstack-ceilometer-api'
      $collector_service_name     = 'openstack-ceilometer-collector'
      # db packages
      if $::operatingsystem == 'Fedora' and $::operatingsystemrelease >= 18 {
        # name change in f18 : https://bugzilla.redhat.com/show_bug.cgi?id=954155
        $pymongo_package_name     = 'python-pymongo'
        # fallback to stdlib version, not provided on fedora
        $sqlite_package_name      = undef
      } else {
        $pymongo_package_name     = 'pymongo'
        $sqlite_package_name      = 'python-sqlite2'
      }

    }
    'Debian': {
      # package names
      $agent_central_package_name = 'ceilometer-agent-central'
      $agent_compute_package_name = 'ceilometer-agent-compute'
      $api_package_name           = 'ceilometer-api'
      $collector_package_name     = 'ceilometer-collector'
      $common_package_name        = 'ceilometer-common'
      $client_package_name        = 'python-ceilometerclient'
      # service names
      $agent_central_service_name = 'ceilometer-agent-central'
      $agent_compute_service_name = 'ceilometer-agent-compute'
      $api_service_name           = 'ceilometer-api'
      $collector_service_name     = 'ceilometer-collector'
      # db packages
      $pymongo_package_name       = 'python-pymongo'
      $sqlite_package_name        = 'python-pysqlite2'

      # Operating system specific
      case $::operatingsystem {
        'Ubuntu': {
          $libvirt_group = 'libvirtd'
        }
        default: {
          $libvirt_group = 'libvirt'
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: \
${::operatingsystem}, module ${module_name} only support osfamily \
RedHat and Debian")
    }
  }
}
