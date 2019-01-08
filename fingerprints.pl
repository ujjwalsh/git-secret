#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long; 
use File::Basename;
use Data::Dumper qw(Dumper);

my $prog = basename($0);
my $verbose = 0;
my $stdin = 0;
my $homedir = "";
my $user = "";
#my $dryrun;


# Usage() : returns usage information
sub Usage {
    "$prog [--verbose] [--stdin] [--homedir=/home/user/.gpg] [--user=email]\n";
}

# call main()
main();

# main()
sub main {
    GetOptions(
        "verbose!" => \$verbose,
        "stdin!"   => \$stdin,
        "homedir=s"  => \$homedir,
        "user=s"  => \$user,
        #"dryrun!" => \$dryrun,
    ) or die Usage();

    writelog( "$prog: got stdin=$stdin, homedir=$homedir, user=$user" );

    # (die "$prog: Pass user to fetch fingerprint of\n" . Usage());
    #(die "$prog: Pass --homedir to fetch fingerprint from\n" . Usage());

    #warn "$prog: user is $user, homedir is $homedir, stdin is $stdin";

    my %hash;
    my $cmd = "gpg --list-secret-keys --with-colons" . ($homedir ? " --homedir '$homedir'" : "");
    my @lines = $stdin ? <> : `$cmd`;
    #warn "$prog: got " . scalar(@lines) . " lines from " . ($stdin ? "stdin" : "$cmd" );
    #warn "$prog: lines are \n" . join("\n", @lines ) . "\n";
    my $fpr;
    for my $line (@lines) {
        if ($line =~ /^fpr/) { 
            my @parts = split(/:/, $line);
            $fpr = $parts[9];
            print "$prog: parsed fpr: $fpr\n" if $verbose;
        }
        if ($line =~ /^uid/) {
            my @parts = split(/:/, $line);
            my $email = $parts[9];
            $email =~ s/.*<(.*)>.*/$1/;
            print "$prog: email: $email, fingerprint: $fpr\n" if $verbose;
            $hash{$email} = $fpr;
        }
    }
    #if ($user) {
        #die "$prog: no fingerprint for user: $user\n" unless exists( $hash{$user} );
        my $result = $hash{$user} // "";
        print "$result\n";
    #} 
    if ($verbose) {
        print STDERR Dumper( \%hash ) . "\n";
    }
    exit(0);
}

sub writelog {
    my $line = shift;
    open(my $fh, ">>", "/tmp/fingerprints.log" ) || die "can't open logfile";
    print $fh $line;
    close $fh;
}

