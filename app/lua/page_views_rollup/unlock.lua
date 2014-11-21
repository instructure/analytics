local lock_key = ARGV[1]

redis.call('DEL', lock_key)
