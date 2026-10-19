-- Pure server-authoritative state machine; replace this for Fishing V2.
local Machine = {}
function Machine.new(config)
    local self = {}
    function self.begin(now, waitSeconds, reelMultiplier)
        return {phase = "Charge", started = now, changedAt = now, progress = 0, taps = 0,
            waitSeconds = waitSeconds, reelMultiplier = reelMultiplier, lastTap = -100, heldUntil = 0, resisted = false}
    end
    function self.input(s, action, now)
        if action == "release" and s.phase == "Charge" then
            s.power = math.clamp((now - s.started) / config.ChargeSeconds, 0, 1)
            s.phase = "Flight"
            s.changedAt = now
            return true
        elseif action == "hold" and s.phase == "Reel" then
            s.heldUntil = now + config.HoldLease
        elseif action == "stopHold" then
            s.heldUntil = 0
        elseif action == "tap" and s.phase == "Resist" and now < s.deadline and now - s.lastTap >= config.MinTapInterval then
            s.lastTap = now
            s.taps += 1
            if s.taps >= config.ResistanceTaps then
                s.resisted = true
                s.phase = "Reel"
                s.changedAt = now
                s.heldUntil = 0
            end
        end
        return false
    end
    function self.step(s, now, dt)
        if s.phase == "Success" or s.phase == "Failed" then return end
        if now - s.started > config.SessionTimeout or (s.phase == "Charge" and now-s.started > config.MaxChargeSeconds) then
            s.phase = "Failed"
            return
        end
        if s.phase == "Flight" and now - s.changedAt >= config.FlightSeconds then
            s.phase = "Waiting"
            s.changedAt = now
        elseif s.phase == "Waiting" and now - s.changedAt >= s.waitSeconds then
            s.phase = "Reel"
            s.changedAt = now
        elseif s.phase == "Reel" then
            if now <= s.heldUntil then s.progress = math.min(1, s.progress + math.min(dt, 0.15)*config.ProgressPerSecond*s.reelMultiplier) end
            if not s.resisted and s.progress >= config.ResistanceAt then
                s.progress = config.ResistanceAt
                s.phase = "Resist"
                s.deadline = now + config.ResistanceSeconds
                s.changedAt = now
                s.heldUntil = 0
            elseif s.progress >= 1 then s.phase = "Success" end
        elseif s.phase == "Resist" and now >= s.deadline then
            s.phase = "Failed"
        end
    end
    return self
end
return Machine
