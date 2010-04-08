package MNSLQuery;

use DBI;
use strict;
use Exporter;
use vars qw($VERSION);

$MNSLQuery::VERSION = 1.00;

sub connect
{
   my ($user, $password) = @_;
   $MNSLQuery::dbh = DBI->connect('dbi:mysql:mnsl', $user, $password) or die "Connection Error: ";
}

sub query
{
   my ($query) = @_;
   my $sql = $query;
   my $sth = $MNSLQuery::dbh->prepare($sql);
   $sth->execute or die "SQL Error: $DBI::errstr ($query)\n";
   return ($sth);
}

