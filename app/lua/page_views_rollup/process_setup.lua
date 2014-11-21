local set_key = KEYS[1]
local in_progress_set_key = ARGV[1]
local lock_key = ARGV[2]
local lock_time = ARGV[3]

local success = redis.call('SETNX', lock_key, 1)
if success == 0 then
  return redis.error_reply("Could not lock")
end
redis.call('EXPIRE', lock_key, lock_time)

-- If the in progress already exists, a previous worker failed and we'll finish
-- up that work instead.
if redis.call('EXISTS', in_progress_set_key) == 0 then
  redis.call('RENAMENX', set_key, in_progress_set_key)
end

return redis.call('SMEMBERS', in_progress_set_key)
