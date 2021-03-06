# == Define: compellent::volume
#
# Utility class for creation of a Compellent Volume#
#
define compellent::volume (
  $size           = '10g',
  $purge          = 'yes',
  $ensure         = 'present',
  $boot           = false,
  $volumefolder   = '',
  $notes          = 'Test Volume',
  $replayprofile  = 'Sample',
  $storageprofile = 'Low Priority',) {
  compellent_volume { "$name":
    ensure         => $ensure,
    size           => $size,
    boot           => $boot,
    volumefolder   => $volumefolder,
    notes          => $notes,
    replayprofile  => $replayprofile,
    storageprofile => $storageprofile,
    purge          => $purge,
  }
}
