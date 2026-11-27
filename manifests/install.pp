# @summary Installs the zfs_mgmt gem.
#
# @api private
class zfsmgr::install {
  assert_private()

  if $zfsmgr::manage_package {
    package { $zfsmgr::package_name:
      ensure   => $zfsmgr::package_ensure,
      provider => $zfsmgr::package_provider,
    }
  }
}
