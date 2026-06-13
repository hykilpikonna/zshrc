local kAccepted = 1
local kNoop = 2

local function is_left_shift(key)
    return key:repr():find("Shift_L", 1, true) ~= nil
end

local function init(env)
    if Switcher == nil then
        return
    end
    env.switcher = Switcher(env.engine)
    env.shift_l_pending = false
end

local function processor(key, env)
    if env.switcher == nil then
        return kNoop
    end

    if is_left_shift(key) then
        if key:release() then
            if env.shift_l_pending then
                env.shift_l_pending = false
                env.switcher:select_next_schema()
                return kAccepted
            end
            return kNoop
        end

        env.shift_l_pending = true
        return kNoop
    end

    if env.shift_l_pending and not key:release() then
        env.shift_l_pending = false
    end

    return kNoop
end

return { init = init, func = processor }
