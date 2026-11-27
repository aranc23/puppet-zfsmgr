# @summary Cron job specification for zfsmgr scheduled tasks.
type Zfsmgr::CronJob = Struct[{
  Optional['ensure']     => Enum['present', 'absent'],
  Optional['user']       => String[1],
  Optional['minute']     => Variant[Integer[0, 59], String[1], Array[Variant[Integer[0, 59], String[1]]]],
  Optional['hour']       => Variant[Integer[0, 23], String[1], Array[Variant[Integer[0, 23], String[1]]]],
  Optional['monthday']   => Variant[Integer[1, 31], String[1], Array[Variant[Integer[1, 31], String[1]]]],
  Optional['month']      => Variant[Integer[1, 12], String[1], Array[Variant[Integer[1, 12], String[1]]]],
  Optional['weekday']    => Variant[Integer[0, 7], String[1], Array[Variant[Integer[0, 7], String[1]]]],
  Optional['loglevel']   => Enum['debug', 'info', 'warn', 'error', 'fatal', 'unknown'],
  Optional['lock']       => Boolean,
  Optional['lock_file']  => Stdlib::Absolutepath,
  Optional['lock_wait']  => Integer[0],
  Optional['extra_args'] => String[1],
  Optional['command']    => String[1],
}]
