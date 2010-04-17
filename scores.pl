#!/usr/bin/perl

use File::Basename;
use Cwd 'abs_path';

use Tk;
use Tk::MatchEntry;
use Tk::FileDialog;
use Tk::BrowseEntry;
use Tk::DateEntry;


use Generate;
use MNSLQuery;


# configuration vars
$dbuser = "";
$dbpw = "";
$db = "";
$session = ();
$session_st = ();
$date = ();
$basedir = dirname(abs_path($0));
$conf = "$basedir/scores.conf";
$datadir = "$basedir/data";

# Vars for UI
@shooters = ("");
$shooters_entry = undef;
@divisions = ();
@calibers = ();
$caliber_entry = undef;
@events = ();
# In the MenuBar
$mb_date = undef;
$mb_session = undef;

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
         if (!AddSession($main, $s)) {
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
      return ($fname, $lname);
   }
   die "Failed to split $name\n";
}

sub UpdateShooter
{
   my ($old, $fname, $lname, $email, $phone, $addr, $city, $st, $zip) = @_;

   my ($old_fname, $old_lname) = SplitName($old);

   my $sth = MNSLQuery::query(
            "select id,fname,lname from shooters where fname='$old_fname' and lname='$old_lname';");
   my @s = $sth->fetchrow_array;
   MNSLQuery::query("update shooters set fname='$fname',lname='$lname',email='$email',".
                  "phone='$phone',address='$addr',city='$city',state='$st',zip='$zip' ".
                  "where id='$s[0]';");
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

   my $dialog = $main->DialogBox(-title => "Change Name", -buttons => ["OK","Cancel"]);
   my $topframe = $dialog->Frame()->pack(-side=>'top');
   $topframe->Label(-text => "Change:")->pack(-side=>'left');
   $topframe->MatchEntry(-textvariable => \$old_name, -choices => \@shooters)->pack(-side=>'left');
   my $choice = $dialog->Show();

   if ($choice eq "OK") {

      while (1) {
         my @shooter = GetShooter($old_name);
         if (scalar @shooter < 1) {
            my $win = $main->DialogBox(-title => 'ERROR: Shooter not found', -buttons => ["Yes","Cancel"]);
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
   
         my $dialog = $main->DialogBox(-title => "Enter New Shooter Info", -buttons => ["OK","Cancel"]);
         my $midframe = $dialog->Frame()->pack(-side=>'bottom');
         
         $midframe->Label(-text => "First")->grid(
               $midframe->Entry(-textvariable => \$fname));
         $midframe->Label(-text => "Last")->grid(
               $midframe->Entry(-textvariable => \$lname));
         $midframe->Label(-text => "email")->grid(
               $midframe->Entry(-textvariable => \$email));
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
            UpdateShooter($old_name, $fname, $lname, $email, $phone, $addr, $city, $st, $zip);
            UpdateShooterList();
            return;
         } else {
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
                     "and sh.fname='$fname' and sh.lname='$lname' and dte='$date';");
   my @rc;
   while (my @res = $sth->fetchrow_array) {
      push (@rc, \@res);
   }
   return (@rc);
}

sub UpdateScore
{
   my ($id, $event, $div, $cal, $score) = @_;
   my $sth = MNSLQuery::query("select id from event where name='$event';");
   my @res = $sth->fetchrow_array;
   my $eid = $res[0];

   $sth = MNSLQuery::query("select id from division where name='$div';");
   @res = $sth->fetchrow_array;
   my $did = $res[0];

   $sth = MNSLQuery::query("update scores set eid=$eid,did=$did,cal='$cal',score='$score' ".
                           "where id='$id';");
}

sub EditScores
{
   my ($main) = @_;
   my $date = "";
   my $name = "";
   my $win = $main->DialogBox(-title => 'Choose Name and Date to change', -buttons => ["OK","Cancel"]);
   $win->MatchEntry(-textvariable => \$name, -choices => \@shooters)->pack(-side=>'left');
   $win->DateEntry(-textvariable =>\$date, -dateformat=>4)->pack(-side=>'left');
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

      # build dialog with those scores which can be editied.
      my $win = $main->DialogBox(-title => "Change scores for $name ($date)", -buttons => ["OK","Cancel"]);
      my $main_frame = $win->Frame->pack(-side=>'bottom', -fill=>'x');

      my $print_frame = $main_frame->Frame->pack(-side=>'top', -fill=>'x');
      $print_frame->Label(-text => "Event")->grid(
                     $print_frame->Label(-text => "Division"),
                     $print_frame->Label(-text => "Caliber"),
                     $print_frame->Label(-text => "Score"),
                      -sticky => "nsew");

      foreach my $score (@scores) {
         # score[0] is the id of the row we would change
         my $event = $print_frame->Optionmenu(-options => \@events,
                                       -variable => \$score->[1]),
         my $division = $print_frame->Optionmenu(-options => \@divisions,
                                       -variable => \$score->[2]),
         $caliber_entry = $print_frame->MatchEntry(-choices => \@calibers,
                                       -textvariable => \$score->[3]);

         $event->grid(
                  $division,
                  $caliber_entry,
                  $print_frame->Entry(-textvariable => \$score->[4]),
                  -sticky => "nsew");

      }

      my $choice = $win->Show();
      if ($choice eq "OK") {
         print "Changing scores for $name on $date\n";
         foreach my $score (@scores) {
            print "Updating scores:\n";
            print "$score->[0], $score->[1], $score->[2], $score->[3], $score->[4]\n";
            UpdateScore($score->[0], $score->[1], $score->[2], $score->[3], $score->[4]);
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

   Generate::HTML($file, $session, $sdate);

   my $win = $main->DialogBox(-title => "Generate HTML Complete",
                  -buttons => ['OK', 'View in Firefox']);
   $win->Label(-text => "Written to: $file\n")->pack;
   my $choice = $win->Show;
   if ($choice eq 'View in Firefox') {
      system("firefox $file&");
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
      my ($var, $value) = split /:/, $_;
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
   print FILE "db_user: $dbuser\n";
   print FILE "db_pw:   $dbpw\n";
   print FILE "db:      $db\n";
   print FILE "session: $session\n";
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
}

sub LoadShooterDB
{
   my $sth = MNSLQuery::query("select fname,lname from shooters;");
   while (my @s = $sth->fetchrow_array) {
      push (@shooters, "$s[0] $s[1]");
   }
}

sub LoadDBs
{
   LoadShooterDB();

   $sth = MNSLQuery::query("select name from event;");
   while (my @s = $sth->fetchrow_array) {
      push (@events, @s);
   }

   $sth = MNSLQuery::query("select name from division;");
   while (my @s = $sth->fetchrow_array) {
      push (@divisions, @s);
   }

   $sth = MNSLQuery::query("select name from caliber;");
   while (my @s = $sth->fetchrow_array) {
      push (@calibers, @s);
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
   my $sth = MNSLQuery::query("select id,fname,lname,email,phone,address,city,state,zip ".
                              "from shooters where fname='$fname' and lname='$lname';");
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
   $file_mb->command(-label=>'Export Data File...', -command => [\&ExportDataFile, $mw]);
   $file_mb->command(-label=>'Quit', -command => [\&Exit]);

   my $file_mb = $menu_bar->Menubutton(-text=>'Edit')->pack(-side=>'left');
   $file_mb->command(-label=>'Person...', -command => [\&EditPerson, $mw]);
   $file_mb->command(-label=>'Scores...', -command => [\&EditScores, $mw]);

   my $date_mb = $menu_bar->Menubutton(-text=>'Date')->pack(-side=>'left');
   $date_mb->command(-label=>'Change Date...', -command => [\&ChangeDate, $mw]);

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
   $shooter =~ s/:/;/g;
   $caliber =~ s/:/;/g;
   $score =~ s/:/;/g;

   printf("Saving Score; $session $date $shooter $event $division $caliber $score\n");

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

   AddShooterEntry($shooter);
   AddCaliberEntry($caliber, \@calibers);
   $shooters_entry->selection('range', 0, 60);
   $shooters_entry->focus();
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
   
   my $print_frame = $mw->Frame->pack(-side=>'bottom', -fill=>'x');
   $print_frame->Label(-text => "Event")->grid(
                     $print_frame->Label(-text => "Shooter"),
                     $print_frame->Label(-text => "Division"),
                     $print_frame->Label(-text => "Caliber"),
                     $print_frame->Label(-text => "Score"),
                      -sticky => "nsew");

   my $event = $print_frame->Optionmenu(-options => \@events,
                                       -variable => \$event),
   $shooters_entry = $print_frame->MatchEntry(-textvariable => \$shooter,
                                             -choices => \@shooters);
   my $division = $print_frame->Optionmenu(-options => \@divisions,
                                       -variable => \$division),
   $caliber_entry = $print_frame->MatchEntry(-textvariable => \$caliber,
                                             -choices => \@calibers);

   $event->grid(
               $shooters_entry,
               $division,
               $caliber_entry,
               $print_frame->Entry(-textvariable => \$score),
               $print_frame->Button(-text => "Save",
                           -command => [\&SaveScore, $shooter, $event, $division,
                                                      $caliber, $score]),
                   -sticky => "nsew");

   $shooters_entry->selection('range', 0, 60);
   $shooters_entry->focus();

   my $sw = $mw->screenwidth;
   my $sh = $mw->screenheight;
   $mw{left} = int(($sw - $mw{width})/8);
   $mw{top} = int(($sh - $mw{height})/8);
   $mw->geometry("+".$mw{left}."+".$mw{top});
   $mw->resizable(1,0);
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

