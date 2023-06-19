--
-- Base
-- @Auther Olindholm
--

if not Base then
    Base = {}
    -- Need an interface to register watchers to.
    -- 'main' is the only one that works 100 % of the time
    -- TODO replace with UIManager.GetActiveInterface() ?
    local interface = UIManager.GetInterface('main')

    function GetSide()
        if GetCvarBool('ui_minimap_rightside') then
            return 'right'
        else
            return 'left'
        end
    end

    function GetOppositeSide()
        if not GetCvarBool('ui_minimap_rightside') then
            return 'right'
        else
            return 'left'
        end
    end

    function StripClanTag(playerName)
        if (string.find(playerName, ']')) then
            playerName = string.sub(playerName, string.find(playerName, ']') + 1)
        end
        return playerName
    end

    function IsClientVoiceMuted(client)
        return AtoB(UIManager.GetActiveInterface():UICmd("IsVoiceMuted('" .. client .. "')"))
    end

    function IsPlayerVoiceMuted(playerName)
        local client = GetClientByPlayerName(playerName)
        if (client == nil) then return false end

        return IsClientVoiceMuted(client)
    end

    local MaxAllies = 4
    local ClientByPlayerName = {}

    --
    -- Returns the client number from a player's name.
    -- If no player with the provided name is not connected, nil is returned.
    function GetClientByPlayerName(playerName)
        local striptPlayerName = StripClanTag(playerName)
        return ClientByPlayerName[playerName]
    end

    local function AllyPlayerInfo(allyIndex, sourceWidget, playerName, playerColor, playerClient)
        local striptPlayerName = StripClanTag(playerName)
        ClientByPlayerName[playerName] = playerClient
    end

    for i = 0, MaxAllies - 1 do
        interface:RegisterWatch('AllyPlayerInfo' .. i, function(...) AllyPlayerInfo(i, ...) end)
    end
end
