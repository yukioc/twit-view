#!/usr/bin/env perl

use strict;
use warnings;
use Net::Twitter::Lite;
use Data::Dumper;
use Encode;
use Term::ANSIColor;
$Term::ANSIColor::AUTORESET=1;

sub usage{
    my $s=<<"USAGE";
Usage: $0 [-s word] query

$0 is a simple twitter viewer.

Option:
 query         get the twitter about the query.
 -s word       emphasis the word.
 -h -? --help  this help

USAGE
print $s;
exit;
}

my $inifile='twit-view.ini';
my $q;
my @sword1;
my @sword2;

#--- read arg and ini
while(@ARGV){
    my $argv=shift;
    if($argv eq '-s'){
        push(@sword1,decode('utf8',shift));
    }elsif($argv eq '-S'){
        push(@sword2,decode('utf8',shift));
    }elsif($argv=~/^(-h|-\?|--help)/){
        usage;
    }else{
        $q=$argv;
        last;
    }
}
my %ini;
open my $fi,"<",$inifile or die "error:$!";
while(<$fi>){
  $ini{$1}=$2 if(/\s*(\w+)\s*=(\S+)/);
}
close $fi;

#--- check param;
my $consumer_key = $ini{consumer_key_secret} or die "error: not found consumer_key_secret";
my $consumer_key_secret = $ini{consumer_key_secret} or die "error: not found consumer_key_secret";
my $access_token = $ini{access_token} or die "error: not found access_token";
my $access_token_secret = $ini{access_token_secret} or die "error: not found access_token_secret";
die "error: not found query\n" if(!$q);

#--- main
my $nt = Net::Twitter::Lite->new(
  consumer_key    => $consumer_key,
  consumer_secret => $consumer_key_secret,
);
$nt->access_token($access_token);
$nt->access_token_secret($access_token_secret);

$|=1; # STDOUT auto flush
my $last_id='0';
while(1){
    my $r;
    my @tubuyaki;
    while(1){
        $r=$nt->search({q=>$q,since_id=>"0"});
        last if($r->{results_per_page}>0 && $r->{max_id} ne $last_id);
        print ".";
        sleep(10);
    }
    print "\r";
    for my $status (@{$r->{results}}){
        my $u=$status->{from_user};
        my $s=$status->{text};
        last if($status->{id} eq $last_id);
        push(@tubuyaki,[$u,$s]);
    }
    $last_id=$r->{max_id};
    while($#tubuyaki>0){
        my ($u,$t)=@{shift(@tubuyaki)};
        $u=colored($u,'blue');
        $t=~ s/(#[0-9A-Za-z-_]+)/colored(' '.$1,'green')/eg;
        $t=~ s/(@[A-Za-z-_]+)/colored($1,'cyan')/eg;
        $t=~ s/(http:[\x21-\x7e]+)/colored($1." ",'magenta')/eg;
        $t=~ s/($_)/colored($1,'yellow')/egi foreach(@sword1);
        $t=~ s/($_)/colored($1,'on_red')/egi foreach(@sword2);
        print "$u:".encode('utf8',"$t\n");
        sleep(1);
    }
}

