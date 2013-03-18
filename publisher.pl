use strict;
use warnings;
use RedisDB;

my $redis = RedisDB->new;

for ( 1... 100 ) {
    $redis->publish("channel" . int(rand() * 3 + 0.5), "published!!!");
    sleep(1);
}
