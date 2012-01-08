#!/usr/bin/perl

use POSIX;
use IO::Socket;
use strict;
use warnings;

my $plugin;
my @plugins;
my $plugin_data;
my @plugin_data_split;
my @plugin_return_lines;
my $plugin_return_line;
my $plugin_directory="/usr/local/carbon_client/plugins";
my $plugin_directory_states="/usr/local/carbon_client/plugins/execution_states";
my $plugin_frequency;
my $plugin_frequency_state;
my $time;
my $data = "";
my $conf_search_path=".:/usr/local/carbon_client";
my $conf_filename="carbon_server.conf";
my @carbon_server;
my $conf_input;

foreach my $check_path(split(':',$conf_search_path)) {
    if (-e $check_path . '/' . $conf_filename) {
        open(FIN, $check_path . '/' . $conf_filename);
        $conf_input = <FIN>;
        chomp($conf_input);
        if ($conf_input =~ /^([a-zA-Z0-9\.]+):([0-9]+)$/)
        {
            $carbon_server[0] = $1;
            $carbon_server[1] = $2;
        } else {
            next;
        }
    }
}

if ($#carbon_server != 1) {
    die "can't find or parse config file\n"
}

if (!-d $plugin_directory)
{
    die "plugin directory is not an existing directory\n";
}
if (!-d $plugin_directory_states)
{
    die "plugin states directory doesn't exist\n";
}

opendir(PLUGIN_DIR, $plugin_directory);
@plugins = readdir(PLUGIN_DIR);
close (PLUGIN_DIR);

$/ = "";
foreach $plugin(@plugins)
{
    if (($plugin eq ".") or ($plugin eq ".."))
    {
        next;
    }
    if (!-x $plugin_directory . "/" . $plugin)
    {
        next;
    }
    ($plugin_frequency) = split(/_/, $plugin);
    if (!isdigit($plugin_frequency))
    {
        next;
    }

    if (-e $plugin_directory_states . "/" . $plugin . ".state")
    {
        open(FIN, $plugin_directory_states . "/" . $plugin . ".state");
        $plugin_frequency_state = <FIN>;
        chomp($plugin_frequency_state);
        close(FIN);
    }
    else
    {
        $plugin_frequency_state = 1;
    }

    open(FOUT, ">" . $plugin_directory_states . "/" . $plugin . ".state") or die "could not write frequency_state: $!\n";
    if ($plugin_frequency_state < $plugin_frequency)
    {
        $plugin_frequency_state++;
        print FOUT $plugin_frequency_state;
        close(FOUT);
        next;
    }
    else
    {
        print FOUT "1";
        close(FOUT);
    }

    $time = time();
    $plugin_data = `$plugin_directory/$plugin`;
    @plugin_return_lines = split(/\n/, $plugin_data);
    foreach $plugin_return_line(@plugin_return_lines)
    {
        chomp($plugin_return_line);
        @plugin_data_split = split(/\ /, $plugin_return_line);
        if ($#plugin_data_split != 1)
        {
            next;
        }
        
        if ($plugin_data_split[1] !~ /^[\.0-9]+$/)
        {
            next;
        }
        if ($plugin_data_split[0] !~ /^[\.\-0-9a-zA-Z]+$/)
        {
            next;
        }
        $data .= $plugin_data_split[0] . " " . $plugin_data_split[1] . " " . $time . "\n";
    }
}

my $sock = IO::Socket::INET->new(Proto => "tcp", PeerAddr => $carbon_server[0], PeerPort => $carbon_server[1], Timeout  => 10) or die "could not connect to carbon server";
print $sock $data or die "could not write to socket";
close ($sock);
