# @summary Manages a TOML configuration file under the zfsmgr config directory.
#
# @param ensure
#   File ensure state ('file', 'present', or 'absent').
# @param config
#   Configuration hash to serialize to TOML using stdlib::to_toml.
#   Mutually exclusive with content.
# @param content
#   Raw TOML content to write verbatim. Mutually exclusive with config.
# @param replace
#   Whether to overwrite an existing file when its contents differ.
# @param config_dir
#   Directory in which to place the file. Defaults to $zfsmgr::config_dir.
# @param owner
#   File owner. Defaults to $zfsmgr::owner.
# @param group
#   File group. Defaults to $zfsmgr::group.
# @param mode
#   File mode. Defaults to $zfsmgr::config_file_mode.
# @param include_schema_comment
#   Whether to prepend the #:schema directive when rendering config.
#   Defaults to $zfsmgr::include_schema_comment.
#
# @example Adding a role/profile configuration snippet
#   zfsmgr::config { '60-backups':
#     config => {
#       'zfs' => {
#         'tank/backups' => {
#           'send'        => true,
#           'destination' => 'zfs_recv@backup.example.com:backup/tank',
#         },
#       },
#     },
#   }
define zfsmgr::config (
  Enum['present', 'absent', 'file'] $ensure = 'file',
  Optional[Hash] $config                    = undef,
  Optional[String] $content                 = undef,
  Boolean $replace                          = true,
  Optional[Stdlib::Absolutepath] $config_dir = undef,
  Optional[String[1]] $owner                = undef,
  Optional[String[1]] $group                = undef,
  Optional[Stdlib::Filemode] $mode          = undef,
  Optional[Boolean] $include_schema_comment = undef,
) {
  include zfsmgr

  if $config != undef and $content != undef {
    fail("zfsmgr::config[${title}]: 'config' and 'content' are mutually exclusive")
  }

  $_config_dir = pick($config_dir, $zfsmgr::config_dir)
  $_owner      = pick($owner, $zfsmgr::owner)
  $_group      = pick($group, $zfsmgr::group)
  $_mode       = pick($mode, $zfsmgr::config_file_mode)
  $_include_schema = $include_schema_comment ? {
    undef   => $zfsmgr::include_schema_comment,
    default => $include_schema_comment,
  }

  $filename = $name ? {
    /\.toml$/ => $name,
    default   => "${name}.toml",
  }

  if $config != undef {
    $schema_header = $_include_schema ? {
      true    => "#:schema ${zfsmgr::schema_url}\n",
      default => '',
    }
    $toml_body = stdlib::to_toml($config)
    $file_content = $toml_body ? {
      ''      => "${schema_header}# Managed by Puppet\n",
      default => "${schema_header}# Managed by Puppet\n\n${toml_body}",
    }
  } else {
    $file_content = $content
  }

  file { "${_config_dir}/${filename}":
    ensure  => $ensure,
    owner   => $_owner,
    group   => $_group,
    mode    => $_mode,
    replace => $replace,
    content => $file_content,
    require => File[$zfsmgr::config_dir],
  }
}
