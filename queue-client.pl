use strict;
use warnings;
use RedisDB;

my $redis = RedisDB->new;

for my $i ( 1...10000 ) {
    $redis->lpush("queue", $i);
}
