define insurgency::instance(
  $config    = {},
  $servercfg = {},
  $autostart = true,
  $monitor   = true,
  $servercfg = {},
  $overwrite = false,
) {
  if ($osfamily == 'Windows') {
  } else {
    #Firewall defaults
    Firewall { proto => udp, action => accept, }

    if ($title != 'default') {
      file { "${insurgency::homedir}/${title}": ensure => symlink, target => "${insurgency::homedir}/insserver", }
      $cmd = $title
    } else {
      $cmd = 'insserver'
    }

    $rule_clientport = "${config['clientport']} UDP Insurgency"
    if (!defined(Firewall[$rule_clientport])) {
      firewall { $rule_clientport: port => $config['clientport'], }
    }

    $rule_port = "${config['port']} UDP Insurgency"
    if (!defined(Firewall[$rule_port])) {
      firewall { $rule_port: port => $config['port'], }
    }

    $rule_sourcetvport = "${config['sourcetvport']} UDP Insurgency"
    if (!defined(Firewall[$rule_sourcetvport])) {
      firewall { $rule_sourcetvport: port => $config['sourcetvport'], }
    }

    #Create server config
    file { "${serverfiles}/insurgency/cfg/${cmd}.cfg": content => template('insurgency/servercfg.erb'), } ->

    #Create config for script
    file { "${insurgency::homedir}/cfg.insserver/${cmd}.cfg": content => template('insurgency/instance.cfg.erb'), replace => $overwrite, }

    #
    if ($autostart) {
      cron { "update-restart-insserver-${title}": user => $insurgency::user, command => "cd ${insurgency::homedir} && ./${cmd} update-restart", } ->
    }

    if ($monitor) {
      cron { "monitor-insserver-${title}": user => $insurgency::user, command => "cd ${insurgency::homedir} && ./${cmd} monitor", }
    }
  }
}
