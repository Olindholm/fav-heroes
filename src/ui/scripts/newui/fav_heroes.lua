--
-- Fav Heroes
-- @Auther Olindholm
--
require('/ui/base.lua')

local interface = object
local interfaceName = interface:GetName()

local favHeroesCount = 5
local maxLobbyPlayers = 10
local maxFetchAttempts = 5

local playerNames = {}
local fetchAttempts = {}

local function GetHeroIconPath(heroName)
    if Empty(heroName) then
        return '/ui/common/ability_coverup.tga'
    end

    local heroDirectories = {
        forsakenarcher = 'forsaken_archer',
        corrupteddisciple = 'corrupted_disciple',
        sandwraith = 'sand_wraith',
        witchslayer = 'witch_slayer',
        dwarfmagi = 'dwarf_magi',
        flintbeastwood = 'flint_beastwood',
        doctorrepulsor = 'doctor_repulsor',
        bombardier = 'bomb',
        emeraldwarden = 'emerald_warden',
        monkeyking = 'monkey_king',
        masterofarms = 'master_of_arms',
        sirbenzington = 'sir_benzington',
        kingklout = 'king_klout',
    }
    local heroIcons = {
        pollywogpriest = 'icons/hero.tga',
        electrician = 'icons/hero.tga',
        yogi = 'icons/hero.tga',
        cthulhuphant = 'alt/icon.tga',
        artillery = 'alt/icon.tga',
        geomancer = 'hd_geomancer/icon.tga',
        sand_wraith = 'hd_sandwraith2/icon.tga',
        tremble = 'hd_tremble/icon.tga',
        tarot = 'hd_tarot/icon.tga',
        bushwack = 'bushwack_hd/icon.tga',
    }

    heroDirectory = heroName
    if heroDirectories[heroName] ~= nil then
        heroDirectory = heroDirectories[heroName]
    end

    heroIcon = 'icon.tga'
    if heroIcons[heroName] ~= nil then
        heroIcon = heroIcons[heroName]
    end

    return '/heroes/' .. heroDirectory .. '/' .. heroIcon
end

local function VoteBanHero(hero)
    interface:UICmd("VoteBanHero('" .. hero.entity .. "');")
    interface:UICmd("TeamChat('" .. Translate("team_message_vote_ban_hero", "hero", GetEntityDisplayName(hero.entity)) .. "')")
end

local function GetLobbyPlayerFavHeroIconWidget(playerIndex, heroIndex)
    return interface:GetWidget(
        'lobby_player_' .. playerIndex .. '_fav_hero_' .. (heroIndex - 1) .. '_icon'
    )
end
local function GetLobbyPlayerFavHeroPercetangeWidget(playerIndex, heroIndex)
    return interface:GetWidget(
        'lobby_player_' .. playerIndex .. '_fav_hero_' .. (heroIndex - 1) .. '_percentage'
    )
end
local function GetLobbyPlayerFavHeroesLoadingWidget(playerIndex)
    return interface:GetWidget('lobby_player_' .. playerIndex .. '_fav_hero_loading')
end
local function GetLobbyPlayerFavHeroesSleeperWidget(playerIndex)
    return interface:GetWidget('LobbyPlayer' .. playerIndex .. 'FavHeroesSleeper')
end

local function ParseFavHeroes(params)
    local favHeroes = {}

    for i = 1, favHeroesCount do
        local favHero       = {}
        favHero.id         = params[i + favHeroesCount * 0]
        favHero.name       = params[i + favHeroesCount * 1]
        favHero.entity     = params[i + favHeroesCount * 2]
        favHero.percentage = params[i + favHeroesCount * 3]
        favHeroes[i]       = favHero
    end

    return favHeroes
end

local function ResetLobbyPlayerFavHeroes(playerIndex)
    for i = 1, favHeroesCount do
        GetLobbyPlayerFavHeroIconWidget(playerIndex, i):SetTexture('$invis')
        GetLobbyPlayerFavHeroIconWidget(playerIndex, i):SetCallback('onclick', function() end)
        GetLobbyPlayerFavHeroPercetangeWidget(playerIndex, i):SetText('')
    end
end

local function FetchLobbyPlayerFavHeroes(index, playerName)
    local attempt = 1

    if Empty(playerName) then
        if Empty(playerNames[index]) then
            return
        else
            playerName = playerNames[index]
            attempt = fetchAttempts[index] + 1

            if attempt > maxFetchAttempts then
                return
            end
        end
    end

    println(
        'Fetching favorites heroes for ' .. playerName ..
        ' (' .. index .. ') (' .. attempt .. '/' .. maxFetchAttempts .. ')'
    )
    SubmitForm(
        'LobbyPlayer' .. index .. 'FavHeroes',
        'f',
        'show_stats',
        'nickname',
        StripClanTag(playerName),
        'cookie',
        Client.GetCookie(),
        'table',
        'campaign'
    )
    playerNames[index] = playerName
    fetchAttempts[index] = attempt
end


local function OnLobbyPlayerInfo(index, clientNum, playerName)
    if clientNum == '-1' then
        return
    end

    ResetLobbyPlayerFavHeroes(index)
    FetchLobbyPlayerFavHeroes(index, playerName)
end

local function OnLobbyPlayerFavHeroesStatus(index, status)
    status = tonumber(status)
    local loading = (status == 1)

    GetLobbyPlayerFavHeroesLoadingWidget(index):SetVisible(loading)

    if loading then
        return -- Loading... / Pending...
    end

    local playerName = playerNames[index]

    if status == 2 then
        -- Success
    elseif status == 3 then
        -- Failed
        GetLobbyPlayerFavHeroesSleeperWidget(index):Sleep(
            0,
            function(...) FetchLobbyPlayerFavHeroes(index, nil) end
        )
    end
end

local function OnLobbyPlayerFavHeroesResult(index, error, favHeroes)
    for i = 1, favHeroesCount do
        local favHero = favHeroes[i]
        local percentage = math.floor(favHero.percentage + 0.5)

        GetLobbyPlayerFavHeroIconWidget(index, i):SetTexture(GetHeroIconPath(favHero.name))
        GetLobbyPlayerFavHeroIconWidget(index, i):SetCallback('onclick', function()
            VoteBanHero(favHero)
			PlaySound('/shared/sounds/ui/revamp/region_click.wav')
		end)
        GetLobbyPlayerFavHeroPercetangeWidget(index, i):SetText(tostring(percentage) .. ' %')
    end
end

for i = 0, maxLobbyPlayers - 1 do
    interface:RegisterWatch(
        'LobbyPlayerInfo' .. i,
        function(_, ...) OnLobbyPlayerInfo(i, ...) end
    )
    interface:RegisterWatch(
        'LobbyPlayer' .. i .. 'FavHeroesStatus',
        function(_, ...) OnLobbyPlayerFavHeroesStatus(i, ...) end
    )
    interface:RegisterWatch(
        'LobbyPlayer' .. i .. 'FavHeroesResult',
        function(_, error, ...) OnLobbyPlayerFavHeroesResult(i, error, ParseFavHeroes(arg)) end
    )
end

-- This must be placed at the end to
-- be able to "use" all functions.
-- It must also be global (aka not local)
FavHeroes = {}
function FavHeroes:Init()
end
