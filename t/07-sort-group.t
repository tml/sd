#!/usr/bin/perl -w

use strict;

use Prophet::Test tests => 9;
use App::SD::Test;
use File::Temp qw/tempdir/;
use Path::Class;

no warnings 'once';

BEGIN {
    require File::Temp;
    $ENV{'PROPHET_REPO'} = $ENV{'SD_REPO'} = File::Temp::tempdir( CLEANUP => 0 ) . '/_svb';
    diag "export SD_REPO=".$ENV{'PROPHET_REPO'} ."\n";
}

run_script( 'sd', [ 'init']);

my $replica_uuid = replica_uuid;

# create from sd
my ($ticket_id, $ticket_uuid) = create_ticket_ok( '--summary', 'YATTA',
    '--owner', 'foo@bar.com');
my ($ticket_id_2, $ticket_uuid_2) = create_ticket_ok( '--summary', 'huzzah!',
    '--owner', 'alpha@bravo.org' );

diag('default -- no sorting, no grouping');
run_output_matches( 'sd', [ 'ticket', 'list' ],
    [ qr/(\d+) YATTA new/,
      qr/(\d+) huzzah! new/,
    ]
);

diag('using --sort owner');
run_output_matches( 'sd', [ 'ticket', 'list', '--sort', 'owner' ],
    [ qr/(\d+) huzzah! new/,
      qr/(\d+) YATTA new/,
    ]
);

my $config_filename = $ENV{'SD_REPO'} . '/sdrc';
App::SD::Test->write_to_file($config_filename,
    "default_sort_ticket_list = owner\n");
$ENV{'SD_CONFIG'} = $config_filename;

diag('using default_sort_ticket_list = owner');
run_output_matches( 'sd', [ 'ticket', 'list' ],
    [ qr/(\d+) huzzah! new/,
      qr/(\d+) YATTA new/,
    ]
);

diag('using default_sort_ticket_list = owner and --sort none');
run_output_matches( 'sd', [ 'ticket', 'list', '--sort', 'none' ],
    [ qr/(\d+) YATTA new/,
      qr/(\d+) huzzah! new/,
    ]
);

# grouping does not guarantee ordering as it keeps its result in
# a list. that's ok as we can still check that it's grouped.
diag('using --group owner');
run_output_matches( 'sd', [ 'ticket', 'list', '--group', 'owner' ],
    [ '',
      qr/(alpha\@bravo.org|foo\@bar.com)/,
      qr/(===============|===========)/,
      '',
      qr/((\d+) huzzah! new|(\d+) YATTA new)/,
      '',
      qr/(alpha\@bravo.org|foo\@bar.com)/,
      qr/(===============|===========)/,
      '',
      qr/((\d+) huzzah! new|(\d+) YATTA new)/,
    ]
);

diag('using default_group_ticket_list = owner');
$config_filename = $ENV{'SD_REPO'} . '/sdrc';
App::SD::Test->write_to_file($config_filename,
    "default_group_ticket_list = owner\n");
$ENV{'SD_CONFIG'} = $config_filename;

run_output_matches( 'sd', [ 'ticket', 'list' ],
    [ '',
      qr/(alpha\@bravo.org|foo\@bar.com)/,
      qr/(===============|===========)/,
      '',
      qr/((\d+) huzzah! new|(\d+) YATTA new)/,
      '',
      qr/(alpha\@bravo.org|foo\@bar.com)/,
      qr/(===============|===========)/,
      '',
      qr/((\d+) huzzah! new|(\d+) YATTA new)/,
    ]
);

diag('using default_group_ticket_list = owner and --group none');
run_output_matches( 'sd', [ 'ticket', 'list', '--group', 'none' ],
    [ qr/(\d+) YATTA new/,
      qr/(\d+) huzzah! new/,
    ]
);

# TODO: test both sorting and grouping at the same time?
# sort sorts tickets within a grouping but not the groupings themselves