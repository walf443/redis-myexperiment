use strict;
use warnings;
use RedisDB;
use Parallel::Prefork;
use Log::Minimal qw(infof critf warnf);

my $pm = Parallel::Prefork->new({
    max_workers => $ENV{NUM_PROCS} || 4,
    trap_signals => {
        TERM => 'TERM',
        HUP  => 'TERM',
    }
});

while ( $pm->signal_received ne 'TERM' ) {
    $pm->start(sub {
        my $redis = RedisDB->new;
        srand;
        my $counter = 1;
        while ( 1 ) {
            my $job = $redis->brpoplpush("queue", "queue_processed", 1);
            if ( $job ) {
                eval {
                    infof("take job: $job");
                    if ( rand() < 0.1 ) {
                        die "queue failed!!!: $job";
                    }
                    $redis->lrem("queue_processed", 1, $job);
                    infof("finished job successfully: $job");
                };
                if ( $@ ) {
                    critf("it cause error while processing queue.: $@");
                    $redis->lrem("queue_processed", 1, $job);
                    if ( $redis->lpush("queue", $job) ) {
                    } else {
                        critf("reenqueue failed: $job");
                    }
                }
                $counter++;
            }
        }
    });
}

$pm->wait_all_children();

my $redis = RedisDB->new;
while ( $redis->brpoplpush("queue_processed", "queue", 1) ) {
}
