use strict;
use warnings;
use RedisDB;
use DBIx::Sunny;
use Time::Piece;

my $redis = RedisDB->new();

my $access_user_table = <<SQL;
CREATE TABLE IF NOT EXISTS access_users (
    accessed_at datetime not null,
    user_id int unsigned not null,
    primary key(accessed_at, user_id)
) ENGINE=InnoDB
SQL

my $access_counter_table = <<SQL;
CREATE TABLE IF NOT EXISTS access_counter (
    accessed_at datetime not null,
    count int unsigned not null default 0,
    primary key(accessed_at)
) ENGINE=InnoDB
SQL

my $dbh = DBIx::Sunny->connect("dbi:mysql:redis_experiment", "root", "");
if ( $ENV{"WITH_MYSQL"} ) {
    $dbh->do($access_user_table);
    $dbh->do($access_counter_table);
}

while ( 1 ) {
    my $random_user_id = int(rand() * 1000 * 10000);
    my $t = Time::Piece::localtime();
    my $key = "access_user_bits:" . $t->strftime("%Y-%m-%d:%H:%M");
    warn "SETBIT $key for $random_user_id";
    $redis->multi;
    $redis->setbit($key, $random_user_id, 1);
    if ( $ENV{"WITH_MYSQL"} ) {
        $dbh->query("INSERT IGNORE INTO `access_users` (`accessed_at`, `user_id`) VALUES (?, ?)",$t->strftime("%Y-%m-%d %H:%M:00"), $random_user_id);
    }

    my $count_key = "access_count:" . $t->strftime("%Y-%m-%d:%H:%M");
    warn "COUNTUP $count_key";
    if ( !$redis->incr($count_key) ) {
        $redis->getset($count_key, 1);
    }
    if ( $ENV{"WITH_MYSQL"} ) {
        $dbh->query("INSERT INTO `access_counter` (`accessed_at`, `count`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `count` = `count` + 1", $t->strftime("%Y-%m-%d %H:%M:00"), 1);
    }
    $redis->exec;
}
