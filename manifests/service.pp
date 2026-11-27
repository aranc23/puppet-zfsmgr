# @summary Manages cron jobs for zfsmgr scheduled tasks.
#
# @api private
class zfsmgr::service {
  assert_private()

  if $zfsmgr::manage_cron {
    $cron_jobs = {
      'zfsmgr-snapshot-destroy' => {
        'subcommand' => 'snapshot destroy',
        'defaults'   => {
          'ensure'     => 'present',
          'user'       => 'root',
          'minute'     => 45,
          'hour'       => '*/12',
          'monthday'   => '*',
          'month'      => '*',
          'weekday'    => '*',
          'loglevel'   => 'warn',
          'lock'       => true,
          'lock_file'  => undef,
          'lock_wait'  => 43200,
          'extra_args' => undef,
          'command'    => undef,
        },
        'overrides'  => $zfsmgr::snapshot_destroy_cron,
      },
      'zfsmgr-snapshot-create' => {
        'subcommand' => 'snapshot create',
        'defaults'   => {
          'ensure'     => 'present',
          'user'       => 'root',
          'minute'     => 1,
          'hour'       => '*/4',
          'monthday'   => '*',
          'month'      => '*',
          'weekday'    => '*',
          'loglevel'   => 'warn',
          'lock'       => true,
          'lock_file'  => undef,
          'lock_wait'  => 14400,
          'extra_args' => undef,
          'command'    => undef,
        },
        'overrides'  => $zfsmgr::snapshot_create_cron,
      },
      'zfsmgr-send-all' => {
        'subcommand' => 'send all',
        'defaults'   => {
          'ensure'     => 'present',
          'user'       => 'root',
          'minute'     => 57,
          'hour'       => '*/4',
          'monthday'   => '*',
          'month'      => '*',
          'weekday'    => '*',
          'loglevel'   => 'info',
          'lock'       => true,
          'lock_file'  => undef,
          'lock_wait'  => 14400,
          'extra_args' => undef,
          'command'    => undef,
        },
        'overrides'  => $zfsmgr::send_all_cron,
      },
    }

    $cron_jobs.each |$job_name, $spec| {
      $cfg = $spec['defaults'] + $spec['overrides']

      $path_prefix = $zfsmgr::cron_path ? {
        undef   => '',
        ''      => '',
        default => "PATH=${zfsmgr::cron_path} ",
      }
      $lock_file_arg = $cfg['lock_file'] ? {
        undef   => '',
        default => " --lock-file ${cfg['lock_file']}",
      }
      $lock_args = $cfg['lock'] ? {
        true    => " --lock${lock_file_arg} --lock-wait ${cfg['lock_wait']}",
        default => '',
      }
      $extra_args = $cfg['extra_args'] ? {
        undef   => '',
        default => " ${cfg['extra_args']}",
      }
      $command = $cfg['command'] ? {
        undef   => "${path_prefix}${zfsmgr::binary_path} ${spec['subcommand']} --loglevel ${cfg['loglevel']}${lock_args}${extra_args}",
        default => $cfg['command'],
      }

      cron { $job_name:
        ensure   => $cfg['ensure'],
        command  => $command,
        user     => $cfg['user'],
        minute   => $cfg['minute'],
        hour     => $cfg['hour'],
        monthday => $cfg['monthday'],
        month    => $cfg['month'],
        weekday  => $cfg['weekday'],
      }
    }
  }
}
