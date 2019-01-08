#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long; 
use File::Basename;

my $prog = basename($0);
my $verbose;

# pipe in the output of 'gpg --list-keys --with-fingerprint --with-colons' 
# and pass a username, and this will output the fingerprint (or blank line 
# if there's no exact match)

# Usage() : returns usage information
sub Usage {
    "$prog [--verbose] email\n";
}

# call main()
main();

# main()
sub main {
    GetOptions(
        "verbose!" => \$verbose,
    ) or die Usage();

    my $user = shift( @ARGV ) || die ( "$prog: must pass email on command line\n" . Usage() );
    my @lines = <>;
    unless(@lines > 0) {
        die "$prog: you must pipe in output of gpg --list-keys --with-fingerprint --with-colons\n" . Usage();
    }

    # the fingerprint comes before the email address in the output. 
    # so store the fingerprints as we see them, then output when we see the matching email.
    my $fpr;
    my %hash;   # hash of email -> fingerprint
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

    die "$prog: no fingerprint for user: $user\n" unless exists( $hash{$user} );
    my $result = $hash{$user} // "";
    print "$result\n";
}

