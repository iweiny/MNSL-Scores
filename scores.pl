#!/usr/bin/perl

use File::Basename;

use Tk;
use Tk::MatchEntry;
use Tk::FileDialog;
use Tk::BrowseEntry;
use Tk::DateEntry;

use Generate;
use MNSLQuery;

$data_dir = "./data";
$conf = "$data_dir/scores.conf";
$db_dir = "$data_dir";
#$season_db = "$db_dir/season_db";

$dbuser = "";
$dbpw = "";

$season = ();
#$season_path = ();
$date = ();

@shooters = ("");
@divisions = ();
@calibers = ();
@events = ();

$shooters_entry = undef;
$caliber_entry = undef;
$mb_date = undef;
$mb_season = undef;

sub SelectSeason
{
   my ($main) = @_;

#   # This whole function will have to change for a DB implementation.
#   my $win = $main->FileDialog(-title => 'Chose ', -Create => 0);
#   $win->configure(-Title => "Select Season Directory", -SelDir => 1, -ShowAll => 'yes',
#                  -Path => $data_dir);
#   my $choice = $win->Show();
#   my $suffix = ();
#   ($season, $season_path, $suffix) = fileparse($choice, qr/\.[^.]*/);
#   $mb_season->configure(-text=>"$season");
#   return $season;
}

sub CreateSeason
{
   my ($main) = @_;

#   # This whole function will have to change for a DB implementation.
#   my $win = $main->FileDialog(-title => 'Chose ', -Create => 0);
#   $win->configure(-Title => "Enter New Season Name", -SelDir => 1, -ShowAll => 'yes',
#                  -Path => $data_dir);
#   my $choice = $win->Show();
#   ($season, $season_path, $suffix) = fileparse($choice, qr/\.[^.]*/);
#   $mb_season->configure(-text=>"$season");
#   if (! -d $season_path/$season) {
#      mkdir $season_path/$season;
#   }
#   return $season;
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

# go through all days files and change the name.
sub changeName
{
   my ($old, $fname, $lname) = @_;

   my ($old_fname, $old_lname) = SplitName($old);

   my $sth = MNSLQuery::query(
               "select id,fname,lname from shooters where fname='$old_fname' and lname='$old_lname';");
   my @s = $sth->fetchrow_array;
   MNSLQuery::query("update shooters set fname='$fname',lname='$lname' where id='$s[0]';");
}

sub EditName
{
   my ($main) = @_;
   my $old_name = "";
   my $fname = "";
   my $lname = "";

   my $dialog = $main->DialogBox(-title => "Change Name", -buttons => ["OK","Cancel"]);
   $dialog->Label(-text => "Change:")->pack(-side=>'left');
   $dialog->MatchEntry(-textvariable => \$old_name, -choices => \@shooters)->pack(-side=>'left');
   $dialog->Label(-text => "to")->pack(-side=>'left');
   $dialog->Label(-text => "First")->pack(-side=>'left');
   $dialog->Entry(-textvariable => \$fname)->pack(-side=>'left');
   $dialog->Label(-text => "Last")->pack(-side=>'left');
   $dialog->Entry(-textvariable => \$lname)->pack(-side=>'left');

   my $choice = $dialog->Show();
   if ($choice eq "OK") {
      print "Changing $old_name to $fname $lname\n";
      changeName($old_name, $fname, $lname);
      LoadShooterDB();
      $shooters_entry->choices(\@shooters);
   }
}

sub EditScores
{
   my ($main) = @_;
   my $date = "";
   my $name = "";
   my $win = $main->DialogBox(-title => 'Choose Date/Name', -buttons => ["OK","Cancel"]);
   $win->DateEntry(-textvariable =>\$date, -dateformat=>4)->pack(-side=>'left');
   $win->MatchEntry(-textvariable => \$name, -choices => \@shooters)->pack(-side=>'left');
   my $choice = $win->Show();
   if ($choice eq "OK") {
      # read scores for that day and shooter

      # build dialog with those scores which can be editied.
      my $win = $main->DialogBox(-title => "Change scores for $name ($date)", -buttons => ["OK","Cancel"]);
      my $main_frame = $win->Frame->pack(-side=>'bottom', -fill=>'x');

      my $print_frame = $main_frame->Frame->pack(-side=>'top', -fill=>'x');
      $print_frame->Label(-text => "Event")->grid(
                     $print_frame->Label(-text => "Division"),
                     $print_frame->Label(-text => "Caliber"),
                     $print_frame->Label(-text => "Score"),
                      -sticky => "nsew");

      # arrays to hold the values for the options
      my @ev_ary = ();
      my @div_ary = ();
      my @cal_ary = ();
      my @score_ary = ();

      my $event;
      my $division;
      # foreach my $score (@scores) {
         $ev_ary[0] = "Tyro";
         $event = $print_frame->Optionmenu(-options => \@events,
                                       -variable => \$ev_ary[0]),
         $div_ary[0] = "Prod";
         $division = $print_frame->Optionmenu(-options => \@divisions,
                                       -variable => \$div_ary[0]),
         $cal_ary[0] = ".45";
         $caliber_entry = $print_frame->MatchEntry(-choices => \@calibers,
                                       -textvariable => \$cal_ary[0]);

         $score_ary[0] = "465";
         $event->grid(
                  $division,
                  $caliber_entry,
                  $print_frame->Entry(-textvariable => \$score_ary[0]),
                  -sticky => "nsew");

         $ev_ary[1] = "PPC";
         $event = $print_frame->Optionmenu(-options => \@events,
                                       -variable => \$ev_ary[1]),
         $div_ary[1] = "22";
         $division = $print_frame->Optionmenu(-options => \@divisions,
                                       -variable => \$div_ary[1]),
         $cal_ary[1] = ".22";
         $caliber_entry = $print_frame->MatchEntry(-choices => \@calibers,
                                       -textvariable => \$cal_ary[1]);

         $score_ary[1] = "470";
         $event->grid(
                  $division,
                  $caliber_entry,
                  $print_frame->Entry(-textvariable => \$score_ary[1]),
                  -sticky => "nsew");
      #}

      my $choice = $win->Show();
      if ($choice eq "OK") {
         print "Changing scores for $name on $date\n";
         print "$ev_ary[0]:$div_ary[0]:$cal_ary[0]:$score_ary[0]\n";
         print "$ev_ary[1]:$div_ary[1]:$cal_ary[1]:$score_ary[1]\n";
      }
   }
}

sub showGenComplete
{
   my ($type, $main) = @_;
   my $win = $main->DialogBox(-title => "Generate $type Complete", -buttons => ['OK']);
   $win->Label(-text => "Generate $type Complete\n")->pack;

   my $geom = $main->geometry;
   if ($geom =~ m/(\d+)x(\d+)\+(\d+)\+(\d+)/) {
      my $left = int (($1/2) + $3);
      my $top = int ($4);
      $win->geometry("+$left+$top");
   }
   $win->Show;
}

# Leave this for another day
#sub GenPDF
#{
#   my ($main) = @_;
#   Generate::PDF($season, $season_path);
#   showGenComplete("pdf", $main);
#}

sub GenHTML
{
   my ($main) = @_;
   Generate::HTML($season, $season_path);
   showGenComplete("html", $main);
}

sub GenDataTar
{
   my ($main) = @_;
   Generate::DataTar($season, $season_path);
   showGenComplete("Data Tarball", $main);
}

sub WriteSeasonConfig
{
   open FILE, "+>$season_db" or die "Could not open config \"$season_db\"\n";
   print FILE "$season\n";
   print FILE "$season_path\n";
   close (FILE);
}

sub Exit
{
   WriteSeasonConfig();
   exit;
}


sub ChangeDate
{
   my ($main) = @_;
   my $win = $main->DialogBox(-title => 'Change Date', -buttons => ['OK']);
   $win->Label(-text => "Change Date")->pack;
   $win->DateEntry(-textvariable =>\$date, -dateformat=>4)->pack;
   $win->Show;
   $mb_date->configure(-text=>"$date");
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
}

sub AddShooterEntry
{
   my ($entry_widget, $new_shooter, $arr_ref) = @_;

   # don't add an entry already in the DB
   foreach $i (@$arr_ref) {
      if ($i eq $new_shooter) {
         return;
      }
   }

   my ($fname, $lname) = SplitName($new_shooter);
   MNSLQuery::query("insert into shooters (fname,lname) values ('$fname', '$lname')");

   # and to the array on the fly
   push(@$arr_ref, "$fname $lname");
   $entry_widget->choices($arr_ref);
}

sub AddCaliberEntry
{
   my ($caliber_entry, $caliber, $arr_ref) = @_;

   # don't add an entry already in the DB
   foreach $i (@$arr_ref) {
      if ($i eq $caliber) {
         return;
      }
   }

   MNSLQuery::query("insert into caliber (name) values ('$caliber')");

   # and to the array on the fly
   push(@$arr_ref, $caliber);
   $caliber_entry->choices($arr_ref);
}

sub build_menubar
{
   my ($mw) = @_;
   my $menu_bar = $mw->Frame(-relief =>'groove', -borderwidth=>3)
                           ->pack(-side=>'top', -fill=>'x');

   # File
   my $file_mb = $menu_bar->Menubutton(-text=>'File')->pack(-side=>'left');
   $file_mb->command(-label=>'Select Season...', -command => [\&SelectSeason, $mw]);
   $file_mb->command(-label=>'Create Season...', -command => [\&CreateSeason, $mw]);
   $file_mb->command(-label=>'Quit', -command => [\&Exit]);

   my $file_mb = $menu_bar->Menubutton(-text=>'Edit')->pack(-side=>'left');
   $file_mb->command(-label=>'Name...', -command => [\&EditName, $mw]);
   $file_mb->command(-label=>'Scores...', -command => [\&EditScores, $mw]);

   my $gen_mb = $menu_bar->Menubutton(-text=>'Generate')->pack(-side=>'left');
   #$gen_mb->command(-label=>'PDF...', -command => [\&GenPDF, $mw]);
   $gen_mb->command(-label=>'HTML...', -command => [\&GenHTML, $mw]);
   $gen_mb->command(-label=>'Data Tarball...', -command => [\&GenDataTar, $mw]);

   my $date_mb = $menu_bar->Menubutton(-text=>'Date')->pack(-side=>'left');
   $date_mb->command(-label=>'Change Date...', -command => [\&ChangeDate, $mw]);
   $mb_date = $menu_bar->Label(-text=>$date)->pack(-side=>'right');
   $menu_bar->Label(-text=>'Day: ')->pack(-side=>'right');
   $mb_season = $menu_bar->Label(-text=>$season)->pack(-side=>'right');
   $menu_bar->Label(-text=>'Season: ')->pack(-side=>'right');
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

   printf("Saving Score; $shooter $event $division $caliber $score => $date\n");

   open FILE, ">>$season_path/$season/$date" or die "Could not open DB; $season_path/$season/$date\n";
   print FILE "$shooter:$event:$division:$caliber:$score\n";
   close (FILE);

   AddShooterEntry($shooters_entry, $shooter, \@shooters);
   AddCaliberEntry($caliber_entry, $caliber, \@calibers);
   $shooters_entry->selection('range', 0, 60);
   $shooters_entry->focus();
}

sub build_main_window
{
   LoadDBs();

   my $mw = new MainWindow(-title => 'MNSL Scores');
   $mw->title("MNSL Scores");

   build_menubar($mw);
   
   my $main_frame = $mw->Frame->pack(-side=>'bottom', -fill=>'x');

   my $print_frame = $main_frame->Frame->pack(-side=>'top', -fill=>'x');
   $print_frame->Label(-text => "Shooter")->grid(
                     $print_frame->Label(-text => "Event"),
                     $print_frame->Label(-text => "Division"),
                     $print_frame->Label(-text => "Caliber"),
                     $print_frame->Label(-text => "Score"),
                      -sticky => "nsew");


   $shooters_entry = $print_frame->MatchEntry(-textvariable => \$shooter,
                                             -choices => \@shooters);
   my $event = $print_frame->Optionmenu(-options => \@events,
                                       -variable => \$event),
   my $division = $print_frame->Optionmenu(-options => \@divisions,
                                       -variable => \$division),
   $caliber_entry = $print_frame->MatchEntry(-textvariable => \$caliber,
                                             -choices => \@calibers);

   $shooters_entry->grid(
               $event,
               $division,
               $caliber_entry,
               $print_frame->Entry(-textvariable => \$score),
               $print_frame->Button(-text => "Save",
                           -command => [\&SaveScore, $shooter, $event, $division,
                                                      $caliber, $score]),
                   -sticky => "nsew");

   my $sw = $mw->screenwidth;
   my $sh = $mw->screenheight;
   $mw{left} = int(($sw - $mw{width})/8);
   $mw{top} = int(($sh - $mw{height})/8);
   $mw->geometry("+".$mw{left}."+".$mw{top});
   $mw->resizable(0,0);
}


if (! -d $data_dir) {
   mkdir $data_dir
}
if (! -d $db_dir) {
   mkdir $db_dir
}


# main
# open DB connection
open FILE, "<$conf" or die "Could not open config \"$conf\"\n";
while (<FILE>) {
   chomp $_;
   my ($var, $value) = split /:/, $_;
   if ("$var" eq "db_user") {
      $dbuser = $value;
   }
   if ("$var" eq "db_pw") {
      $dbpw = $value;
   }
   if ("$season" eq "Season") {
      $dbpw = $value;
   }
}
close (FILE);
MNSLQuery::connect($dbuser, $dbpw);


# Get todays date as a default
my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek,
   $dayOfYear, $daylightSavings) = localtime();
my $year = 1900 + $yearOffset;
my $month = 1 + $month;
$date = sprintf("%04d-%02d-%02d", $year, $month, $dayOfMonth);

# Open last season used
if (-e $season_db) {
   open FILE, "<$season_db" or die "Could not open config \"$season_db\"\n";
   $season = <FILE>;
   chomp $season;
   $season_path = <FILE>;
   chomp $season_path;
   close(FILE);
}

build_main_window;
MainLoop;

