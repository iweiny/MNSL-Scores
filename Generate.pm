package Generate;

use lib "DateTime-0.55/lib";
use lib "Params-Validate-0.95/lib";
use lib "DateTime-Locale-0.45/lib";
use lib "DateTime-TimeZone-1.15/lib";
use DateTime;

use strict;
use vars qw($VERSION);

$VERSION     = 1.00;

my $tmp = "tmp";

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
# HTML($season, $season_path)
# season == directory to generate file for.
sub HTML
{
   my ($season, $season_path) = @_;
   my $filename;
   my $html = "$tmp/$season.html";
   my $day_section = "$tmp/tmp.html";

   open HTML_FILE, ">$html" or die "could not open $html";
   write_html_header(\*HTML_FILE, $season);


   print HTML_FILE "<table>\n";
   print HTML_FILE "<tr>\n";

   opendir ( DIR, "$season_path/$season" ) || die "Error in opening $season_path/$season\n";
   open SECTION, ">$day_section" or die "could not open $day_section";
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

         # print the header for this
         print HTML_FILE "<td><a href=\"#$filename\">$mon $day, $year</a></td>\n";

         # print the scores for this day for each person
         print SECTION "\n<a name=\"$filename\"><h2>$mon $day, $year</h2></a>\n";

         print SECTION "<table cellpadding='5'>\n";
         print SECTION "<tr>\n";
         print SECTION "<th>Name</th>\n";
         print SECTION "<th>Scores</th>\n";
         print SECTION "</tr>\n";

         open DAY, "<$season_path/$season/$filename"
                  or die "failed to open scores file $season_path/$season/$filename";
         while (<DAY>) {
            my ($name, $event, $div, $cal, $score) = split(/:/, $_);
            print SECTION "<tr>\n";
            print SECTION "<td>$name</td><td>$event</td><td>$div</td><td>$cal</td><td>$score</td>\n";
            print SECTION "</tr>\n";
         }
         close(DAY);

         print SECTION "</table>\n";

         # add these scores to the totals for the season
      }
   }
   closedir(DIR);

   close(SECTION);
   print HTML_FILE "</tr>\n";
   print HTML_FILE "</table>\n";

   # print combined scores


   # insert the days scores from the "<SECTION>" file
   open SECTION, "<$day_section" or die "could not open $day_section";
   while (<SECTION>) {
      print HTML_FILE $_;
   }
   close(SECTION);

   write_html_footer(\*HTML_FILE);
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
