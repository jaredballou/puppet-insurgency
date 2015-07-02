class insurgency::linux(
  $user              = $::insurgency::user,
  $group             = $::insurgency::group,
  $uid               = $::insurgency::uid,
  $gid               = $::insurgency::gid,
  $homedir           = '/home/insserver',
  $steamuser         = $::insurgency::defaults['steamuser'],
  $steampass         = $::insurgency::defaults['steampass'],
  $appid             = $::insurgency::defaults['appid'],
) {
  $rootdir           = $::insurgency::homedir
  $filesdir          = "${rootdir}/serverfiles"
  $systemdir         = "${filesdir}/insurgency"
  $executabledir     = "${filesdir}"
  $executable        = "./srcds_linux"
  $servercfgdir      = "${systemdir}/cfg"
  $gamelogdir        = "${systemdir}/logs"
  $scriptlogdir      = "${rootdir}/log/script"
  $scriptlog         = "${scriptlogdir}/${servicename}-script.log"
  $consolelogdir     = "${rootdir}/log/console"
  $serverlogdir      = "${rootdir}/log/server"

  include wget

  #Create hash of options
  $options = merge({'ip' => $::ipaddress},$::insurgency::defaults)

  #Set defaults for resources
  Vcsrepo { owner => $user, group => $group, ensure => present, provider => git, revision => 'master', }
  File { owner => $user, group => $group, }
  Exec { user => $user, }

  #Install packages
  $packages = $::osfamily ? {
    'debian' => ['gdb','mailutils','postfix','lib32gcc1'],
    default => ['git','gdb','mailx','nano','tmux','glibc.i686','libstdc++.i686'],
  }
  package { $packages: ensure => present, } ->

  #Set up group and user with homedir
  group { $group: gid => $gid, } ->
  user { $user: uid => $uid, home => $homedir, gid => $group, } ->
  exec { 'create-homedir': command => "/bin/mkdir -p \"${homedir}\"", creates => $homedir, user => 'root', notify => Exec['fix-insserver-permissions'], } ->
  file { $homedir: ensure => directory, } ->

  #Install scripts
  file { "${homedir}/insserver": mode => '0755', content => template('insurgency/insserver.erb'), } ->
  file { "${homedir}/sync-all-files.sh": mode => '0755', content => template('insurgency/sync-all-files.sh.erb'), } ->
  file { "${homedir}/cfg.insserver": ensure => directory, } ->

  #Install SteamCMD
  file { "${rootdir}/steamcmd": ensure => directory, } ->
  download_uncompress { 'install_steamcmd':
    download_base_url => 'http://media.steampowered.com/client/',
    distribution_name => 'steamcmd_linux.tar.gz',
    dest_folder       => "${rootdir}/steamcmd",
    creates           => "${rootdir}/steamcmd/steamcmd.sh",
    uncompress        => 'tar.gz',
    user              => $user,
    group             => $group,
  } ->
  file { "${rootdir}/steamcmd/steamcmd.sh": mode => '0755', } ->

  #Apply Steam client fix
  file { "${homedir}/.steam": ensure => directory, } ->
  file { "${homedir}/.steam/sdk32": ensure => directory, } ->
  file { "${homedir}/.steam/sdk32/steamclient.so": ensure => symlink, target => "${rootdir}/steamcmd/linux32/steamclient.so", } ->

  #Create filesdir
  exec { 'create-filesdir': command => "/bin/mkdir -p ${filesdir}", creates => $filesdir, user => 'root', notify => Exec['fix-insserver-permissions'], } ->
  file { $filesdir: ensure => directory, source => 'puppet:///modules/insurgency/serverfiles', recurse => remote, } ->

  #Create logging directory structure
  exec { 'create-scriptlogdir': command => "/bin/mkdir -p ${scriptlogdir}", creates => $scriptlogdir, user => 'root', notify => Exec['fix-insserver-permissions'], } ->
  exec { 'create-consolelogdir': command => "/bin/mkdir -p ${consolelogdir}", creates => $consolelogdir, user => 'root', notify => Exec['fix-insserver-permissions'], } ->
  exec { 'create-serverlogdir': command => "/bin/mkdir -p ${serverlogdir}", creates => $serverlogdir, user => 'root', notify => Exec['fix-insserver-permissions'], } ->
  file { $scriptlogdir: ensure => directory, } ->
  file { $consolelogdir: ensure => directory, } ->
  file { $serverlogdir: ensure => directory, } ->

  #Install Insurgency
#login ${::insurgency::defaults['steamuser']} ${::insurgency::defaults['steampass']} +force_install_dir \"${filesdir}\" +app_update \"${::insurgency::defaults['appid']}\" ${::insurgency::defaults['beta']} +quit
  file { "${rootdir}/steamcmd/update.txt": content => template('insurgency/steamcmd-script.erb'), } ->

  
  #Glibc fix
  exec { 'create-bindir': command => "/bin/mkdir -p ${filesdir}/bin", creates => "${filesdir}/bin", user => 'root', notify => Exec['fix-insserver-permissions'], } ->
  file { "${filesdir}/bin": ensure => directory, } ->
  exec { 'install-insurgency': path => "${rootdir}/steamcmd", cwd => "${rootdir}/steamcmd", command => "steamcmd.sh +runscript update.txt|/usr/bin/tee -a \"${scriptlog}\"", creates => "${filesdir}/${executable}", timeout => 3600, require => Exec['fix-insserver-permissions'], } ->
  wget::fetch { 'libc.so.6':
    source      => 'https://github.com/dgibbs64/linuxgameservers/raw/master/Insurgency/dependencies/libc.so.6',
    destination => "${filesdir}/bin/libc.so.6",
    timeout     => 0,
    verbose     => false,
  } ->
  wget::fetch { 'librt.so.1':
    source      => 'https://github.com/dgibbs64/linuxgameservers/raw/master/Insurgency/dependencies/librt.so.1',
    destination => "${filesdir}/bin/librt.so.1",
    timeout     => 0,
    verbose     => false,
  } ->
  wget::fetch { 'libpthread.so.0':
    source      => 'https://github.com/dgibbs64/linuxgameservers/raw/master/Insurgency/dependencies/libpthread.so.0',
    destination => "${filesdir}/bin/libpthread.so.0",
    timeout     => 0,
    verbose     => false,
  } ->
  wget::fetch { 'libm.so.6':
    source      => 'https://github.com/dgibbs64/linuxgameservers/raw/master/Insurgency/dependencies/libm.so.6',
    destination => "${filesdir}/bin/libm.so.6",
    timeout     => 0,
    verbose     => false,
  } ->

  #Install SourceMod
  exec { 'mkdir-addons': command => "/bin/mkdir -p ${filesdir}/insurgency/addons", creates => "${filesdir}/insurgency/addons", } ->
  vcsrepo { "${filesdir}/insurgency/addons/sourcemod":
    source   => "${::insurgency::gitserver}/insurgency-sourcemod.git",
  } ->

  #Install theaters
  exec { 'mkdir-scripts': command => "/bin/mkdir -p ${filesdir}/insurgency/scripts", creates => "${filesdir}/insurgency/scripts", } ->
  vcsrepo { "${filesdir}/insurgency/scripts/theaters":
    source   => "${::insurgency::gitserver}/insurgency-theaters.git",
  } ->

  #Install Insurgency data
  vcsrepo { "${filesdir}/insurgency/insurgency-data":
    source   => "${::insurgency::gitserver}/insurgency-data.git",
  } ->

  #Set up SourceMod admins
  file { "${filesdir}/insurgency/addons/sourcemod/configs/admins_simple.ini": content => template('insurgency/admins.erb'), } ->

  #Symlink game log directory to server log dir
  file { $gamelogdir: ensure => symlink, target => $serverlogdir, } ->

  #Set up file sync (update all git repos and download maps)
  cron { 'insserver-sync': user => $user, command => "cd ${homedir} && ./sync-all-files.sh", } ->

  #Create default instance (sets up scripts and startup configs)
  insurgency::instance { 'default': config => $options, }

  #Permissions fixup called as needed
  exec { 'fix-insserver-permissions': command => "/bin/chown ${user}:${group} ${homedir} -R", refreshonly => true, }

}
