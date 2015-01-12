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
  $defaults    = {
    emailnotification => "on",
    email             => "insserver@jballou.com",
    steamuser         => "jballou_ins",
    steampass         => "Vhsl8LO4ekG48nf",
    defaultmap        => "ministry_coop",
    defaultmode       => "checkpoint",
    mapcyclefile      => "mapcycle_verynotfun.txt",
    maxplayers        => 64,
    port              => 27015,
    sourcetvport      => 27020,
    clientport        => 27005,
    ip                => $::ipaddress,
    logdays           => 7,
    appid             => "237410",
    gamename          => "Insurgency",
    engine            => "source"
  },
  $instances   = {},
  $admins = {
    'jballou' => {
      'steamid' => 'STEAM_1:1:2938846',
      'level' => '99:z'
    },
    'Geezer' => {
      'steamid' => 'STEAM_1:1:10119430',
      'level' => '90:z'
    },
    'MrClark' => {
      'steamid' => 'STEAM_1:1:15239283',
      'level' => '90:z'
    },
    'StinkPickle' => {
      'steamid' => 'STEAM_1:1:17921013',
      'level' => '90:z'
    },
    'Stryder' => {
      'steamid' => 'STEAM_1:0:66263075',
      'level' => '90:z'
    },
  },
  $gitserver = 'git@github.com:jaredballou',
) {
  Vcsrepo { owner => $user, group => $group, ensure => present, provider => git, revision => 'master', }
  File { owner => $user, group => $group, }
  Exec { user => $user, }
  group { $group: gid => $gid, } ->
  user { $user: uid => $uid, home => $homedir, gid => $group, } ->
  package { ['git','gdb','mailx','wget','nano','tmux','glibc.i686','libstdc++.i686']: ensure => present, } ->
  exec { 'create-homedir': command => "mkdir -p \"${homedir}\"", creates => $homedir, } ->
  file { $homedir: ensure => directory, } ->
  file { "${homedir}/insserver": mode => '0755', content => template('insurgency/insserver.erb'), } ->
  file { "${homedir}/cfg.insserver": ensure => directory, } ->
  insurgency::instance { 'default': config => $defaults, } ->
  exec { "insserver install": cwd => $homedir, path => "${::path}:${homedir}", creates => $serverfiles, } ->
  file { $serverfiles: ensure => directory, source => 'puppet:///modules/insurgency/serverfiles', recurse => remote, } ->
/*
  vcsrepo { "${serverfiles}/insurgency/addons/sourcemod":
    source   => "${gitserver}/insurgency-sourcemod.git",
#    source   => 'https://bitbucket.org/jballou/insurgency-sourcemod',
  } ->
  vcsrepo { "${serverfiles}/insurgency/maps":
    source   => "${gitserver}/insurgency-maps.git",
  } ->
  vcsrepo { "${serverfiles}/insurgency/materials":
    source   => "${gitserver}/insurgency-materials.git",
  } ->
  vcsrepo { "${serverfiles}/insurgency/scripts/theaters":
    source   => "${gitserver}/insurgency-theaters.git",
  } ->
  vcsrepo { "${serverfiles}/insurgency/resource":
    source   => "${gitserver}/insurgency-resource.git",
  } ->
*/
  file { "${serverfiles}/insurgency/maps": ensure => directory, source => 'puppet:///modules/insurgency/maps', recurse => remote, } ->
  file { "${serverfiles}/insurgency/addons/sourcemod/configs/admins_simple.ini": content => template('insurgency/admins.erb'), } ->
  exec { "generate-bzips-and-links.sh": cwd => "${serverfiles}/insurgency/maps", path => "${::path}:${serverfiles}/insurgency/maps", } ->
  cron { 'insserver-update-restart': user => $user, minute => 0, hour => 10, command => "cd ${homedir} && ./insserver update-restart", }
}
/*
 ->
  exec { 'create-serverfiles': command => "mkdir -p \"${serverfiles}\"", creates => $serverfiles, } ->
}
*/
