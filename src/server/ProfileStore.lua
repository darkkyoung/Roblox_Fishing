local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Lease = require(script.Parent.Lease)
local Store = {}
Store.__index = Store

function Store.new(domain, notify)
    local memory = RunService:IsStudio() and not Config.StudioPersistence
    local self = setmetatable({profiles = {}, domain = domain, notify = notify, memory = memory, closing = false}, Store)
    if not memory then
        self.backend = DataStoreService:GetDataStore(Config.DataStoreName .. (RunService:IsStudio() and "_Studio" or "_Live"))
    else
        warn("[FILAMENT] STUDIO MEMORY MODE: data will reset when Stop is pressed. No cloud save is attempted.")
    end
    return self
end
function Store:attempt(callback)
    local lastError
    for attempt = 1, Config.SaveAttempts do
        local ok, result = pcall(callback)
        if ok then return true, result end
        lastError = result
        warn(string.format("[FILAMENT] DataStore attempt %d failed: %s", attempt, tostring(result)))
        if attempt < Config.SaveAttempts then task.wait(2^(attempt-1)) end
    end
    return false, lastError
end
function Store:load(player)
    local token = HttpService:GenerateGUID(false)
    local data = self.domain.default()
    if not self.memory then
        local ok, record = self:attempt(function()
            return self.backend:UpdateAsync("player_"..player.UserId, function(old)
                return Lease.acquire(old, token, os.time(), Config.LeaseSeconds, data)
            end)
        end)
        if not ok or not record or not record.lock or record.lock.token ~= token then
            player:Kick("FILAMENT: 저장 데이터를 불러오지 못했습니다. 다른 세션이 종료된 후 잠시 뒤 다시 접속해 주세요. / Data unavailable or session locked.")
            return nil
        end
        data = record.data
    end
    if not self.domain.valid(data) then
        warn("[FILAMENT] Refusing unsupported/corrupt profile", player.UserId)
        player:Kick("FILAMENT: 저장 데이터 검증 실패. 덮어쓰지 않았습니다. / Invalid save; not overwritten.")
        return nil
    end
    local profile = {data = data, token = token, busy = false, closed = false, lastSave = os.time(), status = self.memory and "memory" or "saved"}
    self.profiles[player] = profile
    return profile
end
function Store:write(player, profile, candidate, release)
    if self.memory then return true end
    self.notify(player, "saving")
    local ok, record = self:attempt(function()
        return self.backend:UpdateAsync("player_"..player.UserId, function(old)
            return Lease.write(old, profile.token, os.time(), Config.LeaseSeconds, candidate, release)
        end)
    end)
    if not ok or not record or record.data.revision ~= candidate.revision or (not release and (not record.lock or record.lock.token ~= profile.token)) then
        profile.status = "error"
        profile.closed = true
        self.notify(player, "error")
        warn("[FILAMENT] Save failed/lock lost; session frozen to prevent divergent writes", player.UserId)
        task.delay(2, function()
            if player.Parent then player:Kick("FILAMENT: 저장 오류로 세션을 중지했습니다. 잠시 후 재접속해 주세요. / Save failed; reconnect shortly.") end
        end)
        return false
    end
    profile.lastSave = os.time()
    return true
end
function Store:transaction(player, mutate)
    local p = self.profiles[player]
    if not p or p.closed or self.closing then return false, "notReady" end
    if p.busy then return false, "busy" end
    p.busy = true
    local candidate = Util.clone(p.data)
    local ran, changed, result = pcall(mutate, candidate)
    if not ran then
        warn("[FILAMENT] Transaction exception", changed)
        p.busy = false
        return false, "serverError"
    end
    if not changed then p.busy = false; return false, result end
    candidate.revision += 1
    if not self.domain.valid(candidate) then
        p.busy = false
        warn("[FILAMENT] Rejected invalid transaction")
        return false, "serverError"
    end
    if not self:write(player, p, candidate, false) then p.busy = false; return false, "saveError" end
    p.data = candidate -- publish only after a durable commit (or explicit Studio memory mode).
    p.status = self.memory and "memory" or "saved"
    p.busy = false
    self.notify(player, p.status)
    return true, result
end
function Store:renew(player)
    local p = self.profiles[player]
    if not p or p.closed or p.busy or self.memory or os.time()-p.lastSave < Config.RenewSeconds then return end
    p.busy = true
    if self:write(player, p, p.data, false) then p.status = "saved"; self.notify(player, "saved") end
    p.busy = false
end
function Store:release(player)
    local p = self.profiles[player]
    if not p then return end
    local deadline = os.clock()+20
    while p.busy and os.clock() < deadline do task.wait(0.1) end
    if not p.busy and not p.closed then
        p.busy = true
        self:write(player, p, p.data, true)
        p.closed = true
    end
    self.profiles[player] = nil
end
return Store
