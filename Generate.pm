package Generate;

use strict;
use vars qw($VERSION);

$VERSION     = 1.00;

my $tmp = "tmp";
my @month_names = ("", "January", "Febuary", "March", "April", "May", "June",
                  "July", "August", "September", "October", "November", "December");

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
                  = "$scores_date{$filename}{$ev}{$div}{$name}:$cal/$score";
            }
         }
         close(DAY);
      }
   }
   closedir(DIR);
   return (%scores_date);
}

# return %scores
sub process_data
{
   my (%scores_date) = @_;
   my %scores = ();

   my @sorted_dates = sort keys(%scores_date);
   
   foreach my $date (@sorted_dates) {
      foreach my $ev (keys (%{$scores_date{$date}})) {
         foreach my $div (keys (%{$scores_date{$date}{$ev}})) {
            foreach my $name (keys (%{$scores_date{$date}{$ev}{$div}})) {
               my @tmp = split /:/, $scores_date{$date}{$ev}{$div}{$name};
               foreach my $calscore (@tmp) {
                  my ($cal, $score) = split /\//, $calscore;
                  if ($scores{$ev}{$div}{$name} eq "") {
                     $scores{$ev}{$div}{$name} = "$score";
                  } else {
                     $scores{$ev}{$div}{$name} = "$scores{$ev}{$div}{$name}:$score";
                  }
               }
            }
         }
      }
   }

   return (%scores);
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

   # add these scores to the totals for the season
   # print combined scores
   my %scores = process_data(%scores_date);

   foreach my $ev (keys (%scores)) {
      foreach my $div (keys (%{$scores{$ev}})) {
         print HTML_FILE "<h3>$ev -- $div</h3>\n";
         print HTML_FILE "<table cellpadding='5' border='1'>\n";
         print HTML_FILE "<tr>\n";
         print HTML_FILE "<th>Name</th>\n";
         print HTML_FILE "<th>1</th>\n";
         print HTML_FILE "<th>2</th>\n";
         print HTML_FILE "<th>3</th>\n";
         print HTML_FILE "<th>4</th>\n";
         print HTML_FILE "<th>5</th>\n";
         print HTML_FILE "<th>6</th>\n";
         print HTML_FILE "<th>7</th>\n";
         print HTML_FILE "<th>8</th>\n";
         print HTML_FILE "<th>9</th>\n";
         print HTML_FILE "<th>10</th>\n";
         print HTML_FILE "<th>Avg</th>\n";
         print HTML_FILE "<th>Min 1</th>\n";
         print HTML_FILE "<th>Min 2</th>\n";
         print HTML_FILE "</tr>\n";

         my @names = sort (keys (%{$scores{$ev}{$div}}));
         foreach my $name (@names) {

            my @tmp = split /:/, $scores{$ev}{$div}{$name};

            my $min1 = "500";
            my $min2 = "500";
            my $avg = 0;
            my $num = 0;

            foreach my $score (@tmp) {

               # this takes care of printing an empty row when there are exactly 10 scores
               if (int($num) == 0) {
                  print HTML_FILE "<tr><td>$name</td>";
               }

               print HTML_FILE "<td>$score</td>";

               if ($score < $min2) {
                  if ($score < $min1) {
                     $min2 = $min1;
                     $min1 = $score;
                  } else {
                     $min2 = $score;
                  }
               }
               $avg += $score;
               $num++;

               if ($num == 10) {
                  $avg -= $min1;
                  $avg -= $min2;
                  $avg /= 8;
                  # end this row with an avg
                  printf HTML_FILE "<td>%03.02f</td><td>%d</td><td>%d</td></tr>\n",
                                    $avg,$min1,$min2;
                  $min1 = 500;
                  $min2 = 500;
                  $avg = 0;
                  $num = 0;
               }
            }
            # end this row with an avg no matter what
            if ($num != 0) {
               if ($num == 9) {
                  if ($min2 < $min1) {
                     $min1 = $min2;
                  }
                  $avg -= $min1;
                  $avg /= 8;
               } else {
                  $avg /= $num;
               }
               while ($num < 10) {
                  print HTML_FILE "<td></td>";
                  $num++;
               }
               printf HTML_FILE "<td>%03.02f</td>", $avg;
               print HTML_FILE "<td>$min1</td>";
               if ($min2 != 500) {
                  print HTML_FILE "<td>$min2</td></tr>\n";
               } else {
                  print HTML_FILE "<td></td></tr>\n";
               }
            }
            print HTML_FILE "</tr>\n";
         }
         print HTML_FILE "</table>\n";
      }
   }

   # for each date write header with quick links
   print HTML_FILE "<hr><br>";
   print HTML_FILE "Click below (or scroll down) for scores on individual days<p>\n";
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
         $mon = $month_names[$mon];
         # print the header for this
         print HTML_FILE "<td><a href=\"#$date\">$mon $day, $year</a></td>\n";
   }
   print HTML_FILE "</tr>\n";
   print HTML_FILE "</table>\n";


   # print scores by Days
   foreach my $date (@sorted_dates) {
      my $year='';
      my $mon='';
      my $day='';
      if ($date =~ /(.*)-(.*)-(.*)/) {
         $year = $1;
         $mon = $2;
         $day = $3;
      }
      $mon = $month_names[$mon];

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
               my @tmp = split /:/, $scores_date{$date}{$ev}{$div}{$name};
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

sub DataTar
{
   my ($season, $season_path) = @_;
   system("pushd $season_path; tar czf $season.tgz $season; popd; mv $season_path/$season.tgz $tmp");
}

#
# PDF($season)
# season == directory to generate file for.
# Leave this for another day
#sub PDF
#{
#   my ($season) = @_;
#   my $filename;
#   my $latex = "$tmp/$season.latex";
#
#   open LATEX_FILE, ">$latex" or die "could not open $latex";
#   write_doc_header(<LATEX_FILE>);
#
#   opendir ( DIR, $season ) || die "Error in opening $season\n";
#   while( ($filename = readdir(DIR))) {
#      if (($filename ne ".") and ($filename ne "..")) {
#         my $year='';
#         my $mon='';
#         my $day='';
#         if ($filename =~ /(.*)-(.*)-(.*)/) {
#            $year = $1;
#            $mon = $2;
#            $day = $3;
#         }
#         $mon = $month_names[$mon];
#         print("$filename => $mon $day, $year\n");
#      }
#   }
#   closedir(DIR);
#   close(LATEX_FILE);
#}
