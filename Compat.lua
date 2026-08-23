-- Arui QOL - Compatibility Layer 3.3.5
if not C_Timer then
    C_Timer = {}

    local timerFrame = CreateFrame("Frame", "AruiQOL_TimerFrame")
    local activeTimers = {}

    timerFrame:SetScript("OnUpdate", function(self, elapsed)
        local now = GetTime()
        local i = 1
        while i <= #activeTimers do
            local timer = activeTimers[i]
            if not timer or timer.finished or timer.cancelled then
                table.remove(activeTimers, i)
            elseif now >= timer.expiry then
                timer.finished = true
                table.remove(activeTimers, i)
                if timer.callback then timer.callback() end
            else
                i = i + 1
            end
        end
        if #activeTimers == 0 then
            self:SetScript("OnUpdate", nil)
        end
    end)

    local function ensureTickerFrame()
        if not timerFrame:GetScript("OnUpdate") then
            timerFrame:SetScript("OnUpdate", timerFrame.OnUpdate)
        end
    end

    function C_Timer.After(delay, callback)
        local timer = {
            expiry = GetTime() + (delay or 0),
            callback = callback,
        }
        table.insert(activeTimers, timer)
        ensureTickerFrame()
        return timer
    end

    function C_Timer.NewTicker(interval, callback, iterations)
        local timer = {
            interval = interval or 1,
            callback = callback,
            iterations = iterations,
            elapsed = 0,
            cancelled = false
        }
        local tickerFrame = CreateFrame("Frame")
        tickerFrame:SetScript("OnUpdate", function(self, elapsed)
            if timer.cancelled then
                self:Hide()
                return
            end
            timer.elapsed = timer.elapsed + elapsed
            if timer.elapsed >= timer.interval then
                timer.elapsed = timer.elapsed - timer.interval
                if timer.callback then timer.callback() end
                if timer.iterations then
                    timer.iterations = timer.iterations - 1
                    if timer.iterations <= 0 then
                        timer.cancelled = true
                        self:Hide()
                    end
                end
            end
        end)
        return {
            Cancel = function()
                timer.cancelled = true
                tickerFrame:Hide()
            end
        }
    end
end

local testFrame = CreateFrame("Frame")
local testTex = testFrame:CreateTexture()
local textureMt = getmetatable(testTex)
if textureMt and not textureMt.__index.SetColorTexture then
    textureMt.__index.SetColorTexture = function(self, r, g, b, a)
        self:SetTexture(r, g, b)
        if a then self:SetAlpha(a) end
    end
end

-- ELECTRASOL è UN CAZZO DI POKEMON
local frameMt = getmetatable(testFrame)
if frameMt and not frameMt.__index.SetShown then
    frameMt.__index.SetShown = function(self, shown)
        if shown then self:Show() else self:Hide() end
    end
end
local textureMt2 = getmetatable(testTex)
if textureMt2 and not textureMt2.__index.SetShown then
    textureMt2.__index.SetShown = function(self, shown)
        if shown then self:Show() else self:Hide() end
    end
end
testFrame = nil
testTex = nil
