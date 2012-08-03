#!/usr/bin/env perl

use warnings;
use strict;

open my $fh, '<', 'download/pci.ids';

my (@vendors, @devices, @subdevices) = ();
my %queries = ();
my %key = (
    0 => sub {
        s/^(....)\s+//; chomp;
        push @vendors, {
            "id" => $1,
            "name" => $_,
            "devices" => [] }
    },
    1 => sub {
        s/^(....)\s+//; chomp;
        push $vendors[-1]{devices}, {
            "id" => $1,
            "name" => $_,
            "subdevices" => [] }
    },
    2 => sub {
        s/^(....)\ (....)\s+//; chomp;
        return if not $2;
        push $vendors[-1]{devices}[-1]{subdevices}, {
            "subvendor" => $1,
            "subdevice" => $2,
            "subsystem_name" => $_ };
    },
);
while (<$fh>) {
    next if m/^#|^\s+$/;
    $key{length $1}->(s/^(\t{0,2})//);
}
foreach my $vendor (@vendors) {
    print "$vendor->{id} $vendor->{name}\n";
    $queries{$vendor->{id}} = $vendor->{name};
    if (scalar @{$vendor->{devices}} > 0) {
        foreach my $device (@{$vendor->{devices}}) {
            print "$vendor->{id} $device->{id}"
                . "$device->{name} $vendor->{name}\n";
            $queries{"$vendor->{id} $device->{id}"} =
                "$device->{name} $vendor->{name}";
            if (scalar @{$device->{subdevices}} > 0) {
                foreach my $subdevice (@{$device->{subdevices}}) {
                    print "$vendor->{id} $device->{id} "
                        . "$subdevice->{subvendor} "
                        . "$subdevice->{subdevice} "
                        . "$vendor->{name} $device->{name} "
                        . "$subdevice->{subsystem_name}\n";
                    $queries{"$vendor->{id} $device->{id}"
                            . "$subdevice->{subvendor} "
                            . "$subdevice->{subdevice} "} =
                                "$device->{name} $vendor->{name}"
                                . "$subdevice->{subsystem_name}";
                }
            }
        }
    }
}
