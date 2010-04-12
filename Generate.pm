package Generate;

use strict;
use vars qw($VERSION);

use MNSLQuery;

$VERSION     = 1.00;

my $tmp = "tmp";
my @month_names = ("", "January", "Febuary", "March", "April", "May", "June",
                  "July", "August", "September", "October", "November", "December");

sub write_html_header
{
   my ($file, $session, $sdate) = @_;
   my $hrdate = ConvertDateHR($sdate);

   print $file "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";   
   print $file "<html>\n";
   print $file "<head>\n";
   #Steggy added - read style file and print in head of HTML
   open(MYDATA ,"css") or die ("Error: cannot open file 'css'\n");
   my @lines = <MYDATA>;
   print $file "@lines";
   close MYDATA;
   print $file "</head>\n";
   print $file "<title>MNSL Scores -- Season $session (Started: $hrdate); </title>\n";
   print $file "<body>\n";
   print $file "<a name=top>\n";  
   print $file "<div class=pageheader>MNSL Scores -- Season $session (Started: $hrdate)</div>\n";
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

#
# HTML($session)
# season == directory to generate file for.
sub HTML
{
   my ($html, $session, $sdate) = @_;

   open HTML_FILE, ">$html" or die "could not open $html";
   write_html_header(\*HTML_FILE, $session, $sdate);

   my @shooterids = GetShooters($session);
   my @eids = GetEids();
   my @dids = GetDids();


   foreach my $eid (@eids) {
      foreach my $did (@dids) {
         my $event = GetEventFromID($eid);
         my $division = GetDivisionFromID($did);

         if (HaveScoresForEvDiv($eid, $did, $session)) {
            print HTML_FILE "<h3>$event -- $division</h3>\n";
            print HTML_FILE "<table>\n";
            print HTML_FILE "<tr>\n";
            print HTML_FILE "<th class=sname>Name</th>\n";
            print HTML_FILE "<th class=scorenum>1</th>\n";
            print HTML_FILE "<th class=scorenum>2</th>\n";
            print HTML_FILE "<th class=scorenum>3</th>\n";
            print HTML_FILE "<th class=scorenum>4</th>\n";
            print HTML_FILE "<th class=scorenum>5</th>\n";
            print HTML_FILE "<th class=scorenum>6</th>\n";
            print HTML_FILE "<th class=scorenum>7</th>\n";
            print HTML_FILE "<th class=scorenum>8</th>\n";
            print HTML_FILE "<th class=scorenum>9</th>\n";
            print HTML_FILE "<th class=scorenum>10</th>\n";
            print HTML_FILE "<th class=scoreavg>Avg</th>\n";
            print HTML_FILE "<th class=scoreminmax>Min 1</th>\n";
            print HTML_FILE "<th class=scoreminmax>Min 2</th>\n";
            print HTML_FILE "</tr>\n";
         } else {
            next;
         }

         foreach my $shid (@shooterids) {
            my $name = GetNameFromID($shid);
            my @scores = GetScoresForShooter($shid, $eid, $did, $session);

            my $min1 = "500";
            my $min2 = "500";
            my $avg = 0;
            my $num = 0;

            foreach my $score (@scores) {

               # this takes care of printing an empty row when there are exactly 10 scores
               if (int($num) == 0) {
                  print HTML_FILE "<tr><td>$name</td>";
               }

               print HTML_FILE "<td class=cl>$score</td>";

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
                  printf HTML_FILE "<td class=cl>%03.02f</td><td class=cl>%d</td>".
                                 "<td class=cl>%d</td></tr>\n", $avg,$min1,$min2;
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
                  print HTML_FILE "<td>&nbsp;</td>";
                  $num++;
               }
               printf HTML_FILE "<td class=cl>%03.02f</td>", $avg;
               print HTML_FILE "<td class=cl>$min1</td>";
               if ($min2 != 500) {
                  print HTML_FILE "<td class=cl>$min2</td></tr>\n";
               } else {
                  print HTML_FILE "<td class=cl>&nbsp;</td></tr>\n";
               }
            }
            print HTML_FILE "</tr>\n";
         }
         print HTML_FILE "</table>\n";

      }
   }

   # get a list of dates for this session.
   my @dates = GetDates($session);
   my $x = 0;
   # for each date write header with quick links
   print HTML_FILE "<hr><br>";
   print HTML_FILE "Click below (or scroll down) for scores on individual days<p>\n";
   print HTML_FILE "<table class=datelist>\n";
   print HTML_FILE "<tr  class=datelist>\n";
   foreach my $date (@dates) {
         my $hrdate = ConvertDateHR($date);
         # print the header for this
         print HTML_FILE "<td class=datelist><a href=\"#$date\">$hrdate</a></td>\n";
         $x++;
         if ($x == 7){
         print HTML_FILE "<tr><tr>\n";
	 $x = 0
         }
   }
   print HTML_FILE "</tr>\n";
   print HTML_FILE "</table>\n";

   my @dates = GetDatesRev($session);

   # print scores by Days
   foreach my $date (@dates) {
      my $hrdate = ConvertDateHR($date);

      # print the scores for this day for each person
      print HTML_FILE "\n<hr><a name=\"$date\"><h2>$hrdate</h2></a>\n";
      print HTML_FILE "<a href=#top> TOP </a>\n";

      foreach my $eid (@eids) {
         foreach my $did (@dids) {
            my $event = GetEventFromID($eid);
            my $division = GetDivisionFromID($did);

            if (HaveScoresForEvDivDate($eid, $did, $session, $date)) {
               print HTML_FILE "<h3>$event -- $division</h3>\n";
               print HTML_FILE "<table cellpadding='5' border='1'>\n";
               print HTML_FILE "<tr>\n";
               print HTML_FILE "<th class=sname>Name</th>\n";
               print HTML_FILE "<th colspan=10 align=left>Scores cal/score</th>\n";
               print HTML_FILE "</tr>\n";
            } else {
               next;
            }

            foreach my $shid (@shooterids) {
               my $name = GetNameFromID($shid);
               my @scores = GetScoresForShooterDate($shid, $eid, $did, $session, $date);

               if (scalar @scores < 1) {
                  next;
               }

               print HTML_FILE "<tr>\n";
               print HTML_FILE "<td>$name</td>";
               foreach my $score (@scores) {
                  print HTML_FILE "<td>$score</td>";
               }
               print HTML_FILE "\n</tr>\n";
            }
            print HTML_FILE "</table>\n";
         }
      }
   }

   write_html_footer(\*HTML_FILE);
   close(HTML_FILE);
}

sub DataFile
{
   my ($file, $db_user, $db_pw, $db) = @_;
   system ("mysqldump -u $db_user --password=$db_pw $db > $file");
}

