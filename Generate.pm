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

# return %scores_date
sub read_data_date #(season, season_path)
{
   my ($season, $season_path) = @_;
   my $filename;

   my %scores_date = ();

   opendir ( DIR, "$season_path/$season" ) || die "Error in opening $season_path/$season\n";
   while( ($filename = readdir(DIR))) {
      if (($filename ne ".") and ($filename ne "..")) {
         open DAY, "<$season_path/$season/$filename"
                  or die "failed to open scores file $season_path/$season/$filename";
         while (<DAY>) {
            my ($name, $ev, $div, $cal, $score) = split(/:/, $_);
	    chomp $score;
            if ($scores_date{$filename}{$ev}{$div}{$name} eq "") {
               $scores_date{$filename}{$ev}{$div}{$name} = "$cal/$score";
            } else {
               $scores_date{$filename}{$ev}{$div}{$name}
                  = "$scores_date{$filename}{$ev}{$div}{$name},$cal/$score";
            }
         }
         close(DAY);
      }
   }
   closedir(DIR);
   return (%scores_date);
}

sub write_latex_header
{
   my ($file) = @_;
   print $file "hello\n";
}

sub write_html_header
{
   my ($file, $season) = @_;
   print $file "<html>\n";
   print $file "<title>MNSL Scores -- $season</title>\n";
   print $file "<body>\n";
   print $file "<h1>MNSL Scores -- $season</h1>\n";
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

   my %scores_date = read_data_date ($season, $season_path);

   open HTML_FILE, ">$html" or die "could not open $html";
   write_html_header(\*HTML_FILE, $season);

   # for each date write header with quick links
   print HTML_FILE "<table>\n";
   print HTML_FILE "<tr>\n";

   my @sorted_dates = sort keys(%scores_date);
   foreach my $date (@sorted_dates) {
         my $year='';
         my $mon='';
         my $day='';
         if ($date =~ /(.*)-(.*)-(.*)/) {
            $year = $1;
            $mon = $2;
            $day = $3;
         }
         my $dt = DateTime->new(year=>$year,month=>$mon,day=>$day);
         $mon = $dt->month_name;
         # print the header for this
         print HTML_FILE "<td><a href=\"#$date\">$mon $day, $year</a></td>\n";
   }
   print HTML_FILE "</tr>\n";
   print HTML_FILE "</table>\n";

   # add these scores to the totals for the season
   # print combined scores

   # print individual scores by dates
   foreach my $date (@sorted_dates) {
      my $year='';
      my $mon='';
      my $day='';
      if ($date =~ /(.*)-(.*)-(.*)/) {
         $year = $1;
         $mon = $2;
         $day = $3;
      }
      my $dt = DateTime->new(year=>$year,month=>$mon,day=>$day);
      $mon = $dt->month_name;

      # print the scores for this day for each person
      print HTML_FILE "\n<hr><a name=\"$date\"><h2>$mon $day, $year</h2></a>\n";

      foreach my $ev (keys (%{$scores_date{$date}})) {
	 foreach my $div (keys (%{$scores_date{$date}{$ev}})) {
            print HTML_FILE "<h3>$ev -- $div</h3>\n";
            print HTML_FILE "<table cellpadding='5' border='1'>\n";
            print HTML_FILE "<tr>\n";
            print HTML_FILE "<th>Name</th>\n";
            print HTML_FILE "<th>Scores</th>\n";
            print HTML_FILE "</tr>\n";

            my @names = sort (keys (%{$scores_date{$date}{$ev}{$div}}));
	    foreach my $name (@names) {
               print HTML_FILE "<tr>\n";
               print HTML_FILE "<td>$name</td>";
	       my @tmp = split /,/, $scores_date{$date}{$ev}{$div}{$name};
	       foreach my $score (@tmp) {
                  print HTML_FILE "<td>$score</td>";
	       }
	    }
            print HTML_FILE "\n</tr>\n";
            print HTML_FILE "</table>\n";
	 }
      }
   }

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
