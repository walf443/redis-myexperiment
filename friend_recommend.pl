use strict;
use warnings;
use RedisDB;
use Log::Minimal qw(infof);

my $redis = RedisDB->new();
while ( 1 ) {
    my $random_user_id = int(rand() * 10000);
    my $random_target_user_id = int(rand() * 10000);
    my $friend_key = "friend_user_ids:" . $random_user_id;
    my $target_key = "friend_user_ids:" . $random_target_user_id;
    my $friend_union_key = "friendship_union:$random_user_id:$random_target_user_id";
    my $friend_common_key = "friendship_common:$random_user_id:$random_target_user_id";

    $redis->bitop("OR", $friend_union_key, $friend_key, $target_key);
    my $friend_union_count = $redis->bitcount($friend_union_key);
    $redis->expire($friend_union_key, 1);

    $redis->bitop("AND", $friend_common_key, $friend_key, $target_key);
    my $friend_common_count = $redis->bitcount($friend_common_key);
    $redis->expire($friend_common_key, 1);
    my $jaccard = $friend_common_count * 1.0 / ( $friend_union_count || 1.0 );
    if ( $friend_common_count > 0 ) {
        infof("$random_user_id , $random_target_user_id : common: $friend_common_count union: $friend_union_count jaccard: $jaccard");
    }

    $redis->setbit($friend_key, $random_target_user_id, 1);

}
