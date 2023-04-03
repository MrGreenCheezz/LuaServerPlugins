-- Configuration
local THIRST_SYSTEM_ENABLED = true
local THIRST_UPDATE_INTERVAL = 40000
local THIRST_MIN = 0
local THIRST_DECAY_AMOUNT = 10

-- If the Thirst system is disabled, stop the script
if not THIRST_SYSTEM_ENABLED then
    return
end

local function CheckForDB()
    CharDBExecute("CREATE TABLE IF NOT EXISTS players_thirst_system( id int(11) NOT NULL, thirst int(11) NOT NULL, thirst_state int(3) NOT NULL, PRIMARY KEY (`id`));")
 end
 

-- Store Thirst values for each player
CheckForDB()
local playersThirst = {}
local playersThirstState = {}

local function ChangeThirstState(state, player)
    local guid = player:GetGUIDLow()
    local prevState = playersThirstState[guid]
    local auraOfThirst = player:GetAura(200105)
   
    if state == 0 then 
        if auraOfThirst then
            auraOfThirst:Remove()
            playersThirstState[guid] = 0
        else
            playersThirstState[guid] = 0
        end
    elseif state == 1 then
        if auraOfThirst then
            auraOfThirst:SetStackAmount(1)
            playersThirstState[guid] = 1
        else
            player:AddAura(200105, player)
            playersThirstState[guid] = 1
        end
    elseif state == 2 then
        if auraOfThirst then
            auraOfThirst:SetStackAmount(2)
            playersThirstState[guid] = 2
        else
            player:AddAura(200105, player)
            playersThirstState[guid] = 2
        end
    elseif state == 3 then
        if auraOfThirst then
            auraOfThirst:SetStackAmount(3)
            playersThirstState[guid] = 3
        else
            player:AddAura(200105, player)
            playersThirstState[guid] = 3
        end
    elseif state == 4 then
        if auraOfThirst then
            auraOfThirst:SetStackAmount(4)
            playersThirstState[guid] = 4
        else
            player:AddAura(200105, player)
            playersThirstState[guid] = 4
        end
    end

end

local function DBWrite(guid, entry, value)
    local querry = "UPDATE players_thirst_system SET " .. entry .. "=" .. value .. " WHERE id = " .. guid
    CharDBExecute(querry)
    return true
end

-- Initialize Thirst for a new player
local function InitializeThirst(player)
    local guid = player:GetGUIDLow()
    local playerThirst = CharDBQuery("SELECT * FROM players_thirst_system WHERE id = ".. guid)
    playersThirst[guid] = playerThirst:GetInt32(1)
    playersThirstState[guid] = playerThirst:GetInt32(2)
end

local function CallCharUpdate(player)
    local guid = player:GetGUIDLow()
    local Thirst = playersThirst[guid]
    local ThirstState = playersThirstState[guid]

    if  Thirst < 10 then
        ChangeThirstState(4, player)
    elseif Thirst >= 10 and Thirst < 20 then
        ChangeThirstState(3, player)
    elseif Thirst >= 20 and Thirst < 30 then
        ChangeThirstState(2, player)
    elseif Thirst >= 30 and Thirst < 50 then
        ChangeThirstState(1, player)
    else
        ChangeThirstState(0, player)
    end
end

-- Decrease Thirst every interval
local function UpdateThirst(player)
    local guid = player:GetGUIDLow()
    local Thirst = playersThirst[guid]
    local ThirstState = playersThirstState[guid]

    if not Thirst then
        InitializeThirst(player)
    end

    if Thirst - THIRST_DECAY_AMOUNT < 0 then
            Thirst = 0
        else
            Thirst = Thirst - THIRST_DECAY_AMOUNT
    end
    

    
    playersThirst[guid] = Thirst
    CallCharUpdate(player)
end

-- Update player Thirst on a timed interval
local function ThirstUpdate(eventId, delay, repeats, worldobject)
    if worldobject:IsInWorld() then
        UpdateThirst(worldobject)
    end
end

local function IncreaseThirst(amount, player)
    if playersThirst[player:GetGUIDLow()] + amount > 100 then
        playersThirst[player:GetGUIDLow()] = 100
    else
        playersThirst[player:GetGUIDLow()] = playersThirst[player:GetGUIDLow()] + amount
    end
    CallCharUpdate(player)
end





 local function CheckForPlayer(guid)
    local row = CharDBQuery("SELECT * FROM players_thirst_system WHERE id = " .. guid)
    if not (row == nil) then
        return true
        else
            CharDBQuery("INSERT INTO players_thirst_system VALUES ("..guid..", 100, 0 )")
    end
end

-- Reset Thirst when player logs in
local function OnLogin(event, player)
    CheckForDB()
    CheckForPlayer(player:GetGUIDLow())
    InitializeThirst(player)
    player:RegisterEvent(ThirstUpdate, THIRST_UPDATE_INTERVAL, 0)
end


-- Cancel the Thirst update event when player logs out
local function OnLogout(event, player)
   DBWrite(player:GetGUIDLow(), "thirst", playersThirst[player:GetGUIDLow()])
   DBWrite(player:GetGUIDLow(), "thirst_state", playersThirstState[player:GetGUIDLow()])
    player:RemoveEvents()
end

local function OnSpellCaster(event, player, spell, skipCheck)
    player:SendBroadcastMessage(spell:GetEntry() .. " is casted")
end


local function OnPacketSend(event, packet, player)
   local item = player:GetItemByPos(packet:ReadUByte(), packet:ReadUByte())
   local class = item:GetClass()
   local subclass = item:GetSubClass()
   if class == 0 and subclass == 5 then
        IncreaseThirst(100, player)
   end
end

local function OnServerSendOk(event, packet, player)
    local code = packet:GetOpcode()
    if code ~= 221 and code ~= 912 and code ~= 169 and code ~= 502 then
    print(code)
    end
end

local function OnSpellCastThirst(event, player, spell, skipCheck)
    if spell:GetEntry() == 200104 then
        IncreaseThirst(25,player)
    end
end
-- Register the events
RegisterPlayerEvent(3, OnLogin) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, OnLogout) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(5, OnSpellCastThirst)
--RegisterPacketEvent("0x0AB", 5, OnPacketSend)

