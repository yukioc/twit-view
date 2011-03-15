#!/usr/bin/env perl

use strict;
use warnings;
use Encode qw/decode encode/;
use URI::Escape qw/uri_escape/;
use LWP::Simple qw/get/;
use Term::ANSIColor qw/colored/;
use JSON qw/decode_json/;
use Data::Dumper;
$Term::ANSIColor::AUTORESET=1;
$|=1; # STDOUT auto flush

sub usage{
    print <<"USAGE";
Usage: $0 [-s word] query

$0 is a simple twitter viewer.

Option:
 query         get the twitter about the query.
 -s word       emphasis the word.
 -h -? --help  this help

USAGE
exit;
}

sub version{
  print "twit-view v.0.2\n";
  exit;
}

my $q;
my @sword1;
my @sword2;
my %query=(rpp=>"60", result_type=>"recent");

#--- read arg and ini
while(@ARGV){
    my $argv=shift;
    if($argv eq '-s'){
        push(@sword1,decode('utf8',shift));
    }elsif($argv eq '-S'){
        push(@sword2,decode('utf8',shift));
    }elsif($argv=~/^(-h|-\?|--help)/){
        usage;
    }elsif($argv eq '--version'){
        version;
    }else{
        $q=$argv;
        last;
    }
}

#--- check param
die "error: not found query\n" if(!$q);

#--- twitter
sub get_twitter{
    my $q=shift;
    my %opt=%{$_[0]};
    my ($k,$v);
    my $url="http://search.twitter.com/search.json?q=".uri_escape($q);
    $url.="&$k=$v" while(($k,$v)=each(%opt));
    return decode_json(get($url));
}

#--- main
my $last_id='0';
my $wait=0;
while(1){
    my $r;
    my @tubuyaki;
    while(1){
        sleep($wait) if($wait>0);
        $r=get_twitter($q,\%query);
        $wait=30;
        last if($r->{results_per_page}>0 && $r->{max_id} ne $last_id);
        print ".";
    }
    print "\r";
    for my $status (@{$r->{results}}){
        my ($u,$s)=($status->{from_user},$status->{text});
        last if($status->{id} eq $last_id);
        push(@tubuyaki,[$u,$s]);
    }
    $last_id=$r->{max_id};
    while($#tubuyaki>0){
        my ($u,$t)=@{shift(@tubuyaki)};
        $u=colored($u,'blue');
        $t=~ s/(^|[^\w\-]+)(#[\w\-]+)/$1.colored($2,'green')/eg;
        $t=~ s/(@[\w\-]+)/colored($1,'cyan')/eg;
        $t=~ s/(http:[\x21-\x7e]+)/colored($1.' ','magenta')/eg;
        $t=~ s/($_)/colored($1,'yellow')/egi foreach(@sword1);
        $t=~ s/($_)/colored($1,'on_red')/egi foreach(@sword2);
        print "$u:".encode('utf8',"$t\n");
        sleep(1);
        $wait-- if($wait>0);
    }
}

