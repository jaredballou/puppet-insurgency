define insurgency::instance(
  $config    = {},
  $autostart = true,
  $monitor   = true,
  $servercfg = {},
) {
  if ($title != 'default') {
    file { "${insurgency::homedir}/${title}": ensure => symlink, target => "${insurgency::homedir}/insserver", }
    $cmd = $title
  } else {
    $cmd = 'insserver'
  }
  file { "${insurgency::homedir}/cfg.insserver/${title}.cfg": content => template('insurgency/instance.cfg.erb'), }
  if ($autostart) {
  }
  if ($monitor) {
    cron { "monitor-insserver-${title}": user => $insurgency::user, command => "cd ${insurgency::homedir} && ./${cmd} monitor", }
  }
}
