class insurgency::linux(
) {
  include wget

  #Create hash of options
  $options = merge({'ip' => $::ipaddress},$::insurgency::defaults)

  #Set defaults for resources
  Vcsrepo { owner => $::insurgency::user, group => $::insurgency::group, ensure => present, provider => git, revision => 'master', }
  File { owner => $::insurgency::user, group => $::insurgency::group, }
  Exec { user => $::insurgency::user, }

  #Install packages
  $packages = $::osfamily ? {
    'debian' => ['gdb','mailutils','postfix','lib32gcc1'],
    default => ['git','gdb','mailx','wget','nano','tmux','glibc.i686','libstdc++.i686'],
  }
  package { $packages: ensure => present, } ->

  #Set up group and user with homedir
  group { $::insurgency::group: gid => $::insurgency::gid, } ->
  user { $::insurgency::user: uid => $::insurgency::uid, home => $::insurgency::homedir, gid => $::insurgency::group, } ->
  exec { 'create-homedir': command => "/bin/mkdir -p \"${::insurgency::homedir}\"", creates => $::insurgency::homedir, } ->
  file { $::insurgency::homedir: ensure => directory, } ->

  #Install scripts
  file { "${::insurgency::homedir}/insserver": mode => '0755', content => template('insurgency/insserver.erb'), } ->
  file { "${::insurgency::homedir}/sync-all-files.sh": mode => '0755', content => template('insurgency/sync-all-files.sh.erb'), } ->
  file { "${::insurgency::homedir}/cfg.insserver": ensure => directory, } ->

  #Install SteamCMD
  file { "${::insurgency::rootdir}/steamcmd": ensure => directory, } ->
  download_uncompress { 'install_steamcmd':
    download_base_url => 'http://media.steampowered.com/client/',
    distribution_name => 'steamcmd_linux.tar.gz',
    dest_folder       => "${::insurgency::rootdir}/steamcmd",
    creates           => "${::insurgency::rootdir}/steamcmd/steamcmd.sh",
    uncompress        => 'tar.gz',
    user              => $::insurgency::user,
    group             => $::insurgency::group,
  } ->
  file { "${::insurgency::rootdir}/steamcmd/steamcmd.sh": mode => '0755', } ->

  #Apply Steam client fix
  file { "${::insurgency::homedir}/.steam": ensure => directory, } ->
  file { "${::insurgency::homedir}/.steam/sdk32": ensure => directory, } ->
  file { "${::insurgency::homedir}/.steam/sdk32/steamclient.so": ensure => symlink, target => "${::insurgency::rootdir}/steamcmd/linux32/steamclient.so", } ->

  #Create filesdir
  exec { 'create-filesdir': command => "mkdir -p ${::insurgency::filesdir}", creates => $::insurgency::filesdir, } ->
  file { $::insurgency::filesdir: ensure => directory, source => 'puppet:///modules/insurgency/serverfiles', recurse => remote, } ->

  #Install Insurgency
  exec { 'install_insurgency': cmd => "./steamcmd.sh +login ${::insurgency::steamuser} \"${::insurgency::steampass}\" +force_install_dir \"${::insurgency::filesdir}\" +app_update \"${::insurgency::appid}\" ${::insurgency::beta} +quit|tee -a \"${::insurgency::scriptlog}\"", cwd => "${::insurgency::rootdir}/steamcmd", creates => "${::insurgency::filesdir}/${::insurgency::executable}", } ->

  #Glibc fix
  wget::fetch { 'libc.so.6':
    source      => 'https://github.com/dgibbs64/linuxgameservers/raw/master/Insurgency/dependencies/libc.so.6',
    destination => "${::insurgency::filesdir}/bin/libc.so.6",
    timeout     => 0,
    verbose     => false,
  } ->
  wget::fetch { 'librt.so.1':
    source      => 'https://github.com/dgibbs64/linuxgameservers/raw/master/Insurgency/dependencies/librt.so.1',
    destination => "${::insurgency::filesdir}/bin/librt.so.1",
    timeout     => 0,
    verbose     => false,
  } ->
  wget::fetch { 'libpthread.so.0':
    source      => 'https://github.com/dgibbs64/linuxgameservers/raw/master/Insurgency/dependencies/libpthread.so.0',
    destination => "${::insurgency::filesdir}/bin/libpthread.so.0",
    timeout     => 0,
    verbose     => false,
  } ->
  wget::fetch { 'libm.so.6':
    source      => 'https://github.com/dgibbs64/linuxgameservers/raw/master/Insurgency/dependencies/libm.so.6',
    destination => "${::insurgency::filesdir}/bin/libm.so.6",
    timeout     => 0,
    verbose     => false,
  } ->

  #Install SourceMod
  exec { 'mkdir-addons': command => "/bin/mkdir -p ${::insurgency::filesdir}/insurgency/addons", creates => "${::insurgency::filesdir}/insurgency/addons", } ->
  vcsrepo { "${::insurgency::filesdir}/insurgency/addons/sourcemod":
    source   => "${::insurgency::gitserver}/insurgency-sourcemod.git",
  } ->

  #Install theaters
  exec { 'mkdir-scripts': command => "/bin/mkdir -p ${::insurgency::filesdir}/insurgency/scripts", creates => "${::insurgency::filesdir}/insurgency/scripts", } ->
  vcsrepo { "${::insurgency::filesdir}/insurgency/scripts/theaters":
    source   => "${::insurgency::gitserver}/insurgency-theaters.git",
  } ->

  #Install Insurgency data
  vcsrepo { "${::insurgency::filesdir}/insurgency/insurgency-data":
    source   => "${::insurgency::gitserver}/insurgency-data.git",
  } ->

  #Set up SourceMod admins
  file { "${::insurgency::filesdir}/insurgency/addons/sourcemod/configs/admins_simple.ini": content => template('insurgency/admins.erb'), } ->

  #Set up file sync (update all git repos and download maps)
  cron { 'insserver-sync': user => $::insurgency::user, command => "cd ${::insurgency::homedir} && ./sync-all-files.sh", } ->
  exec { 'insserver-sync': user => $::insurgency::user, command => "./sync-all-files.sh", cwd => $::insurgency::homedir, } ->

  #Create default instance (sets up scripts and startup configs)
  insurgency::instance { 'default': config => $options, }
}
