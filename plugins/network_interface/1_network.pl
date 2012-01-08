#!/usr/bin/perl

use strict;
use warnings;
use Sys::Hostname;

sub trim
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

my $proc_net_dev="/proc/net/dev";
my $line;
my @split;
my @split2;
my $element;
my $element2;
my $if;
my @top_title;
my @sub_title;
my $phase = 1;
my $metric;
my $metric_prefix = "system." . hostname() . ".net";

open(FIN, $proc_net_dev) or die "could not read from $proc_net_dev: $!\n";
while ($line = <FIN>)
{
    if ($phase == 1){
        @split = split(/\|/, $line);
        for ($element = 1; $element <= $#split; $element++)
        {
            chomp($split[$element]);
            $split[$element] = trim($split[$element]);
            push(@top_title, $split[$element]);
        }
        $phase++;
    } elsif ($phase == 2) {
        @split = split(/\|/, $line);
        for ($element = 1; $element <= $#split; $element++)
        {
            @split2 = split(/[[:space:]]+/, $split[$element]);
            $sub_title[$element - 1] = [];
            for ($element2 = 0; $element2 <= $#split2; $element2++)
            {
                chomp($split2[$element2]);
                $split2[$element2] = trim($split2[$element2]);
                if ($split2[$element2] ne '')
                {
                    push(@{$sub_title[$element - 1]}, $split2[$element2]);
                }
            }
        }
        $phase++;
    } elsif ($phase == 3) {
	$line = trim($line);
	@split = split(/\:/, $line);
	$if = $split[0];
	$if = trim($if);
	$line = $split[1];
        @split = split(/[[:space:]]+/, $line);
        #print "---line\n\n\n";
        for ($element = 0; $element < $#split; $element++)
        {
            chomp($split[$element]);
            $split[$element] = trim($split[$element]);
            if ($split[$element] ne '')
            {
                if ($element < scalar(@{$sub_title[1]}))
                {
                    $metric = $top_title[0] . "." . $sub_title[0][$element];
                }
                else
                {
                    $metric = $top_title[1] . "." . $sub_title[1][$element - scalar(@{$sub_title[0]})];
                }
                print $metric_prefix . "." . $if . "." . $metric . " " . $split[$element] . "\n";
            }
        }
    }
}
close(FIN);
