package Generate;

use strict;
use vars qw($VERSION);

use MNSLQuery;

$VERSION     = 1.00;

my $bg_grey = "#F0F0F0";

my $tmp = "tmp";
my @month_names = ("", "January", "Febuary", "March", "April", "May", "June",
                  "July", "August", "September", "October", "November", "December");

sub write_html_header
{
   my ($file) = @_;

   print $file "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";   
   print $file "<html>\n";
   print $file "<head>\n";
   #Steggy added - read style file and print in head of HTML
   open(MYDATA ,"css") or die ("Error: cannot open file 'css'\n");
   my @lines = <MYDATA>;
   print $file "@lines";
   close MYDATA;
}

sub write_html_footer
{
   my ($file) = @_;
   print $file "</body>\n";
   print $file "</html>\n";
}

sub ConvertDateHR
{
   my ($date) = @_;
   my $year='';
   my $mon='';
   my $day='';
   if ($date =~ /(.*)-(.*)-(.*)/) {
      $year = $1;
      $mon = $2;
      $day = $3;
   }
   $mon = $month_names[$mon];
   return ("$mon $day, $year");
}

sub GetColAsArray
{
   my ($q) = @_;
   my $sth = MNSLQuery::query($q);
   my @rc;
   while (my @res = $sth->fetchrow_array) {
      push (@rc, @res);
   }
   return (@rc);
}

sub GetDates
{
   my ($s) = @_;
   return (GetColAsArray("select distinct dte from scores where ".
                  "leaguenum='$s' order by dte;"));
}
sub GetDatesRev
{
   my ($s) = @_;
   return (GetColAsArray("select distinct dte from scores where ".
                  "leaguenum='$s' order by dte desc;"));
}

sub GetShooters
{
   my ($s) = @_;
   return (GetColAsArray("select distinct sh.id from shooters as sh, ".
                  "scores as s where s.shooterid=sh.id and leaguenum='$s' ".
                  "order by sh.lname,sh.fname;"));
}

sub GetEids
{
   my ($s) = @_;
   return (GetColAsArray("select id from event;"));
}
sub GetEventFromID
{
   my ($eid) = @_;
   my $sth = MNSLQuery::query("select name from event where id='$eid';");
   my @res = $sth->fetchrow_array;
   return ("$res[0]");
}
sub GetDids
{
   my ($s) = @_;
   return (GetColAsArray("select id from division;"));
}
sub GetDivisionFromID
{
   my ($did) = @_;
   my $sth = MNSLQuery::query("select name from division where id='$did';");
   my @res = $sth->fetchrow_array;
   return ("$res[0]");
}

sub GetNameFromID
{
   my ($shid) = @_;
   my $sth = MNSLQuery::query("select lname,fname from shooters ".
                  "where id='$shid';");
   my @res = $sth->fetchrow_array;
   return ("$res[0], $res[1]"); 
}

sub GetNameGendJunFromID
{
   my ($shid) = @_;
   my $sth = MNSLQuery::query("select lname,fname,gender,junior from shooters ".
                  "where id='$shid';");
   my @res = $sth->fetchrow_array;
   my @rc;
   push(@rc, "$res[0], $res[1]");
   if ($res[2]) { # 1 == Male
      push(@rc, "&nbsp;");
   } else {
      push(@rc, "X");
   }
   if ($res[3]) {
      push(@rc, "X");
   } else {
      push(@rc, "&nbsp;");
   }
   return (@rc);
}

# get scores for a single shooter-event-division-session
# returned in order by date.
sub GetScoresForShooter
{
   my ($shid, $eid, $did, $session) = @_;
   return (GetColAsArray("select score from scores ".
                  "where shooterid='$shid' and eid='$eid' ".
                  "and did='$did' and leaguenum='$session' ".
                  "order by dte,id;"));
}

sub GetScoresForShooterDate
{
   my ($shid, $eid, $did, $session, $date) = @_;
   my ($q) = @_;
   my $sth = MNSLQuery::query("select cal,score from scores ".
                  "where shooterid='$shid' and eid='$eid' ".
                  "and did='$did' and leaguenum='$session' and dte='$date' ".
                  "order by id;");
   my @rc;
   while (my @res = $sth->fetchrow_array) {
      push (@rc, "$res[0]/$res[1]");
   }
   return (@rc);
}

sub GetScoresForShooterDate2
{
   my ($shid, $session, $date) = @_;
   my ($q) = @_;
   my $sth = MNSLQuery::query("select e.name,d.name,cal,score from scores as s, ".
                  "event as e, division as d ".
                  "where shooterid='$shid' and e.id=eid and d.id=did ".
                  "and leaguenum='$session' and dte='$date' ".
                  "order by s.id;");
   my @rc;
   while (my @res = $sth->fetchrow_array) {
      push (@rc, "$res[0]-$res[1] $res[2]/$res[3]");
   }
   return (@rc);
}

sub HaveScoresForEvDiv
{
   my ($eid, $did, $session) = @_;
   my @rc = GetColAsArray("select score from scores ".
                  "where eid='$eid' ".
                  "and did='$did' and leaguenum='$session';");
   return (scalar @rc > 0);
}

sub HaveScoresForEvDivDate
{
   my ($eid, $did, $session, $date) = @_;
   my @rc = GetColAsArray("select score from scores ".
                  "where eid='$eid' and dte='$date' ".
                  "and did='$did' and leaguenum='$session';");
   return (scalar @rc > 0);
}

sub GetTableWidth
{
   my ($eid, $did, $session, $date) = @_;
   my $sth = MNSLQuery::query("select max(colcount) from (".
                           "select count(shooterid) as colcount ".
                           "from scores where eid='$eid' and ".
                           "dte='$date' and did='$did' ".
                           "and leaguenum='$session' group by shooterid)t;");
   my @rc = $sth->fetchrow_array;
   return ($rc[0]);
}

sub GetTableWidth2
{
   my ($session, $date) = @_;
   my $sth = MNSLQuery::query("select max(colcount) from (".
                           "select count(shooterid) as colcount ".
                           "from scores where ".
                           "dte='$date' ".
                           "and leaguenum='$session' group by shooterid)t;");
   my @rc = $sth->fetchrow_array;
   return ($rc[0]);
}

sub PrintDayScores
{
   my ($file, $session, $html_base) = @_;

   my @shooterids = GetShooters($session);
   my @eids = GetEids();
   my @dids = GetDids();

   my @dates = GetDatesRev($session);

   # print scores by Days
   foreach my $date (@dates) {
      my $hrdate = ConvertDateHR($date);

      # print the scores for this day for each person
      print $file "\n<hr><a name=\"$date\"><h2>$hrdate</h2></a>\n";
      print $file "<a href=$html_base#top> TOP </a>\n";

      foreach my $eid (@eids) {
         foreach my $did (@dids) {
            my $event = GetEventFromID($eid);
            my $division = GetDivisionFromID($did);

            if (HaveScoresForEvDivDate($eid, $did, $session, $date)) {
               print $file "<h3>$event -- $division</h3>\n";
               print $file "<table cellpadding='5' border='1'>\n";
               print $file "<tr>\n";
               print $file "<th class=sname>Name</th>\n";
               print $file "<th colspan=10 align=left>Scores cal/score</th>\n";
               print $file "</tr>\n";
            } else {
               next;
            }

            my $maxwidth = GetTableWidth($eid, $did, $session, $date);

            my $bgcolor = "#FFFFFF";
            foreach my $shid (@shooterids) {
               my $name = GetNameFromID($shid);
               my @scores = GetScoresForShooterDate($shid, $eid, $did, $session, $date);

               if (scalar @scores < 1) {
                  next;
               }

               my $width = $maxwidth;

               print $file "<tr bgcolor=\"$bgcolor\">\n";
               if ($bgcolor eq "#FFFFFF") {
                  $bgcolor=$bg_grey;
               } else {
                  $bgcolor="#FFFFFF";
               }
               print $file "<td>$name</td>";
               foreach my $score (@scores) {
                  print $file "<td>$score</td>";
                  $width--;
               }
               while ($width > 0) {
                  print $file "<td>&nbsp;</td>";
                  $width--;
               }
               print $file "\n</tr>\n";
            }
            print $file "</table>\n";
         }
      }
   }
}

sub PrintDayScores2
{
   my ($file, $session) = @_;

   my @shooterids = GetShooters($session);
   my @eids = GetEids();
   my @dids = GetDids();

   my @dates = GetDatesRev($session);

   my $i = scalar(@dates);
   # print scores by Days
   foreach my $date (@dates) {
      my $hrdate = ConvertDateHR($date);

      # print the scores for this day for each person
      print $file "\n<hr><a name=\"$date\"><h2>$hrdate (Week: $i)</h2></a>\n";
      $i--;
      print $file "<a href=#top> TOP </a>\n";

      print $file "<table cellpadding='5' border='1'>\n";
      print $file "<tr>\n";
      print $file "<th class=sname>Name</th>\n";
      print $file "<th colspan=10 align=left>Scores -- Event-Div Cal/Score</th>\n";
      print $file "</tr>\n";

      my $maxwidth = GetTableWidth2($session, $date);

      my $bgcolor = "#FFFFFF";
      foreach my $shid (@shooterids) {
         my @scores = GetScoresForShooterDate2($shid, $session, $date);

         if (scalar @scores < 1) {
            next;
         }

         print $file "<tr bgcolor=\"$bgcolor\">\n";
         if ($bgcolor eq "#FFFFFF") {
            $bgcolor=$bg_grey;
         } else {
            $bgcolor="#FFFFFF";
         }

         my $name = GetNameFromID($shid);

         print $file "<td>$name</td>";

         my $width = $maxwidth;
         foreach my $score (@scores) {
            print $file "<td>$score</td>";
            $width--;
         }
         while ($width > 0) {
            print $file "<td>&nbsp;</td>";
            $width--;
         }
         print $file "\n</tr>\n";
      }
      print $file "</table>\n";
   }
}

sub write_table_header
{
   my ($file, $event, $division, $final) = @_;

   print $file "<h3>$event -- $division</h3>\n";
   print $file "<table>\n";
   print $file "<tr>\n";
   if ($final == 1) {
      print $file "<th class=flag>&nbsp;</th>\n";
   }
   print $file "<th class=sname>Name</th>\n";
   print $file "<th class=flag>F</th>\n";
   print $file "<th class=flag>J</th>\n";
   print $file "<th class=scorenum>1</th>\n";
   print $file "<th class=scorenum>2</th>\n";
   print $file "<th class=scorenum>3</th>\n";
   print $file "<th class=scorenum>4</th>\n";
   print $file "<th class=scorenum>5</th>\n";
   print $file "<th class=scorenum>6</th>\n";
   print $file "<th class=scorenum>7</th>\n";
   print $file "<th class=scorenum>8</th>\n";
   print $file "<th class=scorenum>9</th>\n";
   print $file "<th class=scorenum>10</th>\n";
   print $file "<th class=scoreavg>Avg</th>\n";
   print $file "<th class=scoreminmax>Min 1</th>\n";
   print $file "<th class=scoreminmax>Min 2</th>\n";
   print $file "</tr>\n";
}

sub process_scores
{
   my @scores = @_;
   my $avg = 0;
   my $num = 0;
   my $min1 = 500;
   my $min2 = 500;
   my @rc;
   my $i = 0;

   foreach my $score (@scores) {

      if ($score < $min2) {
         if ($score < $min1) {
            $min2 = $min1;
            $min1 = $score;
         } else {
            $min2 = $score;
         }
      }
      $avg += $score;
      push (@{$rc[$i]{'scores'}}, $score);

      $num++;

      if ($num == 10) {
         $avg -= $min1;
         $avg -= $min2;
         $avg /= 8;

         $rc[$i]{'avg'} = $avg;
         $rc[$i]{'min1'} = $min1;
         $rc[$i]{'min2'} = $min2;
         $rc[$i]{'qual'} = "X";
         $i++;

         $avg = 0;
         $num = 0;
         $min1 = 500;
         $min2 = 500;
      }
   }

   if ($num != 0) {
      if ($num >= 8) {
         $rc[$i]{'qual'} = "X";
      }
      if ($num == 9) {
         if ($min2 < $min1) {
            $min1 = $min2;
         }
         $avg -= $min1;
         $rc[$i]{'min1'} = $min1;
         $avg /= 8;
      } else {
         $avg /= $num;
      }

      $rc[$i]{'avg'} = $avg;
   }

   return (@rc);
}

sub get_scores_for_event_div
{
   my ($session, $eid, $did) = @_;
   my @rc;
   my %tickets;

   my @shooterids = GetShooters($session);
   foreach my $shid (@shooterids) {
      my ($name,$gender,$junior) = GetNameGendJunFromID($shid);
      my @scores = GetScoresForShooter($shid, $eid, $did, $session);

      my $num = scalar(@scores);
      my $rem = $num % 10;
      $num = int($num/10);
      if ($rem >= 8) {
         $num++;
      }
      if ($num > 0) {
         $tickets{$name} = $num;
      }

      my @proc_scores = process_scores(@scores);
      foreach my $set (@proc_scores) {
         $set->{'name'} = $name;
         $set->{'gender'} = $gender;
         $set->{'junior'} = $junior;
      }
      push (@rc, @proc_scores);
   }

   return (\@rc, \%tickets);
}

sub scores_sort
{
   my $aavg = $a->{'avg'};
   my $aqual = $a->{'qual'};
   my $anumscores = scalar($a->{'scores'});

   my $bavg = $b->{'avg'};
   my $bqual = $b->{'qual'};
   my $bnumscores = scalar($b->{'scores'});

   # if both scores are complete order by average
   if ($aqual eq "X" && $bqual eq "X") {
      return ($bavg <=> $aavg);
   }

   # Whichever is qualified has precidence
   if ($aqual eq "X") {
      return (-1);
   }
   if ($bqual eq "X") {
      return (1);
   }

   return ($bavg <=> $aavg);
}

#
# HTML($session)
# season == directory to generate file for.
sub HTML
{
   my ($html, $session, $sdate, $html_base, $final, $tik_file) = @_;

   open HTML_FILE, ">$html" or die "could not open $html";

   # get a list of dates for this session.
   my @dates = GetDates($session);

   write_html_header(\*HTML_FILE);

   my $hrdate = ConvertDateHR($sdate);
   my $week = scalar(@dates);
   my $date = ConvertDateHR($dates[$week - 1]);

   if ($final == 1) {
      print HTML_FILE "</head>\n";
      print HTML_FILE "<title>MNSL Scores -- Season $session -- Final</title>\n";
      print HTML_FILE "<body>\n";
      print HTML_FILE "<a name=top>\n";
      print HTML_FILE "<div class=pageheader>Season $session -- Final</div>\n";
   } else {
      print HTML_FILE "</head>\n";
      print HTML_FILE "<title>MNSL Scores -- Season $session; Week $week(Started: $hrdate); </title>\n";
      print HTML_FILE "<body>\n";
      print HTML_FILE "<a name=top>\n";
      print HTML_FILE "<div class=pageheader>Season $session; Week $week ($date) [Start: $hrdate]</div>\n";
   }

   my @eids = GetEids();
   my @dids = GetDids();

   my %tickets;

   foreach my $eid (@eids) {
      foreach my $did (@dids) {
         my $event = GetEventFromID($eid);
         my $division = GetDivisionFromID($did);

         if (HaveScoresForEvDiv($eid, $did, $session)) {
            write_table_header(\*HTML_FILE, $event, $division, $final);
         } else {
            next;
         }

         my ($p_scores, $p_t) = get_scores_for_event_div($session, $eid, $did);
         my @scores = @{$p_scores};

         for my $name (keys %{$p_t}) {
            my $num = $p_t->{$name};
            #print "$name gets $num more tickets for $event/$division\n";
            $tickets{$name} = $tickets{$name} + $num;
         }

         if ($final == 1) {
            @scores = sort scores_sort @scores;
         }

         my $i = 1;
         my $sep = 0;
         my $bgcolor = "#FFFFFF";
         foreach my $set (@scores) {
            my @tmp = @{$set->{'scores'}};
            my $avg = $set->{'avg'};
            my $min1 = $set->{'min1'};
            my $min2 = $set->{'min2'};
            my $qual = $set->{'qual'};
            my $name = $set->{'name'};
            my $gender = $set->{'gender'};
            my $junior = $set->{'junior'};

            #debug: print "$name : $avg\n";

            if ($final == 1 && $qual ne "X" && $sep == 0) {
               print HTML_FILE "<tr bgcolor=#000000>";
               print HTML_FILE "<td></td>";
               for (my $j = 0; $j < 16; $j++) {
                  print HTML_FILE "<td></td>";
               }
               print HTML_FILE "</tr>";
               $sep = 1;
            }

            print HTML_FILE "<tr bgcolor=\"$bgcolor\">";
            if ($bgcolor eq "#FFFFFF") {
               $bgcolor=$bg_grey;
            } else {
               $bgcolor="#FFFFFF";
            }

            if ($final == 1) {
               print HTML_FILE "<td>$i</td>";
               $i++;
            }
            print HTML_FILE "<td>$name</td>";
            print HTML_FILE "<td>$gender</td>";
            print HTML_FILE "<td>$junior</td>";

            for (my $i = 0; $i < 10; $i++) {
               if ($tmp[$i] != "") {
                  print HTML_FILE "<td class=cl>$tmp[$i]</td>";
               } else {
                  print HTML_FILE "<td class=cl>&nbsp;</td>";
               }
            }
            printf HTML_FILE "<td class=cl>%03.03f</td>", $avg;
            if ($min1 != "") {
               print HTML_FILE "<td class=cl>$min1</td>";
            } else {
               print HTML_FILE "<td class=cl>&nbsp;</td>";
            }
            if ($min2 != "") {
               print HTML_FILE "<td class=cl>$min2</td>";
            } else {
               print HTML_FILE "<td class=cl>&nbsp;</td>";
            }
            print HTML_FILE "</tr>\n";
         }
         print HTML_FILE "</table>\n";
      }
   }

   if ($final == 1) {
      my $total = 0;

      open HTML_FILE2, ">$tik_file" or die "could not open $tik_file";
      write_html_header(\*HTML_FILE2);
      print HTML_FILE2 "<h3>Tickets earned Session $session</h3>";
      print HTML_FILE2 "<table>";
      print HTML_FILE2 "<tr><th>Name</th><th>Num Tickets</th><th>Recv</th></tr>";
      my $bgcolor = "#FFFFFF";
      for my $name (sort keys %tickets) {
         my $num = $tickets{$name};
         print HTML_FILE2 "<tr bgcolor=\"$bgcolor\">";
         if ($bgcolor eq "#FFFFFF") {
            $bgcolor=$bg_grey;
         } else {
            $bgcolor="#FFFFFF";
         }
         print HTML_FILE2 "<td>$name</td><td align=\"center\">$num</td><td>&nbsp;</td>";
         $total += $num;
         print HTML_FILE2 "</tr>";
      }
      print HTML_FILE2 "</table>";
      print HTML_FILE2 "<br>$total tickets earned this Session</p>";
      print HTML_FILE2 "</body></html>";
      write_html_footer(\*HTML_FILE2);
      close(HTML_FILE2);

   } else {
      # we have a list of dates for this session from above.  Print those dates with week numbers.
      # for each date write header with quick links
      print HTML_FILE "<hr><br>";
      print HTML_FILE "Click below (or scroll down) to verify your scores on individual days<p>\n";
      print HTML_FILE "</p><table class=\"steggy\">\n";
      print HTML_FILE "<tbody><tr  class=\"steggy\">\n";
      print HTML_FILE "<td class=\"datelist\">\n";
      my $i=1;
      foreach my $date (@dates) {
            my $hrdate = ConvertDateHR($date);
            # print the header for this
            print HTML_FILE "<a href=\"$html_base#$date\">$hrdate (Wk: $i)</a> &nbsp;|&nbsp;\n";
            $i++;
      }
      print HTML_FILE "</tr>\n";
      print HTML_FILE "</tbody></table>\n";

      #PrintDayScores(\*HTML_FILE, $session);
      PrintDayScores2(\*HTML_FILE, $session, $html_base);
   }

   write_html_footer(\*HTML_FILE);
   close(HTML_FILE);
}

sub DataFile
{
   my ($file, $db_user, $db_pw, $db) = @_;
   system ("mysqldump -u $db_user --password=$db_pw $db > $file");
}

