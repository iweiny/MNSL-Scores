#!/usr/bin/perl

use Tk;
use Tk::MatchEntry;
use Tk::FileDialog;
use Tk::BrowseEntry;

$dname = "./data";
$shooter_db = "$dname/shooters_db";
$division_db = "$dname/division_db";

@shooters = ("");
@divisions = ("");

$shooters_entry = undef;

sub ChoseSeason
{
   my ($main) = @_;
   my $win = $main->FileDialog(-title => 'Chose ', -Create => 0);
   $win->configure(-SelDir => 1, -ShowAll => 'yes', -Path => $dname);
   $dname = $win->Show();
   return $dname;
}

sub GenPDF
{
}

sub Save
{
}

sub LoadShooters
{
   if (! -e $shooter_db) {
      open FILE, "+>$shooter_db" or die "Could not open shooter DB for creation\n";
   } else {
      open FILE, "<$shooter_db" or die "Could not open shooter DB; $shooter_db\n";
   }
   @shooters = <FILE>;
   close (FILE);
}

sub LoadDivisions
{
   if (! -e $division_db) {
      die "Division DB does not exist; please create\n";
   }

   open FILE, "<$division_db" or die "Could not open division DB; $division_db\n";
   @divisions = <FILE>;
   close (FILE);
}


sub AddShooter
{
   my ($new_shooter) = @_;

   # don't add a shooter already in the DB
   foreach $shooter (@shooters) {
      if ($shooter eq $new_shooter) {
         return;
      }
   }

   print ("Adding shooter: $new_shooter to @shooters\n");

   # add to the file on the fly
   open FILE, ">>$shooter_db" or die "Could not open shooter DB; $shooter_db\n";
   print FILE "$new_shooter\n";
   close (FILE);

   # and to the array on the fly
   push(@shooters, $new_shooter);

   $shooters_entry->choices(\@shooters);
}

sub Exit
{
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
}

my $name = "";
my $division = "";
my $caliber = "";
my $score = "";

sub SaveScore
{
   printf("Saving Score; $name $division $caliber $score\n");

   AddShooter($name);
}

sub build_main_window
{
   LoadShooters();
   LoadDivisions();

   my $mw = new MainWindow(-title => 'MNSL Scores');
   $mw->title("MNSL Scores");
   
   build_menubar($mw);
   
   my $main_frame = $mw->Frame->pack(-side=>'bottom', -fill=>'x');

   my $print_frame = $main_frame->Frame->pack(-side=>'top', -fill=>'x');

   $print_frame->Label(-text => "Shooter")->pack(-side=>'left');
   $shooters_entry = $print_frame->MatchEntry(-textvariable => \$name, -choices => \@shooters)
                                       ->pack(-side=>'left');

   $print_frame->Label(-text => "Division")->pack(-side=>'left');
   $print_frame->Optionmenu(-options => \@divisions, -variable => \$division)->pack(-side=>'left');
   $print_frame->Button(-text => "Enter", -command => [\&SaveScore, $name, $division, $caliber, $score])
                     ->pack(-side=>'left');
}


if (! -d $dname) {
   mkdir $dname
}

build_main_window;
MainLoop;

