#!/usr/bin/perl

my $STORAGE_DEVICE_ID = 111;

use DBI;
use DBI::DBD;
use Data::Dumper;

$dbh = DBI->connect("DBI:mysql:ccm:di1.mia.colo-cation.com", "colobk", "cbk1cbk2");

if ($#ARGV != 0) {
  exit;
}
  $stl = $dbh->prepare("select count(*) as count from cp_backups");
  $stl->execute();
  $sql = $stl->fetchrow_hashref;
  $startpos = int((int($sql->{count} / 6)+1) / 3 * $ARGV[0]);

  $stl = $dbh->prepare("select cp_backups.device_id,ccm_device.devicename,cp_backups.volume,cp_backups.storage_device,cp_backups.generations from cp_backups,ccm_device where cp_backups.storage_device_id=? and ((backup_days & b'10000000') or (backup_days & pow(2,dayofweek(curdate())-1))) and ((datediff(curdate(),cp_backups.last_backup) is null) or (datediff(curdate(),cp_backups.last_backup) > 6)) and cp_backups.device_id=ccm_device.device_id order by (backup_days & pow(2,dayofweek(curdate())-1) > 1) desc,last_backup limit ?,?");
  $stl->execute($STORAGE_DEVICE_ID, $startpos, int((int($sql->{count} / 6)+1)/3));
#} else {
#  $stl = $dbh->prepare("select cp_backups.device_id,ccm_device.devicename,cp_backups.volume,cp_backups.storage_device from cp_backups,ccm_device where ccm_device.devicename=? and cp_backups.device_id=ccm_device.device_id and cp_backups.storage_device_id=?");
#  $stl->execute($ARGV[0],$STORAGE_DEVICE_ID);
#}

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
  while ( ($sql = $stl->fetchrow_hashref) && ($hour < 7) ) {
# /colobk2/rootbackup.sh colo1.mia.colo-cation.com /colobk2
    my $shortdevice = $sql->{devicename};
    $shortdevice =~ s/\.colo-cation\.com$//;
    my $starttime = time();
print "Backing up $sql->{devicename} to $sql->{volume}\n";
    `/root/rootbackup.sh $sql->{devicename} $sql->{volume} $sql->{generations}`;
    my $diskused = `du -sl --block-size=1M $sql->{volume}/$shortdevice|cut -f 1` * 1;
    my $endtime = time();
    my $elapsedtime = $endtime - $starttime;
    $dbh = DBI->connect("DBI:mysql:ccm:di1.mia.colo-cation.com", 
                        "colobk", "cbk1cbk2");
    $stk=$dbh->prepare("insert into cp_backup_history (device_id,mb_stored,elapsed_time) values (?,?,?)");
    $stk->execute($sql->{device_id},$diskused,$elapsedtime);
    $stk=$dbh->prepare("update cp_backups set last_backup=now(),mb_stored=? where device_id=?");
    $stk->execute($diskused,$sql->{device_id});
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
  }
