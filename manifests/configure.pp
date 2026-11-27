# @summary Manages zfsmgr directories and TOML configuration files.
#
# @api private
class zfsmgr::configure {
  assert_private()

  file { $zfsmgr::config_dir:
    ensure  => directory,
    owner   => $zfsmgr::owner,
    group   => $zfsmgr::group,
    mode    => $zfsmgr::config_dir_mode,
    purge   => $zfsmgr::purge_config_dir,
    recurse => $zfsmgr::purge_config_dir,
    force   => $zfsmgr::purge_config_dir,
  }

  file { $zfsmgr::state_dir:
    ensure => directory,
    owner  => $zfsmgr::owner,
    group  => $zfsmgr::group,
    mode   => $zfsmgr::state_dir_mode,
  }

  zfsmgr::config { '50-puppet':
    config => $zfsmgr::config,
  }

  if $zfsmgr::manage_local_config {
    $local_header = $zfsmgr::include_schema_comment ? {
      true    => "#:schema ${zfsmgr::schema_url}\n# Local zfsmgr configuration (not managed by Puppet)\n",
      default => "# Local zfsmgr configuration (not managed by Puppet)\n",
    }

    zfsmgr::config { '99-local':
      replace => false,
      content => $local_header,
    }
  }

  $zfsmgr::configs.each |$config_name, $config_params| {
    zfsmgr::config { $config_name:
      * => $config_params,
    }
  }
}
