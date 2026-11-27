# zfsmgr

Puppet module to install the `zfs_mgmt` RubyGem, manage `/etc/zfsmgr/*.toml` configuration files and `/var/lib/zfs_mgmt`, and schedule `zfsmgr` cron jobs.

## Table of Contents

1. [Description](#description)
1. [Setup](#setup)
    * [Requirements](#requirements)
    * [Beginning with zfsmgr](#beginning-with-zfsmgr)
1. [Usage](#usage)
    * [Basic usage](#basic-usage)
    * [Configuring datasets via `$config`](#configuring-datasets-via-config)
    * [Purging `/etc/zfsmgr` while keeping `99-local.toml`](#purging-etczfsmgr-while-keeping-99-localtoml)
    * [Adding role/profile config snippets with `zfsmgr::config`](#adding-roleprofile-config-snippets-with-zfsmgrconfig)
    * [Customizing cron schedules](#customizing-cron-schedules)
1. [Reference](#reference)

## Description

`zfsmgr` automates the setup of [`zfs_mgmt`](https://github.com/aranc23/zfs_mgmt):

* **`zfsmgr::install`**: Installs the `zfs_mgmt` gem.
* **`zfsmgr::configure`**: Manages `/etc/zfsmgr` (with optional directory purging), `/var/lib/zfs_mgmt` (for `send_state.pstore`), `/etc/zfsmgr/50-puppet.toml` rendered from `$zfsmgr::config`, and `/etc/zfsmgr/99-local.toml` created with `replace => false` so local edits are preserved.
* **`zfsmgr::config`**: Defined type for adding `*.toml` configuration snippets under `/etc/zfsmgr` from roles/profiles.
* **`zfsmgr::service`**: Manages cron jobs for `zfsmgr snapshot destroy`, `zfsmgr snapshot create`, and `zfsmgr send all`.

## Setup

### Requirements

* `puppetlabs/stdlib` (`>= 8.1.0 < 10.0.0`, provides `stdlib::to_toml`)
* `puppetlabs/cron_core` (`>= 1.0.0 < 3.0.0`)
* Ruby / RubyGems environment capable of installing `zfs_mgmt`

### Beginning with zfsmgr

```puppet
include zfsmgr
```

## Usage

### Basic usage

```puppet
include zfsmgr
```

This installs `zfs_mgmt` via the `gem` provider, creates `/etc/zfsmgr/50-puppet.toml` and `/etc/zfsmgr/99-local.toml`, creates `/var/lib/zfs_mgmt`, and configures the three default cron jobs:

* `zfsmgr-snapshot-destroy` (`45 */12 * * *`)
* `zfsmgr-snapshot-create` (`1 */4 * * *`)
* `zfsmgr-send-all` (`57 */4 * * *`)

### Configuring datasets via `$config`

```puppet
class { 'zfsmgr':
  config => {
    'mbuffer'      => true,
    'mbuffer_size' => '512M',
    'excludes'     => ['mountpoint', 'sharenfs'],
    'overrides'    => {
      'canmount' => 'noauto',
    },
    'zfs'          => {
      'tank'      => {
        'manage'   => true,
        'policy'   => '10y6m4w30d24h',
        'snapshot' => true,
      },
      'tank/data' => {
        'send'        => true,
        'destination' => 'zfs_recv@backup.example.com:backup/tank',
      },
    },
  },
}
```

### Purging `/etc/zfsmgr` while keeping `99-local.toml`

```puppet
class { 'zfsmgr':
  purge_config_dir => true,
}
```

Because `99-local.toml` is declared as a Puppet `file` resource with `replace => false`, Puppet preserves local edits to `99-local.toml` even when `purge_config_dir => true` removes unmanaged files from `/etc/zfsmgr`.

### Adding role/profile config snippets with `zfsmgr::config`

Other roles and profiles can add independent TOML drop-in files under `/etc/zfsmgr`:

```puppet
zfsmgr::config { '60-backups':
  config => {
    'zfs' => {
      'tank/backups' => {
        'send'        => true,
        'destination' => 'zfs_recv@offsite.example.com:offsite/backups',
      },
    },
  },
}
```

### Customizing cron schedules

```puppet
class { 'zfsmgr':
  snapshot_create_cron => {
    'minute' => 5,
    'hour'   => '*',
  },
  send_all_cron        => {
    'hour'       => '*/6',
    'extra_args' => '--filter ^tank/',
  },
}
```

## Reference

### Classes

* `zfsmgr`: Main entry point. Parameters:
  * `manage_package` (`Boolean`, default: `true`)
  * `package_name` (`String[1]`, default: `'zfs_mgmt'`)
  * `package_ensure` (`String[1]`, default: `'installed'`)
  * `package_provider` (`String[1]`, default: `'gem'`)
  * `config_dir` (`Stdlib::Absolutepath`, default: `'/etc/zfsmgr'`)
  * `purge_config_dir` (`Boolean`, default: `false`)
  * `state_dir` (`Stdlib::Absolutepath`, default: `'/var/lib/zfs_mgmt'`)
  * `owner` (`String[1]`, default: `'root'`)
  * `group` (`String[1]`, default: `'root'`)
  * `config_dir_mode` (`Stdlib::Filemode`, default: `'0755'`)
  * `config_file_mode` (`Stdlib::Filemode`, default: `'0644'`)
  * `state_dir_mode` (`Stdlib::Filemode`, default: `'0755'`)
  * `config` (`Hash`, default: `{}`)
  * `manage_local_config` (`Boolean`, default: `true`)
  * `include_schema_comment` (`Boolean`, default: `true`)
  * `schema_url` (`String[1]`, default: `'https://raw.githubusercontent.com/aranc23/zfs_mgmt/master/schema/config.schema.json'`)
  * `configs` (`Hash[String[1], Hash]`, default: `{}`)
  * `manage_cron` (`Boolean`, default: `true`)
  * `binary_path` (`Stdlib::Absolutepath`, default: `'/usr/local/bin/zfsmgr'`)
  * `cron_path` (`Variant[Undef, String]`, default: `'/sbin:$PATH'`)
  * `snapshot_destroy_cron` (`Zfsmgr::CronJob`, default: `{}`)
  * `snapshot_create_cron` (`Zfsmgr::CronJob`, default: `{}`)
  * `send_all_cron` (`Zfsmgr::CronJob`, default: `{}`)

### Defined Types

* `zfsmgr::config`: Creates a `<title>.toml` file under `$config_dir`. Parameters:
  * `ensure` (`Enum['present', 'absent', 'file']`, default: `'file'`)
  * `config` (`Optional[Hash]`, default: `undef`)
  * `content` (`Optional[String]`, default: `undef`)
  * `replace` (`Boolean`, default: `true`)
  * `config_dir` (`Optional[Stdlib::Absolutepath]`, default: `undef`)
  * `owner` (`Optional[String[1]]`, default: `undef`)
  * `group` (`Optional[String[1]]`, default: `undef`)
  * `mode` (`Optional[Stdlib::Filemode]`, default: `undef`)
  * `include_schema_comment` (`Optional[Boolean]`, default: `undef`)
