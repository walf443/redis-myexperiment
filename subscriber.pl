use strict;
use warnings;
use RedisDB;
use Parallel::Prefork;

my $pm = Parallel::Prefork->new({
    max_workers => $ENV{NUM_PROCS} || 4,
    trap_signals => {
        TERM => 'TERM',
        HUP  => 'TERM',
    },
});

while ( $pm->signal_received ne 'TERM' ) {
    $pm->start(sub {
        my $redis = RedisDB->new;
        
        $redis->subscription_loop(
            subscribe => ['channel1', 'channel2', 'channel3'],
            psubscribe => ['control.*' => sub {
                my ($redis, $channel, $pattern, $msg) = @_;
                if ( $channel eq 'control.quit' ) {
                    $redis->unsubscribe;
                    $redis->punsubscribe;
                } elsif ( $channel eq 'control.subscribe' ) {
                    $redis->subscribe($msg);
                }
            }],
            default_callback => sub {
                my ($redis, $channel, $pattern, $msg) = @_;
                warn "$$: recieved: $msg from $channel";
            },
        );
    });
}

$pm->wait_all_children();

