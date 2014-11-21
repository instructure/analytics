local set_key = KEYS[1]
local hash_key = ARGV[1]

for i, sub_key in ipairs(ARGV) do
  if i > 1 then -- first arg is hash_key
    redis.call('HINCRBY', hash_key, sub_key, 1)
  end
end

redis.call('SADD', set_key, hash_key)
