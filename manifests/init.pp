# == Class: insurgency
#
# Full description of class insurgency here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { insurgency:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2011 Your name here, unless otherwise noted.
#
class insurgency(
  $user              = 'insserver',
  $group             = 'insserver',
  $uid               = 501,
  $gid               = 501,
  $homedir           = '/home/insserver',
  $instances         = {},
  $admins            = {},
  $gitserver         = 'https://github.com/jaredballou',
  $fastdl            = 'ins.jballou.com/fastdl',
  $server_custom_cfg = {},
  $defaults          = {
    appid             => 237410,
    beta              => '',
    clientport        => 27005,
    defaultmap        => 'ministry_coop',
    defaultmode       => 'checkpoint',
    email             => 'insserver@jballou.com',
    emailnotification => 'on',
    engine            => 'source',
    gamename          => 'Insurgency',
    ip                => $::ipaddress,
    logdays           => 7,
    mapcyclefile      => 'mapcycle_checkpoint.txt',
    maxplayers        => 64,
    port              => 27015,
    sourcetvport      => 27020,
    steamuser         => 'anonymous',
    steampass         => '',
  },
) {
  if ($osfamily == 'Windows') {
    include insurgency::windows
  } else {
    include insurgency::linux
  }
  create_resources('insurgency::instance',$instances)
}
