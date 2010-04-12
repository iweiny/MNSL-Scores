package MNSLQuery;

use DBI;
use strict;
use Exporter;
use vars qw($VERSION);

$MNSLQuery::VERSION = 1.00;

sub connect
{
   my ($user, $password, $db) = @_;
   $MNSLQuery::dbh = DBI->connect("dbi:mysql:$db", $user, $password)
                        or die "DataBase Connection Error: " . DBI->errstr;
}

sub reconnect
{
   my ($user, $password, $db) = @_;
   MNSLQuery::disconnect();
   MNSLQuery::connect($user, $password, $db);
}

sub disconnect
{
   $MNSLQuery::dbh->disconnect();
}

sub query
{
   my ($query) = @_;
   my $sql = $query;
   my $sth = $MNSLQuery::dbh->prepare($sql);
   $sth->execute or die "SQL Error: $DBI::errstr ($query)\n";
   return ($sth);
}

