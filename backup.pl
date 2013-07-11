#!/usr/bin/perl

my $STORAGE_DEVICE_ID = 111;

use DBI;
use DBI::DBD;
#use Data::Dumper;


  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
      localtime(time);
  while ($hour < 7) {
    $sql = &get_next_device();

# /colobk2/rootbackup.sh colo1.mia.colo-cation.com /colobk2
    my $shortdevice = $sql->{devicename};
    $shortdevice =~ s/\.colo-cation\.com$//;
    my $lan_device = "";
    if ($sql->{lan_backup} eq "Y") {
      ($lan_device,$junk) = split /\./, $shortdevice, 2;
      $lan_device .= '.local';
    }
    my $starttime = time();
print "Backing up $sql->{devicename} to $sql->{volume}\n";
    `/home/daviesinc/backups/rootbackup.sh $sql->{devicename} $sql->{volume} $sql->{generations} $lan_device`;
    #my $diskused = `du -sl --block-size=1M $sql->{volume}/$shortdevice|cut -f 1` * 1;
    my $diskused = 0;
    my $endtime = time();
    my $elapsedtime = $endtime - $starttime;

    &record_backup_result($sql->{device_id},$diskused,$elapsedtime);

    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime(time);
  }

sub get_next_device {
  my $dbh = DBI->connect("DBI:mysql:ccm:66.244.144.224", "colobk", "cbk1cbk2");
  my $stl = $dbh->prepare("lock tables cp_backups write,ccm_device read");
  $stl->execute();
  $stl = $dbh->prepare("select cp_backups.device_id,ccm_device.devicename,cp_backups.volume,cp_backups.storage_device,cp_backups.generations,cp_backups.lan_backup from cp_backups,ccm_device where cp_backups.storage_device_id=? and ((backup_days & b'10000000') or (backup_days & pow(2,dayofweek(curdate())-1))) and ((datediff(curdate(),cp_backups.last_backup) is null) or (datediff(curdate(),cp_backups.last_backup) > 6)) and cp_backups.device_id=ccm_device.device_id order by (backup_days & pow(2,dayofweek(curdate())-1) > 1) desc,last_backup limit 1");
  $stl->execute($STORAGE_DEVICE_ID);
  my $sql =$stl->fetchrow_hashref;
  $stl = $dbh->prepare("update cp_backups set last_backup=now() where device_id in (?)");
  $stl->execute($sql->{device_id});
  my $stl = $dbh->prepare("unlock tables");
  $stl->execute();
  return $sql;
}

sub record_backup_result {
  my $device_id = shift;
  my $diskused = shift;
  my $elapsedtime = shift;

  my $dbh = DBI->connect("DBI:mysql:ccm:66.244.144.224", 
                      "colobk", "cbk1cbk2");
  my $stk=$dbh->prepare("insert into cp_backup_history (device_id,mb_stored,elapsed_time) values (?,?,?)");
  $stk->execute($device_id,$diskused,$elapsedtime);
  $stk=$dbh->prepare("update cp_backups set last_backup=now(),mb_stored=? where device_id=?");
  $stk->execute($diskused,$device_id);
}
