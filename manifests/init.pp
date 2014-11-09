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
  $user        = 'insserver',
  $group       = 'insserver',
  $uid         = 501,
  $gid         = 501,
  $homedir     = '/home/insserver',
  $serverfiles = '/home/insserver/serverfiles',
  $emailnotification = "on",
  $email             = "insserver@jballou.com",
  $steamuser         = "jballou_ins",
  $steampass         = "Vhsl8LO4ekG48nf",
  $defaultmap="ministry_coop",
  $defaultmode="checkpoint",
  $mapcyclefile="mapcycle.txt",
  $maxplayers=64,
  $port=27015,
  $sourcetvport=27020,
  $clientport=27005,
  $ip=$::ipaddress,
  $logdays=7,
  $appid="237410",
  $gamename="Insurgency",
  $engine="source",
  $instances   = {},
#'default' => { defaultmap => "ministry_coop", defaultmode => "checkpoint", mapcyclefile => "mapcycle.txt", maxplayers => "64", port => "27015", sourcetvport => "27020", clientport => "27005", ip => $::ipaddress, logdays => "7"}},
) {
  Vcsrepo { owner => $user, group => $group, }
  File { owner => $user, group => $group, }
  group { $group: gid => $gid, } ->
  user { $user: uid => $uid, home => $homedir, gid => $group, } ->
  package { ['git','gdb','mailx','wget','nano','tmux','glibc.i686','libstdc++.i686']: ensure => present, } ->
  exec { 'create-homedir': command => "mkdir -p \"${homedir}\"", creates => $homedir, } ->
  file { $homedir: ensure => directory, } ->
  file { "${homedir}/insserver": mode => '0755', content => template('insurgency/insserver.erb'), } ->
  file { "${homedir}/cfg.insserver": ensure => directory, } ->
  file { "${homedir}/cfg.insserver/default.cfg": content => template('insurgency/instance.cfg.erb'), } ->
  exec { "insserver install": cwd => $homedir, path => $homedir, creates => $serverfiles, } ->
  file { $serverfiles: ensure => directory, source => 'puppet:///modules/insurgency/serverfiles', recurse => remote, } ->
  vcsrepo { "${serverfiles}/insurgency/addons/sourcemod":
    ensure   => latest,
    provider => git,
    source   => 'https://bitbucket.org/jballou/insurgency-sourcemod',
    revision => 'master',
  } ->
  vcsrepo { "${serverfiles}/insurgency/maps":
    ensure   => latest,
    provider => git,
    source   => 'https://bitbucket.org/jballou/insurgency-maps',
    revision => 'master',
  } ->
  vcsrepo { "${serverfiles}/insurgency/materials":
    ensure   => latest,
    provider => git,
    source   => 'https://bitbucket.org/jballou/insurgency-materials',
    revision => 'master',
  } ->
  vcsrepo { "${serverfiles}/insurgency/scripts/theaters":
    ensure   => latest,
    provider => git,
    source   => 'https://bitbucket.org/jballou/insurgency-theaters',
    revision => 'master',
  } ->
  vcsrepo { "${serverfiles}/insurgency/resource":
    ensure   => latest,
    provider => git,
    source   => 'https://bitbucket.org/jballou/insurgency-resource',
    revision => 'master',
  }
}
/*
 ->
  exec { 'create-serverfiles': command => "mkdir -p \"${serverfiles}\"", creates => $serverfiles, } ->
}
*/
