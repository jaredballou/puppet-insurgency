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
  $gitserver    = 'git@github.com:jaredballou',
  $fastdl_http  = 'http://ins.jballou.com/fastdl',
  $fastdl_rsync = 'rsync://ins.jballou.com/fastdl',
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
  file { "${homedir}/sync-all-files.sh": mode => '0755', content => template('insurgency/sync-all-files.sh.erb'), } ->
  file { "${homedir}/cfg.insserver": ensure => directory, } ->
  insurgency::instance { 'default': config => $defaults, } ->
  exec { "insserver install": cwd => $homedir, path => "${::path}:${homedir}", creates => $serverfiles, } ->
  file { $serverfiles: ensure => directory, source => 'puppet:///modules/insurgency/serverfiles', recurse => remote, } ->
  exec { 'mkdir-sourcemod': command => "mkdir -p ${serverfiles}/insurgency/addons", creates => "${serverfiles}/insurgency/addons", } ->
  vcsrepo { "${serverfiles}/insurgency/addons/sourcemod":
    source   => "${gitserver}/insurgency-sourcemod.git",
  } ->
  exec { 'mkdir-scripts': command => "mkdir -p ${serverfiles}/insurgency/scripts", creates => "${serverfiles}/insurgency/scripts", } ->
  vcsrepo { "${serverfiles}/insurgency/scripts/theaters":
    source   => "${gitserver}/insurgency-theaters.git",
  } ->
  vcsrepo { "${serverfiles}/insurgency/insurgency-data":
    source   => "${gitserver}/insurgency-data.git",
  } ->
  file { "${serverfiles}/insurgency/addons/sourcemod/configs/admins_simple.ini": content => template('insurgency/admins.erb'), } ->
  cron { 'insserver-update-restart': user => $user, minute => 0, hour => 10, command => "cd ${homedir} && ./insserver update-restart", } ->
  cron { 'insserver-monitor': user => $user, command => "cd ${homedir} && ./insserver monitor", } ->
  cron { 'insserver-sync': user => $user, command => "cd ${homedir} && ./sync-all-files.sh", }
}
