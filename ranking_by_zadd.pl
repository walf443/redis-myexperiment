use strict;
use warnings;
use RedisDB;
use Parallel::Prefork;
use Devel::KYTProf;
Devel::KYTProf->add_prof("RedisDB", 'execute', sub {
    my ($orig, $redis, $cmd, @args) = @_;
    my $args = join(" ", @args);
    return "$cmd $args";
});
Devel::KYTProf->threshold(10);

my $pm = Parallel::Prefork->new({
    max_workers => $ENV{NUM_PROC} || 10,
    trap_signals => {
        TERM => 'TERM',
        HUP  => 'TERM',
    },
});
while ( $pm->signal_received ne 'TERM' ) {
    $pm->start(sub {
        srand();
        my $redis = RedisDB->new();
        my $redis_slave;
        if ( $ENV{USE_SLAVE} ) {
            $redis_slave = RedisDB->new(host => 'localhost', port => 6380);
        }

        my $random_user_id = int(rand() * 10000);
        my $score = int(rand() * 100) * 10;
        my $bscore;
        if ( $redis_slave ) {
            $bscore = $redis_slave->zscore("ranking:01", "user_id:$random_user_id") || 0;
        } else {
            $bscore = $redis->zscore("ranking:01", "user_id:$random_user_id") || 0;
        }
        $redis->zadd("ranking:01", $score + $bscore, "user_id:$random_user_id");
    });
}

$pm->wait_all_children();

