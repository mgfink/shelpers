#!/usr/bin/perl

# Standard stuff to ensure somewhat coherent PERL
use warnings;
use strict;


# Import this so we can explore complex variables
use Data::Dumper;

# Import this so we can parse cmdline input
use Getopt::Long;

my $help = undef;
my $reset = undef;
my $config = undef;

# Parse cmdline input
GetOptions  ('help' => \$help,
            'reset' => \$reset, 
            'config=s' => \$config
            );

if ($help)
{
    print "$0 \[options\]\n";
    print "--help\t\t\tThis help text\n";
    print "--reset\t\t\tResets the HBA and attempts to disconnect from all sessions\n";
    print "--config=<config file>\tAttempt to configure based on supplied info\n";
    #TODO: read config and save to file
    exit(255);
}

# Predefine hbacmd and related functions
my $hbacmd = "/usr/sbin/hbacmd";
my $listiscsihbas = "listhbas pt=iscsi";
my $showtarget = "showtarget";
my $listsessions = "listsessions";
my $getiscsiluns = "getiscsiluns";
my $targetlogout = "targetlogout";
my $removetarget = "removetarget";

# Global variables 
my %Emulex; # Contains the entire data structure of the adapter
my @macs = (); # MAC addresses of the iSCSI HBAs

# Pull the iSCSI MAC addresses
my @output = `$hbacmd $listiscsihbas`;
foreach my $line (@output) {
  if($line =~ /Current MAC\s+:\s(\S+)/i) {
	push @macs, $1;
	}
}

# TODO: Better organize the code
# Add getopts for input parsing
# Add feature to clear iSCSI config
# Add feature to import .cfg file to set up mappings
# Add feature to selectively print info

# Grab the iSCSI target info and put in %Emulex
showTargets();

# Grab the iSCSI sessions and put in %Emulex
listSessions();

# Grab the mapped LUNs and put in %Emulex
getISCSILuns();

if ($reset)
{
    print "We're going to reset the config!!!\n";
    print "You have 3 seconds to ctrl+c and change your mind...\n";
    #sleep(3);
    resetiSCSI();
}


# Have a look!
print Dumper(\%Emulex);

# sub: showTargets
# input: none
# output: none
# Reads global var to determine iSCSI MACs and then pick off the target info
#  stuffing that into the %Emulex hash
sub showTargets
{
	foreach my $mac (@macs)
	{
		my @output = `$hbacmd $showtarget $mac`;
		my $iqn;
		foreach my $line (@output)
		{	
			if($line =~ /Target iSCSI Name:\s+(\S+)/i) {
				$iqn = $1;
			}
			if($line =~ /Target Portal\s{2,}(\S+)/i) {
				my $portal = $1;
				#print "portal: $portal\n";
				my $rec = {};
				$rec->{ADDRESS} = $portal;
				push @{ $Emulex{$mac}{$iqn}{TARGETS}}, $rec;
			}
			if($line =~ /^Sessions:\s*(\S+)/i) {
				my $sessions = $1;				
				$Emulex{$mac}{$iqn}{SESSIONS} = $sessions;
			}
			if($line =~ /^Connected Sessions:\s*(\S+)/i) {
				my $connected = $1;				
				$Emulex{$mac}{$iqn}{CONNECTED} = $connected;			
			}
        }
	}	
}

# sub: listSessions
# input: none
# output: none
# Reads global var to determine iSCSI MACs and then pick off the session info
#  stuffing that into the %Emulex hash
sub listSessions
{
    foreach my $mac (sort keys %Emulex) {
        foreach my $iqn (sort keys %{ $Emulex{$mac} } ) {
            my @output = `$hbacmd $listsessions $mac $iqn`;
            my $get_next = iterator(\@output);
            while (my $line = $get_next->()) {
                #TODO: Dynamically pull hash keys and just grab them all!
                if($line =~ /Initiator Name:\s+(\S+)/) {
                    my $rec = {};
                    $rec->{IQN} = $1;
                
                    $line = $get_next->();
                    if($line =~ /Status:\s+(\S+)/) {
                        $rec->{STATUS} = $1;
                    }                

                    $line = $get_next->();
                    if($line =~ /TSIH:\s+(\S+)/) {
                        $rec->{TSIH} = $1;
                    }   

                    $line = $get_next->();
                    if($line =~ /ISID:\s+(\S+)/) {
                        $rec->{ISID} = $1;
                    }   

                    $line = $get_next->();
                    if($line =~ /ISID Qualifier:\s+(\S+)/) {
                        $rec->{ISIDQUALIFIER} = $1;
                    }   

                    $line = $get_next->();
                    if($line =~ /Target IP Address:\s+(\S+)/) {
                        $rec->{TARGET} = $1;
                    }                
                    
                    $line = $get_next->();
                    if($line =~ /iSCSI Boot:\s+(\S+)/) {
                        $rec->{ISCSIBOOT} = $1;
                    }      
                    push @{ $Emulex{$mac}{$iqn}{SESSIONLIST}}, $rec;                    
                }
            }
        }
    }	
}

# sub: getISCSILuns
# input: none
# output: none
# Reads global var to determine iSCSI MACs and then pick off iSCSI LUN info
#  stuffing that into the %Emulex hash
sub getISCSILuns
{
    foreach my $mac (sort keys %Emulex) {
        foreach my $iqn (sort keys %{ $Emulex{$mac} } ) {
            my @output = `$hbacmd $getiscsiluns $mac $iqn`;
            my $get_next = iterator(\@output);
            while (my $line = $get_next->()) {
                #TODO: Dynamically pull hash keys and just grab them all!
                if($line =~ /Vendor Name:\s+(\S+)/) {
                    my $rec = {};
                    $rec->{VENDOR} = $1;
                
                    $line = $get_next->();
                    if($line =~ /Model Number:\s+(\S+)/) {
                        $rec->{MODEL} = $1;
                    }                

                    $line = $get_next->();
                    if($line =~ /Serial Number:\s+(\S+)/) {
                        $rec->{SERIAL} = $1;
                    }   

                    # Eat a line for  info we don't care about
                    $line = $get_next->();

                    $line = $get_next->();
                    if($line =~ /Capacity:\s+(\S+)/) {
                        $rec->{CAPACITY} = $1;
                    }                
                    
                    $line = $get_next->();
                    if($line =~ /Block Size:\s+(\S+)/) {
                        $rec->{BLOCKSIZE} = $1;
                    }      
                    push @{ $Emulex{$mac}{$iqn}{ISCSILUNS}}, $rec;                    
                }
            }
        }
    }	
}

sub resetiSCSI {
        foreach my $mac (sort keys %Emulex) {
            foreach my $iqn (sort keys %{ $Emulex{$mac} } ) {
                foreach my $rec (@{ $Emulex{$mac}{$iqn}{SESSIONLIST}}) {
                    my $cmd = "$hbacmd $targetlogout $mac $iqn $rec->{ISIDQUALIFIER} $rec->{TARGET}";
                    print "CMD: $cmd\n";
                }                   
                
                my $cmd = "$hbacmd $removetarget $mac $iqn";   
                print "CMD: $cmd\n";
            }
        }
}

# sub: iterator
# input: array reference
# output: string that represents the 'next' line in the array or nothing
# Reads global var to determine iSCSI MACs and then pick off iSCSI LUN info
#  stuffing that into the %Emulex hash 
# TODO: use iterator more globally
sub iterator {
    my $list = shift;
    my $i = 0;
    return sub {
        return if $i > $#$list;
        return $list->[$i++];
    }
}
