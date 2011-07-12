#!/usr/bin/perl

use File::Basename;
use Cwd 'abs_path';

use Tk;
use Tk::MatchEntry;
use Tk::FileDialog;
use Tk::BrowseEntry;
use Tk::JBrowseEntry;
use Tk::DateEntry;
use Tk::ROText;
use Tk::Pane;


use Generate;
use MNSLQuery;


# configuration vars
$dbuser = "";
$dbpw = "";
$db = "";
$session = ();
$session_st = ();
$date = ();
$html_base = "";
$basedir = dirname(abs_path($0));
$conf = "$basedir/scores.conf";
$datadir = "$basedir/data";

# Report version right from the get go.
print "Version: ";
system("cat VERSION");

# Vars for UI
@shooters = ("");
$shooter;
$shooters_entry = undef;
@divisions = ();
@calibers = ();
$caliber_entry = undef;
$caliber;
$score_entry = undef;
@events = ();
# In the MenuBar
$mb_date = undef;
$mb_session = undef;

sub DisplayError
{
   my ($mw, $msg) = @_;
   print STDERR $msg;
   my $win = $mw->DialogBox(-title => "ERROR!", -buttons => ["Ok"]);
   $win->Label(-text => "Error: $msg")->pack();
   $win->Show();
}

sub InvalidSession
{
   my ($s) = @_;
   my $sth = MNSLQuery::query("select id,sdate from league where lnum='$s';");
   my @s = $sth->fetchrow_array;
   if (scalar @s > 0) {
      $session_st = $s[1];
   }
   return (scalar @s < 1);
}

sub CreateSession
{
   my ($s, $d) = @_;
   MNSLQuery::query("insert into league (lnum, sdate) values ($s, '$d');");
}

sub AddSession
{
   my ($main, $s) = @_;
   my $sd;
   my $dialog = $main->DialogBox(-title => "New Session $s", -buttons => ["OK","Cancel"]);
   $dialog->Label(-text => "Enter Start Date for Session $s")->pack(-side=>'top');
   $dialog->DateEntry(-textvariable =>\$sd, -dateformat=>4)->pack(-side=>'bottom');
   $choice = $dialog->Show();
   if ($choice eq "OK") {
      CreateSession($s, $sd);
      return (1);
   }
   return (0);
}

sub ChooseSession
{
   my ($main) = @_;
   my $s;
   my $dialog = $main->DialogBox(-title => "Change Session", -buttons => ["OK","Cancel"]);
   $dialog->Label(-text => "Enter Session number:")->pack(-side=>'left');
   $dialog->Entry(-textvariable => \$s)->pack(-side=>'left');
   $choice = $dialog->Show();
   if ($choice eq "OK") {
      if (InvalidSession($s)) {
         my $dialog = $main->DialogBox(-title => "Invalid Session", -buttons => ["OK","Cancel"]);
         $dialog->Label(-text => "Session $s is invlaid: Create new?")->pack(-side=>'left');
         $choice = $dialog->Show();
         if ($choice eq "OK") {
            if (!AddSession($main, $s)) {
               return;
            }
	 } else {
            return;
	 }
      }
      $session = $s;
      my $title = "MNSL Scores -- Session $session ($session_st)";
      $main->title("$title");
   }
}

sub SplitName
{
   my ($name) = @_;
   if ($name =~ /(\S*)[ ]*(.*)/) {
      my $fname = $1;
      my $lname = $2;
      $fname =~ s/\'/\\'/g;
      $lname =~ s/\'/\\'/g;
      return ($fname, $lname);
   }
   die "Failed to split $name\n";
}

sub UpdateShooter
{
   my ($old, $fname, $lname, $email, $phone, $addr, $city, $st, $zip, $gender,
      $junior, $staff) = @_;

   my ($old_fname, $old_lname) = SplitName($old);

   $fname =~ s/\'/\\'/g;
   $lname =~ s/\'/\\'/g;

   my $sth = MNSLQuery::query(
            "select id,fname,lname from shooters where fname='$old_fname' and lname='$old_lname';");
   my @s = $sth->fetchrow_array;
   MNSLQuery::query("update shooters set fname='$fname',lname='$lname',email='$email',".
                  "phone='$phone',address='$addr',city='$city',state='$st',zip='$zip',".
                  "gender='$gender',junior='$junior',staff='$staff' ".
                  "where id='$s[0]';");
}

sub GetNumScoresForID
{
   my ($id) = @_;
   my $sth = MNSLQuery::query(
            "select count(id) from scores where shooterid='$id';");
   my @s = $sth->fetchrow_array;
   if (scalar @s < 1) {
      return (0);
   }
   return ($s[0]);
}

sub DeleteShooter
{
   my ($id) = @_;
   my $sth = MNSLQuery::query("delete from shooters where id='$id';");
   my $sth = MNSLQuery::query("delete from scores where shooterid='$id';");
}

sub EditPerson
{
   my ($main) = @_;
   my $old_name = "";
   my $fname = "";
   my $lname = "";
   my $email = "";
   my $phone = "";
   my $addr = "";
   my $city = "";
   my $st = "";
   my $zip = "";

   my $dialog = $main->DialogBox(-title => "Edit Person", -buttons => ["OK","Cancel"]);
   my $topframe = $dialog->Frame()->pack(-side=>'top');
   $topframe->Label(-text => "Change:")->pack(-side=>'left');
   my $sh_ent = $topframe->MatchEntry(-textvariable => \$old_name,
                                    -ignorecase => 'true',
                                    -choices => \@shooters)
                              ->pack(-side=>'left');
   $sh_ent->selection('range', 0, 60);
   $sh_ent->focus();
   my $choice = $dialog->Show();

   if ($choice eq "OK") {

      while (1) {
         my @shooter = GetShooter($old_name);
         if (scalar @shooter < 1) {
            my $win = $main->DialogBox(-title => 'ERROR: Shooter not found',
                                       -buttons => ["Yes","Cancel"]);
            $win->Label(-text => "Shooter $old_name does not exist: add them?")->pack();
            $choice = $win->Show();
            if ($choice eq "Cancel") {
               return;
            }
            AddShooterEntry($old_name);
            @shooter = GetShooter($old_name);
         }
   
         my $id = $shooter[0];
         $fname = $shooter[1];
         $lname = $shooter[2];
         $email = $shooter[3];
         $phone = $shooter[4];
         $addr = $shooter[5];
         $city = $shooter[6];
         $st = $shooter[7];
         $zip = $shooter[8];
         $gender = $shooter[9];
         $junior = $shooter[10];
         $staff = $shooter[11];
   
         my $dialog = $main->DialogBox(-title => "Enter New Shooter Info",
                                       -buttons => ["OK","Cancel","DELETE"]);
         my $midframe = $dialog->Frame()->pack(-side=>'bottom');
         
         my $foc = $midframe->Entry(-textvariable => \$fname);

         $midframe->Label(-text => "First")->grid($foc);
         $midframe->Label(-text => "Last")->grid(
               $midframe->Entry(-textvariable => \$lname));
         $midframe->Label(-text => "email")->grid(
               $midframe->Entry(-textvariable => \$email));

         if ($gender eq 1) {
            $gender = "Male";
         } else {
            $gender = "Female";
         }

         my @genders = ("Male", "Female");
         $midframe->Label(-text => "Gender")->grid(
               $midframe->Optionmenu(-options => \@genders,
                                 -variable => \$gender));

         $midframe->Label(-text => "Junior")->grid(
               $midframe->Checkbutton(-variable => \$junior));

         $midframe->Label(-text => "Staff")->grid(
               $midframe->Checkbutton(-variable => \$staff));

         $midframe->Label(-text => "phone")->grid(
               $midframe->Entry(-textvariable => \$phone));
         $midframe->Label(-text => "address")->grid(
               $midframe->Entry(-textvariable => \$addr));
         $midframe->Label(-text => "city")->grid(
               $midframe->Entry(-textvariable => \$city));
         $midframe->Label(-text => "state")->grid(
               $midframe->Entry(-textvariable => \$state));
         $midframe->Label(-text => "zip")->grid(
               $midframe->Entry(-textvariable => \$zip));

         
         $foc->selection('range', 0, 60);
         $foc->focus();
         my $choice = $dialog->Show();
         if ($choice eq "OK") {
            if ($fname eq "" && $lname eq "") {
               my $win = $main->DialogBox(-title => 'ERROR: No Name', -buttons => ["OK"]);
               $win->Label(-text => "At minimum, a first or last name must be specified.")->pack();
               $win->Show();
               next;
            }
            @shooter = GetShooter("$fname $lname");
            if (scalar @shooter > 1 && $shooter[0] != $id) {
               my $win = $main->DialogBox(-title => 'ERROR: Duplicate Entry', -buttons => ["OK"]);
               $win->Label(-text => "$fname $lname already exists as another entry.\n".
                                 "First and last name must be unique for all shooters.\n".
                                 "Please change your entry.")->pack();
               $win->Show();
               next;
            }
            if ($gender eq "Male") {
               $gender = 1;
            } else {
               $gender = 0;
            }
            UpdateShooter($old_name, $fname, $lname, $email, $phone, $addr,
                        $city, $st, $zip, $gender, $junior, $staff);
            UpdateShooterList();
            print "Updated \"$old_name\":\n";
            print "   \"$fname $lname\", $email, $phone, $addr, $city, $st, ".
                  "$zip, $gender, $junior\n";
            return;
         } else {
            if ($choice eq "DELETE") {
               my $count = GetNumScoresForID($id);
               my $win = $main->DialogBox(-title => 'Confirm Delete',
                                       -buttons => ["OK", "Cancel"]);
               $win->Label(-text => "Delete $fname $lname from the database?\n".
                                 "$count score(s) will be deleted as well.\n")
                           ->pack();
               my $choice = $win->Show();
               if ($choice eq "OK") {
                  DeleteShooter($id);
                  UpdateShooterList();
                  print "Deleted \"$old_name\";\n";
               }
            }
            return;
         }
      }
   }
}

sub GetScoresDayShooter
{
   my ($date, $name) = @_;
   my ($fname, $lname) = SplitName($name);
   my $sth = MNSLQuery::query("select s.id, e.name, d.name, s.cal, s.score ".
                     "from scores as s, shooters as sh, event as e, division as d ".
                     "where s.eid=e.id and s.did=d.id and s.shooterid=sh.id ".
                     "and sh.fname='$fname' and sh.lname='$lname' and dte='$date'
                     order by dte,id;");
   my @rc;
   while (my @res = $sth->fetchrow_array) {
      push (@rc, \@res);
   }
   return (@rc);
}

sub GetScoresDay
{
   my ($date) = @_;
   my ($fname, $lname) = SplitName($name);
   my $sth = MNSLQuery::query("select sh.fname, sh.lname, e.name, d.name, s.cal, s.score ".
                     "from scores as s, shooters as sh, event as e, division as d ".
                     "where s.eid=e.id and s.did=d.id and s.shooterid=sh.id ".
                     "and dte='$date' order by sh.lname,sh.fname;");
   my @rc;
   while (my @res = $sth->fetchrow_array) {
      push (@rc, \@res);
   }
   return (@rc);
}

sub UpdateScore
{
   my ($id, $event, $div, $cal, $score, $delete) = @_;

   if ($delete) {
      my $sth = MNSLQuery::query("delete from scores where id=$id;");
      return;
   }

   my $sth = MNSLQuery::query("select id from event where name='$event';");
   my @res = $sth->fetchrow_array;
   my $eid = $res[0];

   $sth = MNSLQuery::query("select id from division where name='$div';");
   @res = $sth->fetchrow_array;
   my $did = $res[0];

   $sth = MNSLQuery::query("update scores set eid=$eid,did=$did,cal='$cal',score='$score' ".
                           "where id='$id';");
}

sub ViewScores
{
   my ($main) = @_;
   my $date = GetToday();
   my @dates = Generate::GetDates($session);
   my $win = $main->DialogBox(-title => 'Choose Date', -buttons => ["OK","Cancel"]);
   $win->Label(-text => "Choose Date")->pack(-side => 'top', -fill => 'x');
   my $d = $win->Optionmenu(-options => \@dates, -variable => \$date)->pack(-side=>'left');
   $d->focus();
   my $choice = $win->Show();

   if ($choice eq "OK") {
      # read scores for that day and shooter
      my @scores = GetScoresDay($date);

      my $hrdate = Generate::ConvertDateHR($date);
      # build dialog with those scores which can be editied.
      my $win = $main->DialogBox(-title => "Scores for $hrdate", -buttons => ["OK"]);
      $win->Label(-text => "Scores for $hrdate")->pack(-side => 'top', -fill => 'x');
      my $main_frame = $win->Frame->pack(-side=>'bottom', -fill=>'x');

      my $print_frame = $main_frame->Scrolled('Frame',
                                       -width => 400, -height => 400,
                                       -scrollbars => 'e');
      $print_frame->pack(-side=>'top', -fill=>'x');
      $print_frame->Label(-text => "Name")->grid(
                     $print_frame->Label(-text => "Event"),
                     $print_frame->Label(-text => "Division"),
                     $print_frame->Label(-text => "Caliber"),
                     $print_frame->Label(-text => "Score"),
                      -sticky => "nsew");

      foreach my $score (@scores) {
         my $name = "$score->[0] $score->[1]";
         $print_frame->Label(-text => $name)->grid(
                        $print_frame->Label(-text => $score->[2]),
                        $print_frame->Label(-text => $score->[3]),
                        $print_frame->Label(-text => $score->[4]),
                        $print_frame->Label(-text => $score->[5]),
                        -sticky => "nsew");

      }

      my $choice = $win->Show();
   }
}

sub EditScores
{
   my ($main) = @_;
   my $date = GetToday();
   my @dates = Generate::GetDates($session);
   my $name = "";
   my $win = $main->DialogBox(-title => 'Choose Date and Name to change',
                              -buttons => ["OK","Cancel"]);
   $win->Label(-text => "Choose Date and Name to change")->pack(-side => 'top', -fill => 'x');
   $win->Optionmenu(-options => \@dates, -variable => \$date)->pack(-side=>'left');
   #$win->DateEntry(-textvariable =>\$date, -dateformat=>4)->pack(-side=>'left');
   my $enter_name = $win->MatchEntry(-textvariable => \$name,
                                 -ignorecase => 'true',
                                 -choices => \@shooters)
                                 ->pack(-side=>'left');
   $enter_name->selection('range', 0, 60);
   $enter_name->focus();
   my $choice = $win->Show();

   if ($choice eq "OK") {
      # read scores for that day and shooter
      my @scores = GetScoresDayShooter($date, $name);

      if (scalar @scores < 1) {
         my $win = $main->DialogBox(-title => 'ERROR: No Scores Found', -buttons => ["OK"]);
         $win->Label(-text => "No Scores found for '$name' on '$date'")->pack();
         $win->Show();
         return;
      }

      my $hrdate = Generate::ConvertDateHR($date);
      # build dialog with those scores which can be editied.
      my $win = $main->DialogBox(-title => "Change scores for $name ($hrdate)",
                                 -buttons => ["OK","Cancel"]);
      my $main_frame = $win->Frame->pack(-side=>'bottom', -fill=>'x');

      my $print_frame = $main_frame->Frame->pack(-side=>'top', -fill=>'x');
      $print_frame->Label(-text => "Event")->grid(
                     $print_frame->Label(-text => "Division"),
                     $print_frame->Label(-text => "Caliber"),
                     $print_frame->Label(-text => "Score"),
                     $print_frame->Label(-text => "Delete"),
                      -sticky => "nsew");

      foreach my $score (@scores) {
         # score[0] is the id of the row we would change
         my $event = $print_frame->Optionmenu(-options => \@events,
                                       -variable => \$score->[1]),
         my $division = $print_frame->Optionmenu(-options => \@divisions,
                                       -variable => \$score->[2]),
         $caliber_entry = $print_frame->MatchEntry(-choices => \@calibers,
                                       -ignorecase => 'true',
                                       -textvariable => \$score->[3]);

         $score->[5] = 0; # signifys don't delete
         $event->grid(
                  $division,
                  $caliber_entry,
                  $print_frame->Entry(-textvariable => \$score->[4]),
                  $print_frame->Checkbutton(-variable => \$score->[5]),
                  -sticky => "nsew");

      }

      my $choice = $win->Show();
      if ($choice eq "OK") {
         print "Updating scores for \"$name\" on $date\n";
         foreach my $score (@scores) {
            UpdateScore($score->[0], $score->[1], $score->[2], $score->[3],
                        $score->[4], $score->[5]);
            print "   $score->[0], $score->[1], $score->[2], $score->[3], $score->[4]";
            if ($score->[5]) {
               print " <=== DELETED\n";
            } else {
               print "\n";
            }
         }
      }
   }
}

sub showGenComplete
{
   my ($title, $main) = @_;
   my $win = $main->DialogBox(-title => "$title", -buttons => ['OK']);
   $win->Label(-text => "$title")->pack;

   my $geom = $main->geometry;
   if ($geom =~ m/(\d+)x(\d+)\+(\d+)\+(\d+)/) {
      my $left = int (($1/2) + $3);
      my $top = int ($4);
      $win->geometry("+$left+$top");
   }
   $win->Show;
}

sub GetCaliberID
{
   my ($caliber) = @_;
   my $sth = MNSLQuery::query("select id from caliber where name='$caliber';");
   my @s = $sth->fetchrow_array;
   return ($s[0]);
}

sub EditCaliber
{
   my ($main) = @_;
   my $old_cal;
   my $new_cal;
   my $win = $main->DialogBox(-title => "Edit Caliber",
                              -buttons => ['Change', 'Delete', 'Cancel']);
   $win->Label(-text=>"Change")->pack;
   my $division = $win->Optionmenu(-options=>\@calibers,
                                       -variable=>\$old_cal)->pack;
   $win->Label(-text=>"To")->pack;
   my $cal_entry = $win->Entry(-textvariable => \$new_cal)->pack;

   my $choice = $win->Show;
   if ($choice eq 'Change') {
      print ("Changing caliber \"$old_cal\" to \"$new_cal\"\n");
      my $id = GetCaliberID($old_cal);
      MNSLQuery::query("update caliber set name='$new_cal' where id='$id';");
   } elsif ($choice eq 'Delete') {
      print ("Deleting caliber \"$old_cal\"\n");
      my $id = GetCaliberID($old_cal);
      MNSLQuery::query("delete from caliber where id='$id';");
   }
   UpdateCaliberList();
}

sub GetStartDate
{
   my ($s) = @_;
   my $sth = MNSLQuery::query("select sdate from league where lnum='$s';");
   my @res = $sth->fetchrow_array;
   if (scalar @res < 1) { die "Invalid session detected\n"; }
   return ($res[0]);
}

sub GenHTML
{
   my ($main) = @_;

   my $sdate = GetStartDate($session);
   my $file = "$datadir/Session$session-$sdate.html";

   Generate::HTML($file, $session, $sdate, $html_base, 0, "");

   my $win = $main->DialogBox(-title => "Generate HTML Complete",
                  -buttons => ['OK', 'View in Google Chrome']);
   $win->Label(-text => "Written to: $file\n")->pack;
   my $choice = $win->Show;
   if ($choice eq 'View in Google Chrome') {
      system("google-chrome $file&");
   }
}

sub GenHTMLFinal
{
   my ($main) = @_;

   my $sdate = GetStartDate($session);
   my $file = "$datadir/Session$session-$sdate-final.html";
   my $tik_file = "$datadir/Session$session-$sdate-tickets.html";

   Generate::HTML($file, $session, $sdate, $html_base, 1, $tik_file);

   my $win = $main->DialogBox(-title => "Generate HTML Complete",
                  -buttons => ['OK', 'View in Google Chrome']);
   $win->Label(-text => "Written to: $file\nAnd: $tik_file")->pack;
   my $choice = $win->Show;
   if ($choice eq 'View in Google Chrome') {
      system("google-chrome $file&");
   }
}

sub ExportDataFile
{
   my ($main) = @_;

   my $win = $main->FileDialog();
   my $today = GetToday();
   my $file = "Session-$session\_$session_st\_$today.sql";
   $win->configure(-Title => "Export Data to...", -ShowAll => 'yes',
                  -Path => $datadir, -File => $file);
   my $choice = $win->Show();

   if ($choice ne "") {
      Generate::DataFile($choice, $dbuser, $dbpw, $db);
      showGenComplete("Export '$file' Complete", $main);
   }
}

sub GetToday
{
   # Get todays date as a default
   my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek,
      $dayOfYear, $daylightSavings) = localtime();
   my $year = 1900 + $yearOffset;
   my $month = 1 + $month;
   return (sprintf("%04d-%02d-%02d", $year, $month, $dayOfMonth));
}

sub ReadConfig
{
   open FILE, "<$conf" or die "Could not open config \"$conf\"\n";
   while (<FILE>) {
      chomp $_;
      $_ =~ s/\s+//;
      my ($var, $value) = split /=/, $_;
      if ("$var" eq "db_user") {
         $dbuser = $value;
      }
      if ("$var" eq "db_pw") {
         $dbpw = $value;
      }
      if ("$var" eq "db") {
         $db = $value;
      }
      if ("$var" eq "session") {
         $session = $value;
      }
      if ("$var" eq "html_base") {
         $html_base = $value;
      }
   }
   close (FILE);
   if ("$dbuser" eq "") {
      die "Failed to retrieve database user from config: $conf\n";
   }

   $date = GetToday();
}

sub WriteConfig
{
   open FILE, "+>$conf" or die "Could not write config \"$conf\"\n";
   print FILE "db_user= $dbuser\n";
   print FILE "db_pw=   $dbpw\n";
   print FILE "db=      $db\n";
   print FILE "session= $session\n";
   print FILE "html_base= $html_base\n";
   close (FILE);
}

sub Exit
{
   WriteConfig();
   exit;
}


sub ChangeDate
{
   my ($main) = @_;
   my $d;
   my $win = $main->DialogBox(-title => 'Change Date',
                     -buttons => ["OK","Cancel"]);
   $win->Label(-text => "Change Date")->pack;
   $win->DateEntry(-textvariable =>\$d, -dateformat=>4)->pack;
   $choice = $win->Show();
   if ($choice eq "OK") {
      $date = $d;
      my $hrdate = Generate::ConvertDateHR($date);
      $mb_date->configure(-text=>"$hrdate");
   }
   print "Date changed to: $hrdate\n";
}

sub LoadShooterDB
{
   my $sth = MNSLQuery::query("select fname,lname from shooters;");
   while (my @s = $sth->fetchrow_array) {
      push (@shooters, "$s[0] $s[1]");
   }
}

sub LoadCaliberDB
{
   $sth = MNSLQuery::query("select name from caliber;");
   while (my @s = $sth->fetchrow_array) {
      push (@calibers, @s);
   }
}

sub LoadDBs
{
   LoadShooterDB();
   LoadCaliberDB();

   $sth = MNSLQuery::query("select name from event;");
   while (my @s = $sth->fetchrow_array) {
      push (@events, @s);
   }

   $sth = MNSLQuery::query("select name from division;");
   while (my @s = $sth->fetchrow_array) {
      push (@divisions, @s);
   }
}

sub UpdateShooterList
{
   @shooters = (); # clear
   LoadShooterDB(); # load
   $shooters_entry->choices(\@shooters);
}

sub GetShooter
{
   my ($name) = @_;
   my ($fname, $lname) = SplitName($name);
   my $sth = MNSLQuery::query("select id,fname,lname,email,phone,address,".
                              "city,state,zip,gender,junior,staff ".
                              "from shooters where fname='$fname' ".
                              "and lname='$lname';");
   my @s = $sth->fetchrow_array;
   return (@s);
}

sub AddShooterEntry
{
   my ($new_shooter) = @_;

   # don't add an entry already in the DB
   foreach $i (@shooters) {
      if ($i eq $new_shooter) {
         return;
      }
   }

   my ($fname, $lname) = SplitName($new_shooter);
   MNSLQuery::query("insert into shooters (fname,lname) values ('$fname', '$lname')");

   UpdateShooterList();

   print "Added: \"$new_shooter\"\n";
}

sub AddCaliberEntry
{
   my ($caliber) = @_;

   # don't add an entry already in the DB
   foreach $i (@calibers) {
      if ($i eq $caliber) {
         return;
      }
   }

   MNSLQuery::query("insert into caliber (name) values ('$caliber')");

   # and to the array on the fly
   push(@calibers, $caliber);
   $caliber_entry->choices(\@calibers);

   print "Added: \"$caliber\"";
}

sub UpdateCaliberList
{
   @calibers = (); # clear
   LoadCaliberDB(); # load
   $caliber_entry->choices(\@calibers);
}

sub build_menubar
{
   my ($mw) = @_;
   my $menu_bar = $mw->Frame(-relief =>'groove', -borderwidth=>3)
                           ->pack(-side=>'top', -fill=>'x');

   # Left side
   my $file_mb = $menu_bar->Menubutton(-text=>'File')->pack(-side=>'left');
   $file_mb->command(-label=>'Choose Session...', -command => [\&ChooseSession, $mw]);
   $file_mb->command(-label=>'Generate HTML...', -command => [\&GenHTML, $mw]);
   $file_mb->command(-label=>'Generate Final HTML...', -command => [\&GenHTMLFinal, $mw]);
   $file_mb->command(-label=>'Export Data File...', -command => [\&ExportDataFile, $mw]);
   $file_mb->command(-label=>'Quit', -command => [\&Exit]);

   my $file_mb = $menu_bar->Menubutton(-text=>'Edit')->pack(-side=>'left');
   $file_mb->command(-label=>'Person...', -command => [\&EditPerson, $mw]);
   $file_mb->command(-label=>'Scores...', -command => [\&EditScores, $mw]);
   $file_mb->command(-label=>'Calibers...', -command => [\&EditCaliber, $mw]);

   my $date_mb = $menu_bar->Menubutton(-text=>'Date')->pack(-side=>'left');
   $date_mb->command(-label=>'Change Date...', -command => [\&ChangeDate, $mw]);

   my $date_mb = $menu_bar->Menubutton(-text=>'View')->pack(-side=>'left');
   $date_mb->command(-label=>'Scores...', -command => [\&ViewScores, $mw]);

   my $hrdate = Generate::ConvertDateHR($date);
   $mb_date = $menu_bar->Label(-text=>$hrdate)->pack(-side=>'right');
   $menu_bar->Label(-text=>'Score Date: ')->pack(-side=>'right');
}

my $shooter = "";
my $event = "";
my $division = "";
my $caliber = "";
my $score = "";

sub SaveScore
{
   my ($mw) = @_;

   $shooter =~ s/:/;/g;
   $caliber =~ s/:/;/g;
   $score =~ s/:/;/g;

   if ($score <= 0 || $score > 480) {
      DisplayError($mw, "Score is invalid: $score is not between 1 and 480\n");
      $score_entry->selection('range', 0, 128);
      $score_entry->focus();
      return;
   }

   if ($shooter eq "") {
      DisplayError($mw, "Shooter field is blank: please enter a shooter name\n");
      $shooters_entry->selection('range', 0, 128);
      $shooters_entry->focus();
      return;
   }

   if ($division eq "Prod") {
      if ($caliber eq ".22") {
         DisplayError($mw,
            ".22's are not allowed in $division\n");
         $caliber_entry->selection('range', 0, 128);
         $caliber_entry->focus();
         return;
      }
   }

   if ($caliber eq "") {
      if ($division ne "22") {
         DisplayError($mw,
            "Caliber field is blank and Division is not 22 : please enter a caliber\n");
         $caliber_entry->selection('range', 0, 128);
         $caliber_entry->focus();
         return;
      } else {
         $caliber = ".22";
      }
   }

   if ($division eq "22" and $caliber ne ".22") {
      DisplayError($mw,
         "$caliber is not allowed in $division\n");
      $caliber_entry->selection('range', 0, 128);
      $caliber_entry->focus();
      return;
   }

   AddShooterEntry($shooter);

   my ($fname, $lname) = SplitName($shooter);

   my $sth = MNSLQuery::query("select id from shooters where fname='$fname' and lname='$lname';");
   my @res = $sth->fetchrow_array;
   my $sid = $res[0];
   $sth = MNSLQuery::query("select id from event where name='$event';");
   my @res = $sth->fetchrow_array;
   my $eid = $res[0];
   $sth = MNSLQuery::query("select id from division where name='$division';");
   my @res = $sth->fetchrow_array;
   my $did = $res[0];

   $sth = MNSLQuery::query(
         "insert into scores (dte, leaguenum, score, shooterid, eid, did, cal)".
                 "values ('$date', $session, $score, $sid, $eid, $did, '$caliber');");

   AddCaliberEntry($caliber, \@calibers);

   printf("Score Saved:\n".
         "   $event, \"$shooter\", $division, $caliber, $score, $date, $session \n");

   $shooters_entry->selection('range', 0, 128);
   $shooter = "";
   $caliber = "";
   $score_entry->delete('0.0', 'end');
   $shooters_entry->focus();

}

my $statustext;
my $errortext;

sub ClearStatus
{
    $statustext->delete('1.0','end');
    $errortext->delete('1.0','end');
}

sub SetCaliberBasedOnDiv
{
   my ($div) = @_;
   if ($div eq "22") {
      $caliber = ".22";
   }
   if ($div eq "Prod" && $caliber eq ".22") {
      $caliber = "";
      $caliber_entry->selection('range', 0, 128);
   }
}

sub build_main_window
{
   LoadDBs();

   my $title = "MNSL Scores -- Session $session (Start Date: $session_st)";
   my $mw = new MainWindow(-title => $title);

   if (InvalidSession($session)) {
      if (!AddSession($mw, $session)) {
         die "ERROR: invalid session in config file\n";
      }
   }

   build_menubar($mw);
   my $frame = $mw->Frame->pack(-side=>'bottom', -fill=>'x');

   
   my $enter_frame = $frame->Frame->pack(-side=>'top', -fill=>'x');
   $enter_frame->Label(-text => "Event")->grid(
                     $enter_frame->Label(-text => "Shooter"),
                     $enter_frame->Label(-text => "Division"),
                     $enter_frame->Label(-text => "Caliber"),
                     $enter_frame->Label(-text => "Score"),
                      -sticky => "nsew");

   my $event = $enter_frame->Optionmenu(-options => \@events,
                                       -variable => \$event),
   $shooters_entry = $enter_frame->MatchEntry(-textvariable => \$shooter,
                                             -ignorecase => 'true',
                                             -choices => \@shooters);
   my $division = $enter_frame->Optionmenu(-options => \@divisions,
                                       -command=>\&SetCaliberBasedOnDiv,
                                       -variable => \$division),
   $caliber_entry = $enter_frame->MatchEntry(-textvariable => \$caliber,
                                             -ignorecase => 'true',
                                             -choices => \@calibers);
   $score_entry = $enter_frame->Entry(-textvariable => \$score);

   $event->grid(
               $shooters_entry,
               $division,
               $caliber_entry,
               $score_entry,
               $enter_frame->Button(-text => "Save",
                           -command => [\&SaveScore, $mw]),
                   -sticky => "nsew");

   $shooters_entry->selection('range', 0, 60);
   $shooters_entry->focus();

   my $status_frame = $frame->Frame->pack(-side=>'bottom', -fill=>'x');

   $statustext = $status_frame->Scrolled('ROText',
            -scrollbars => 'oe',
            -height      => 10,
             -background  => 'white',
             -foreground  => 'black',
             -width       => 100,
             -wrap        => 'word')->pack();
   tie *STDOUT, 'Tk::Text', $statustext;

   $errortext = $status_frame->Scrolled('ROText',
            -scrollbars => 'oe',
            -height      => 10,
             -background  => 'white',
             -foreground  => 'red',
             -width       => 100,
             -wrap        => 'word')->pack();
   tie *STDERR, 'Tk::Text', $errortext;

   $status_frame->Button(-text => "Clear Status",
                        -command => [\&ClearStatus])->pack();

   my $sw = $mw->screenwidth;
   my $sh = $mw->screenheight;
   $mw{left} = int(($sw - $mw{width})/8);
   $mw{top} = int(($sh - $mw{height})/8);
   $mw->geometry("+".$mw{left}."+".$mw{top});
   $mw->resizable(0,0);
}

# main
if (! -d $datadir) {
   mkdir $datadir;
}
ReadConfig();
# open DB connection
MNSLQuery::connect($dbuser, $dbpw, $db);

my $sth = MNSLQuery::query("select sdate from league ".
               "where lnum='$session';");
my @res = $sth->fetchrow_array;
$session_st = $res[0];

build_main_window;
MainLoop;

