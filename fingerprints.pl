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
    "$prog [--verbose] [--stdin] [--homedir=/home/user/.gpg]\n";
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

__END__ 
# % gpg --list-secret-keys --with-colons
sec:u:2048:1:B3FC93080AE53B51:1531663821:1594735821::u:::scESC:::+:::23::0:
fpr:::::::::73FC93844CC1824ADF730FB1B3FC93080AE53B51:
grp:::::::::4B03D656FCDE560A60A35CB6F9853D59A094ED4C:
uid:u::::1531663821::8825403984CBB6DDCCAA5AB93B16D9A3E08CCACF::user3@gitsecret.io::::::::::0:
ssb:u:2048:1:0D906825507B4982:1531663821::::::e:::+:::23:
fpr:::::::::0E49DDFD2EEDEA0D46D485240D906825507B4982:
grp:::::::::C701DF548F2BF199CAC5E395994C2E22474261A8:
sec:u:2048:1:73296724D64F5628:1537974161:1601046161::u:::scESC:::+:::23::0:
fpr:::::::::98F026EAFD16A9DFDF6A334173296724D64F5628:
grp:::::::::E03801D07BD94BC6B5517B6E50336790866D0F84:
uid:u::::1537974161::93AF1E17877F457ED2AE44B2A3001A5231F702C9::joshr@test.macpro.joshr.com::::::::::0:
ssb:u:2048:1:A40732E5B773BAD5:1537974161::::::e:::+:::23:
fpr:::::::::0D1EBDCF76DDBE7B468379CDA40732E5B773BAD5:
grp:::::::::695072A489B7938B5B1DCAC7F2172152CED68A43:

