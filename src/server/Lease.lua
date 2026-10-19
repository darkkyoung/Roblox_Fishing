-- Pure UpdateAsync transformations; nil means refuse, never overwrite another session.
local Lease = {}
function Lease.acquire(old, token, now, ttl, defaultData)
    if old and old.lock and old.lock.token ~= token and old.lock.expires > now then return nil end
    return {data = old and old.data or defaultData, lock = {token = token, expires = now+ttl}}
end
function Lease.write(old, token, now, ttl, data, release)
    if not old or not old.lock or old.lock.token ~= token or old.lock.expires <= now then return nil end
    -- Idempotent retry of the exact same revision is allowed.
    if old.data.revision > data.revision then return nil end
    return {data = data, lock = not release and {token = token, expires = now+ttl} or nil}
end
return Lease
