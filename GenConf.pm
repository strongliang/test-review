package Amanda::Rest::GenConf;
use warnings;
use strict;
use 5.010;

use Template;

# this template can be broken down into sections for better flexibility
my $amconf_tmpl = qq /
org "[%backupset_name%]"

infofile "[%curinfo_dir%]"
logdir "[%log_dir%]"
indexdir "[%index_dir%]"
dumpuser "amandabackup"

define policy diskflat_policy {
    retention-tapes [%retention%]
}

define changer my_diskflat {
  tpchanger "chg-diskflat:[%diskflat_dir%]"
  property "num_slot" "[%num_slot%]"
  property "auto_create_slot" "yes"
  device-property "LEOM" "TRUE"
}

define storage my_diskflat {
  policy "diskflat_policy"
  tpchanger "my_diskflat"
  autolabel "diskflat-\$3s" empty volume-error
  labelstr MATCH-AUTOLABEL
}

storage "my_diskflat"

tapetype "TEST-TAPE"
define tapetype TEST-TAPE {
  length 100 mbytes
  filemark [%filemark_kb%] kbytes
}
/;

sub gen_amanda_conf {
  my $tt = Template->new() || die "$Template::ERROR\n";

  my $vars = shift;

  my $backupset_name = $vars->{'backupset_name'};

  # redirect STDOUT to amanda.conf
  my $origout;
  open($origout, ">&", "STDOUT") || die "$!\n";

  my $stdout_redirect = "/etc/amanda/$backupset_name/amanda.conf";


  # for now, fail if the backupset already exists
  if (-e $stdout_redirect) {
    # TODO: define error codes here
    print STDERR "file already exists\n";
    return 'file already exists';
  }
  mkdir "/etc/amanda/$backupset_name" || die "$!\n";

  open(STDOUT, ">", $stdout_redirect) || die "$!\n";


  # $tt->process('amanda-conf-temp', $vars) || die $tt->error(), "\n";
  $tt->process(\$amconf_tmpl, $vars) || die $tt->error(), "\n";

  # restore STDOUT
  close STDOUT;
  open(STDOUT, ">&", $origout) || die "$!\n";

  return 'ok';

}

sub test {
  my $vars = {
      backupset_name      => 'tmp',
      curinfo_dir         => '/amanda/state/curinfo',
      log_dir             => '/amanda/state/log',
      index_dir           => '/amanda/state/index',
      retention           => 40,
      diskflat_dir        => '/amanda/h1/diskflat',
      num_slot            => 21,
      filemark_kb         => 4096,
  };

  if (gen_amanda_conf ($vars) ne 'ok') {
    print 'failed to generate config\n';
  }
}

# test;

1;

