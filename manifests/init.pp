# @summary Installs, configures, and schedules zfsmgr from the zfs_mgmt gem.
#
# @param manage_package
#   Whether to manage the zfs_mgmt gem package installation.
# @param package_name
#   Name of the gem package to install.
# @param package_ensure
#   Ensure value passed to the package resource (e.g. 'installed', 'latest', or a version string).
# @param package_provider
#   Puppet package provider used to install the gem (e.g. 'gem' or 'puppet_gem').
# @param config_dir
#   Directory containing zfsmgr TOML configuration files.
# @param purge_config_dir
#   Whether to purge unmanaged files in config_dir. Note that when enabled alongside
#   manage_local_config => true, 99-local.toml remains declared by Puppet with replace => false
#   so its contents stay unmanaged while surviving directory purging.
# @param state_dir
#   State directory used by zfsmgr (e.g. for send_state.pstore).
# @param owner
#   Default file owner for zfsmgr directories and config files.
# @param group
#   Default file group for zfsmgr directories and config files.
# @param config_dir_mode
#   Directory permissions mode for config_dir.
# @param config_file_mode
#   Default file permissions mode for generated TOML config files.
# @param state_dir_mode
#   Directory permissions mode for state_dir.
# @param config
#   Configuration hash rendered as TOML to ${config_dir}/50-puppet.toml.
# @param manage_local_config
#   Whether to create ${config_dir}/99-local.toml without managing its contents (replace => false).
# @param include_schema_comment
#   Whether to prepend the #:schema directive to generated TOML files.
# @param schema_url
#   JSON Schema URL used in the #:schema directive.
# @param configs
#   Optional hash of additional zfsmgr::config resources to declare.
# @param manage_cron
#   Whether to manage the default zfsmgr cron jobs.
# @param binary_path
#   Path to the zfsmgr executable invoked by cron jobs.
# @param cron_path
#   PATH value prefixed to cron commands (empty string or undef omits PATH=).
# @param snapshot_destroy_cron
#   Overrides for the zfsmgr-snapshot-destroy cron job.
# @param snapshot_create_cron
#   Overrides for the zfsmgr-snapshot-create cron job.
# @param send_all_cron
#   Overrides for the zfsmgr-send-all cron job.
#
# @example Basic usage
#   include zfsmgr
#
# @example Configure datasets via Hiera or class parameters
#   class { 'zfsmgr':
#     config => {
#       'mbuffer' => true,
#       'zfs'     => {
#         'tank' => {
#           'manage' => true,
#           'policy' => '10y6m4w30d24h',
#         },
#       },
#     },
#   }
class zfsmgr (
  Boolean $manage_package                  = true,
  String[1] $package_name                  = 'zfs_mgmt',
  String[1] $package_ensure                = 'installed',
  String[1] $package_provider              = 'gem',
  Stdlib::Absolutepath $config_dir         = '/etc/zfsmgr',
  Boolean $purge_config_dir                = false,
  Stdlib::Absolutepath $state_dir          = '/var/lib/zfs_mgmt',
  String[1] $owner                         = 'root',
  String[1] $group                         = 'root',
  Stdlib::Filemode $config_dir_mode        = '0755',
  Stdlib::Filemode $config_file_mode       = '0644',
  Stdlib::Filemode $state_dir_mode         = '0755',
  Hash $config                             = {},
  Boolean $manage_local_config             = true,
  Boolean $include_schema_comment          = true,
  String[1] $schema_url                    = 'https://raw.githubusercontent.com/aranc23/zfs_mgmt/master/schema/config.schema.json',
  Hash[String[1], Hash] $configs           = {},
  Boolean $manage_cron                     = true,
  Stdlib::Absolutepath $binary_path        = '/usr/local/bin/zfsmgr',
  Variant[Undef, String] $cron_path        = "/sbin:\$PATH",
  Zfsmgr::CronJob $snapshot_destroy_cron   = {},
  Zfsmgr::CronJob $snapshot_create_cron    = {},
  Zfsmgr::CronJob $send_all_cron           = {},
) {
  contain zfsmgr::install
  contain zfsmgr::configure
  contain zfsmgr::service

  Class['zfsmgr::install']
  -> Class['zfsmgr::configure']
  -> Class['zfsmgr::service']
}
