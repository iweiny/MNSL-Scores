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

sub write_latex_header
{
   my ($file) = @_;
   print $file "hello\n";
}

sub write_html_header
{
   my ($file, $season) = @_;
   print $file "<html>\n";
   print $file "<title>MNSL Scores $season</title>\n";
   print $file "<body>\n";
}

sub write_html_footer
{
   my ($file) = @_;
   print $file "</body>\n";
   print $file "</html>\n";
}

#
# HTML($season)
# season == directory to generate file for.
sub HTML
{
   my ($season) = @_;
   my $filename;
   my $html = "$tmp/$season.html";

   open HTML_FILE, ">$html" or die "could not open $html";
   write_html_header(<HTML_FILE>, $season);

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

   write_html_footer(<HTML_FILE>);
   close(HTML_FILE);
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
