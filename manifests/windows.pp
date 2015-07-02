class insurgency::windows(
  $steamcmd_path = 'c:\steamcmd',
  $steamcmd_url  = 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip',
  $steamuser     = $::insurgency::defaults['steamuser'],
  $steampass     = $::insurgency::defaults['steampass'],
  $appid         = $::insurgency::defaults['appid'],
  $filesdir      = 'c:\steam',
  $beta          = '',
  $exemode       = '0755',
) {
  Exec { path => $::path, }
  File { source_permissions => ignore, }
#  exec { 'create-steamcmd-path': command => "cmd.exe /c \"md ${steamcmd_path}\"", creates => $steamcmd_path, } ->
  file { $steamcmd_path: ensure => directory, } ->
#  exec { 'create-filesdir': command => "cmd.exe /c \"md ${filesdir}\"", creates => $filesdir, } ->
  file { $filesdir: ensure => directory, } ->

  file { "${steamcmd_path}/vcredist_x86.exe": source => "puppet:///modules/insurgency/vcredist_x86.exe", mode => $exemode, } ->
  exec { 'install_vcredist_2010': command => "vcredist_x86.exe /q", cwd => $steamcmd_path, path => $steamcmd_path, creates => 'C:\Windows\System32\msvcr100.dll', timeout => 3600, } ->
  file { "${steamcmd_path}/seDirector_v2.0.exe": source => "puppet:///modules/insurgency/seDirector_v2.0.exe", mode => $exemode, } ->
#  exec { 'install-seDirector': command => "seDirector_v2.0.exe", cwd => $steamcmd_path, path => $steamcmd_path, creates => 'C:\Program Files (x86)\Asher Software\seDirector\seDirector.exe', timeout => 3600, } ->
  file { "${steamcmd_path}/steamcmd.exe": source => "puppet:///modules/insurgency/steamcmd.exe", mode => $exemode, } ->
  file { "${steamcmd_path}/update.txt": content => template('insurgency/steamcmd-script.erb'), } ->

  exec { 'install-insurgency': command => "steamcmd +runscript update.txt", cwd => $steamcmd_path, path => $steamcmd_path, creates => "${filesdir}/insurgency", timeout => 3600, }
}
