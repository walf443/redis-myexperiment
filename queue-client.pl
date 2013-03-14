use strict;
use warnings;
use RedisDB;

my $redis = RedisDB->new;

for my $i ( 1...1000 ) {
    $redis->lpush("queue", $i);
}
