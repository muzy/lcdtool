#!/usr/bin/env perl
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Config::Tiny;
use Data::Dumper;
use IO::LCDproc;

my $config = Config::Tiny->read('config.ini');

my $client = IO::LCDproc::Client->new(name => $config->{_}->{name});
my $screen = IO::LCDproc::Screen->new(name => $config->{_}->{screen_name}, heartbeat => $config->{_}->{heartbeat});
my $first = IO::LCDproc::Widget->new(
             name => "first", align => "center", xPos => 1, yPos => 1
            );
my $second = IO::LCDproc::Widget->new(
              name => "second", align => "center", xPos => 1, yPos => 2
             );

$client->add( $screen );
$screen->add( $first, $second );
$client->connect() or die "cannot connect: $!";
$client->initialize();

tcp_server(
        $config->{_}->{host},
        $config->{_}->{port},
        sub {
            my ($fh, $host, $port) = @_;
            if (not $fh) {
                die "cannot create listener";
                return;
            }

            my $handle;
            $handle = AnyEvent::Handle->new(
                fh       => $fh,
                on_eof   => sub { undef $handle },
                on_error => sub { undef $handle },
            );

            $handle->push_read(line => sub { announce(@_); });
        }
);

sub announce {
    my ($handle,$command) = @_;
    my ($line,$message) = split(/:/,$command,2);
    if ( $line eq "1" ) {
        $first->set( data => $message );
    } elsif ( $line eq "2" ) {
        $second->set( data => $message );
    } else {
        print "No display available";
    }
    $client->flushAnswers();
}

AnyEvent->condvar->wait();
