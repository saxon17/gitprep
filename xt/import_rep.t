use Test::More 'no_plan';
use strict;
use warnings;

use FindBin;
use utf8;
use lib "$FindBin::Bin/../mojo/lib";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../extlib/lib/perl5";
use File::Path 'rmtree';
use Encode qw/encode decode/;

use Test::Mojo;

# Test DB
my $db_file = $ENV{GITPREP_DB_FILE} = "$FindBin::Bin/import_rep.db";

# Test Repository home
my $rep_home = $ENV{GITPREP_REP_HOME} = "$FindBin::Bin/import_rep_user";

$ENV{GITPREP_NO_MYCONFIG} = 1;


use Gitprep;

# For perl 5.8
{
  no warnings 'redefine';
  sub note { print STDERR "# $_[0]\n" unless $ENV{HARNESS_ACTIVE} }
}

note 'import_rep';
{
  unlink $db_file;
  rmtree $rep_home;

  my $app = Gitprep->new;
  my $t = Test::Mojo->new($app);
  $t->ua->max_redirects(3);
  
  # Create admin user
  $t->post_ok('/_start?op=create', form => {password => 'a', password2 => 'a'});
  $t->content_like(qr/Login page/);

  # Login as admin
  $t->post_ok('/_login?op=login', form => {id => 'admin', password => 'a'});
  $t->content_like(qr/Admin/);

  # Create user
  $t->post_ok('/_admin/user/create?op=create', form => {id => 'kimoto', password => 'a', password2 => 'a'});
  $t->content_like(qr/Success.*created/);
  
  # Import repositories
  my $rep_dir = "$FindBin::Bin/../../gitprep_t_rep_home/kimoto";
  chdir "$FindBin::Bin/../script"
    or die "Can't change directory: $!";
  my @cmd = ('./import_rep', '-u', 'kimoto', $rep_dir);
  system(@cmd) == 0
    or die "Command fail: @cmd";
  
  # Branch
  ok(-f "$FindBin::Bin/import_rep_user/kimoto/gitprep_t.git/refs/heads/b1");

  # Tag
  ok(-f "$FindBin::Bin/import_rep_user/kimoto/gitprep_t.git/refs/tags/t1");
  
  # Description
  ok(-f "$FindBin::Bin/import_rep_user/kimoto/gitprep_t.git/description");
}

