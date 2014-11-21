local in_progress_set_key = ARGV[1]
local data_key = ARGV[2]
local lock_key = ARGV[3]
local lock_time = ARGV[4]

redis.call('SREM', in_progress_set_key, data_key)
local data = redis.call('HGETALL', data_key)
redis.call('DEL', data_key)

-- Refresh our lock every time. This is a O(1) op, and we're in Redis anyway.
redis.call('EXPIRE', lock_key, lock_time)

return data
