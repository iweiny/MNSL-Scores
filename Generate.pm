package Generate;

use lib "DateTime-0.55/lib";
use lib "Params-Validate-0.95/lib";
use lib "DateTime-Locale-0.45/lib";
use lib "DateTime-TimeZone-1.15/lib";
use DateTime;

use strict;
use vars qw($VERSION);

$VERSION     = 1.00;

my $tmp = "/tmp";

sub write_doc_header
{
   my ($file) = @_;
   print $file "hello\n";
}

#
# PDF($season)
# season == directory to generate file for.
sub PDF
{
   my ($season) = @_;
   my $filename;
   my $latex = "$tmp/$season.latex";

   open LATEX_FILE, ">$latex" or die "could not open $latex";
   write_doc_header(<LATEX_FILE>);

   opendir ( DIR, $season ) || die "Error in opening $season\n";
   while( ($filename = readdir(DIR))) {
      if (($filename ne ".") and ($filename ne "..")) {
         my $year='';
         my $mon='';
         my $day='';
         if ($filename =~ /(.*)-(.*)-(.*)/) {
            $year = $1;
            $mon = $2;
            $day = $3;
         }
         my $dt = DateTime->new(year=>$year,month=>$mon, day=>$day);
         $mon = $dt->month_name;
         print("$filename => $mon $day, $year\n");
      }
   }
   closedir(DIR);
   close(LATEX_FILE);
}
