#!/usr/bin/perl

use lib "DateTime-0.55/lib";
use lib "Params-Validate-0.95/lib";
use lib "DateTime-Locale-0.45/lib";
use lib "DateTime-TimeZone-1.15/lib";

use DateTime;

use Tk;
use Tk::MatchEntry;
use Tk::FileDialog;
use Tk::BrowseEntry;
use Tk::DateEntry;

$data_dir = "./data";
$db_dir = "$data_dir/db";
$shooter_db = "$db_dir/shooters_db";
$caliber_db = "$db_dir/caliber_db";
$division_db = "$db_dir/division_db";

$season = ();
$date = ();

@shooters = ("");
@divisions = ();
@calibers = ();

$shooters_entry = undef;
$caliber_entry = undef;
$mb_date = undef;
$mb_season = undef;

sub ChoseSeason
{
   my ($main) = @_;
   my $win = $main->FileDialog(-title => 'Chose ', -Create => 0);
   $win->configure(-SelDir => 1, -ShowAll => 'yes', -Path => $data_dir);
   $season = $win->Show();
   $mb_season->configure(-text=>"$season");
   return $season;
}

sub GenPDF
{
}

sub EnterDate
{
   my ($main) = @_;
   my $win = $main->DialogBox(-title => 'Invalid Print', -buttons => ['OK']);
   $win->Label(-text => "Enter Todays Date")->pack;
   $win->DateEntry(-textvariable =>\$date)->pack;
   $win->Show;
   $mb_date->configure(-text=>"$date");
}

sub LoadDB
{
   my ($db_file, $arr_ref) = @_;

   if (! -e $db_file) {
      open FILE, "+>$db_file" or die "Could not open DB \"$db_file\" for creation\n";
   } else {
      open FILE, "<$db_file" or die "Could not open DB; $db_file\n";
   }
   while (<FILE>) {
      chomp $_;
      push (@$arr_ref, $_);
   }
   close (FILE);
}

sub AddMatchEntry
{
   my ($entry_widget, $new_entry, $db_file, $arr_ref) = @_;

   # don't add an entry already in the DB
   foreach $i (@$arr_ref) {
      if ($i eq $new_entry) {
         return;
      }
   }

   print ("Adding $new_entry to @$arr_ref\n");

   # add to the file on the fly
   open FILE, ">>$db_file" or die "Could not open DB; $db_file\n";
   print FILE "$new_entry\n";
   close (FILE);

   # and to the array on the fly
   push(@$arr_ref, $new_entry);

   $entry_widget->choices($arr_ref);
}

sub build_menubar
{
   my ($mw) = @_;
   my $menu_bar = $mw->Frame(-relief =>'groove', -borderwidth=>3)->pack(-side=>'top', -fill=>'x');

   # File
   my $file_mb = $menu_bar->Menubutton(-text=>'File')->pack(-side=>'left');
   $file_mb->command(-label=>'Chose Season...', -command => [\&ChoseSeason, $mw]);
   $file_mb->command(-label=>'Generate PDF...', -command => [\&GenPDF, $mw]);
   $file_mb->command(-label=>'Quit', -command => sub{exit});
   my $date_mb = $menu_bar->Menubutton(-text=>'Date')->pack(-side=>'left');
   $date_mb->command(-label=>'Enter Date...', -command => [\&EnterDate, $mw]);
   $mb_date = $menu_bar->Label(-text=>$date)->pack(-side=>'right');
   $menu_bar->Label(-text=>'Day: ')->pack(-side=>'right');
   $mb_season = $menu_bar->Label(-text=>'<no season>')->pack(-side=>'right');
   $menu_bar->Label(-text=>'Season: ')->pack(-side=>'right');
}

my $shooter = "";
my $division = "";
my $caliber = "";
my $score = "";

sub SaveScore
{
   printf("Saving Score; $shooter $division $caliber $score\n");

   AddMatchEntry($shooters_entry, $shooter, $shooter_db, \@shooters);
   AddMatchEntry($caliber_entry, $caliber, $caliber_db, \@calibers);
   $shooters_entry->selection('range', 0, 60);
   $shooters_entry->focus();
}

sub build_main_window
{
   LoadDB($shooter_db, \@shooters);
   LoadDB($division_db, \@divisions);
   LoadDB($caliber_db, \@calibers);

   my $mw = new MainWindow(-title => 'MNSL Scores');
   $mw->title("MNSL Scores");
   
   build_menubar($mw);
   
   my $main_frame = $mw->Frame->pack(-side=>'bottom', -fill=>'x');

   my $print_frame = $main_frame->Frame->pack(-side=>'top', -fill=>'x');

   $print_frame->Label(-text => "Shooter")->pack(-side=>'left');
   $shooters_entry = $print_frame->MatchEntry(-textvariable => \$shooter, -choices => \@shooters)
                                       ->pack(-side=>'left');

   $print_frame->Label(-text => "Division")->pack(-side=>'left');
   $print_frame->Optionmenu(-options => \@divisions, -variable => \$division)->pack(-side=>'left');

   $print_frame->Label(-text => "Caliber")->pack(-side=>'left');
   $caliber_entry = $print_frame->MatchEntry(-textvariable => \$caliber, -choices => \@calibers)
                                       ->pack(-side=>'left');

   $print_frame->Label(-text => "Score")->pack(-side=>'left');
   $print_frame->Entry(-textvariable => \$score)->pack(-side=>'left');

   $print_frame->Button(-text => "Enter", -command => [\&SaveScore, $shooter, $division, $caliber, $score])
                     ->pack(-side=>'left');
}


if (! -d $data_dir) {
   mkdir $data_dir
}
if (! -d $db_dir) {
   mkdir $db_dir
}


# main
$dt = DateTime->now;
$mon = $dt->month;
$day = $dt->day;
$year = $dt->year;
$date = "$mon/$day/$year";
build_main_window;
MainLoop;

