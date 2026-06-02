local uv = vim.uv or vim.loop

function GET_SYSTEM_THEME()
    local system = uv.os_uname().sysname

    -- macOS
    if system == "Darwin" then
        local p = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
        if not p then return "light" end

        local out = p:read("*a")
        p:close()

        if out:match("Dark") then
            return "dark"
        end

        return "light"
    end

    -- Linux (freedesktop portal via dbus-send)
    if system == "Linux" then
        if vim.fn.executable("dbus-send") == 0 then
            return "dark" -- fallback
        end

        local cmd = {
            "dbus-send",
            "--session",
            "--print-reply=literal",
            "--reply-timeout=1000",
            "--dest=org.freedesktop.portal.Desktop",
            "/org/freedesktop/portal/desktop",
            "org.freedesktop.portal.Settings.Read",
            "string:org.freedesktop.appearance",
            "string:color-scheme",
        }

        local p = io.popen(table.concat(cmd, " "))
        if not p then return "dark" end

        local out = p:read("*a")
        p:close()

        -- portal returns 1 = dark, 2 = light
        if out:match("uint32%s+1") then
            return "dark"
        end

        return "light"
    end

    -- Windows (registry-based)
    if system == "Windows_NT" then
        local p = io.popen(
            [[reg.exe Query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme]]
        )
        if not p then return "light" end

        local out = p:read("*a")
        p:close()

        if out:match("0x0") then
            return "dark"
        end

        return "light"
    end

    -- fallback
    return "dark"
end
