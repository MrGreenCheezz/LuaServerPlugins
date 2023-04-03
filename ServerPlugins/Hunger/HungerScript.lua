-- Configuration
local HUNGER_SYSTEM_ENABLED = true
local HUNGER_UPDATE_INTERVAL = 80000
local HUNGER_MIN = 0
local HUNGER_DECAY_AMOUNT = 10

-- If the hunger system is disabled, stop the script
if not HUNGER_SYSTEM_ENABLED then
    return
end

local function CheckForDB()
    CharDBExecute("CREATE TABLE IF NOT EXISTS players_hunger_system( id int(11) NOT NULL, hunger int(11) NOT NULL, hunger_state int(3) NOT NULL, PRIMARY KEY (`id`));")
 end
 

-- Store hunger values for each player
CheckForDB()
local playersHunger = {}
local playersHungerState = {}

local function ChangeHungerState(state, player)
    local guid = player:GetGUIDLow()
    local prevState = playersHungerState[guid]
    local auraOfHunger = player:GetAura(200100)
   
    if state == 0 then 
        if auraOfHunger then
            auraOfHunger:Remove()
            playersHungerState[guid] = 0
        else
            playersHungerState[guid] = 0
        end
    elseif state == 1 then
        if auraOfHunger then
            auraOfHunger:SetStackAmount(1)
            playersHungerState[guid] = 1
        else
            player:AddAura(200100, player)
            playersHungerState[guid] = 1
        end
    elseif state == 2 then
        if auraOfHunger then
            auraOfHunger:SetStackAmount(2)
            playersHungerState[guid] = 2
        else
            player:AddAura(200100, player)
            playersHungerState[guid] = 2
        end
    elseif state == 3 then
        if auraOfHunger then
            auraOfHunger:SetStackAmount(3)
            playersHungerState[guid] = 3
        else
            player:AddAura(200100, player)
            playersHungerState[guid] = 3
        end
    elseif state == 4 then
        if auraOfHunger then
            auraOfHunger:SetStackAmount(4)
            playersHungerState[guid] = 4
        else
            player:AddAura(200100, player)
            playersHungerState[guid] = 4
        end
    end

end

local function DBWrite(guid, entry, value)
    local querry = "UPDATE players_hunger_system SET " .. entry .. "=" .. value .. " WHERE id = " .. guid
    CharDBExecute(querry)
    return true
end

-- Initialize hunger for a new player
local function InitializeHunger(player)
    local guid = player:GetGUIDLow()
    local playerHunger = CharDBQuery("SELECT * FROM players_hunger_system WHERE id = ".. guid)
    playersHunger[guid] = playerHunger:GetInt32(1)
    playersHungerState[guid] = playerHunger:GetInt32(2)
end

local function CallCharUpdate(player)
    local guid = player:GetGUIDLow()
    local hunger = playersHunger[guid]
    local hungerState = playersHungerState[guid]

    if  hunger < 10 then
        ChangeHungerState(4, player)
    elseif hunger >= 10 and hunger < 20 then
        ChangeHungerState(3, player)
    elseif hunger >= 20 and hunger < 30 then
        ChangeHungerState(2, player)
    elseif hunger >= 30 and hunger < 50 then
        ChangeHungerState(1, player)
    else
        ChangeHungerState(0, player)
    end
end

-- Decrease hunger every interval
local function UpdateHunger(player)
    local guid = player:GetGUIDLow()
    local hunger = playersHunger[guid]
    local hungerState = playersHungerState[guid]

    if not hunger then
        InitializeHunger(player)
    end

    if hunger - HUNGER_DECAY_AMOUNT < 0 then
            hunger = 0
        else
            hunger = hunger - HUNGER_DECAY_AMOUNT
    end
    

    
    playersHunger[guid] = hunger
    CallCharUpdate(player)
end

-- Update player hunger on a timed interval
local function HungerUpdate(eventId, delay, repeats, worldobject)
    if worldobject:IsInWorld() then
        UpdateHunger(worldobject)
    end
end

local function IncreaseHunger(amount, player)
    if playersHunger[player:GetGUIDLow()] + amount > 100 then
        playersHunger[player:GetGUIDLow()] = 100
    else
        playersHunger[player:GetGUIDLow()] = playersHunger[player:GetGUIDLow()] + amount
    end
    CallCharUpdate(player)
end





 local function CheckForPlayer(guid)
    local row = CharDBQuery("SELECT * FROM players_hunger_system WHERE id = " .. guid)
    if not (row == nil) then
        return true
        else
            CharDBQuery("INSERT INTO players_hunger_system VALUES ("..guid..", 100, 0 )")
    end
end

-- Reset hunger when player logs in
local function OnLogin(event, player)
    CheckForDB()
    CheckForPlayer(player:GetGUIDLow())
    InitializeHunger(player)
    player:RegisterEvent(HungerUpdate, HUNGER_UPDATE_INTERVAL, 0)
    if not player:HasSpell(200102) then
        player:LearnSpell(200102)
    end   
end


-- Cancel the hunger update event when player logs out
local function OnLogout(event, player)
   DBWrite(player:GetGUIDLow(), "hunger", playersHunger[player:GetGUIDLow()])
   DBWrite(player:GetGUIDLow(), "hunger_state", playersHungerState[player:GetGUIDLow()])
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
        IncreaseHunger(100, player)
   end
end

local function OnServerSendOk(event, packet, player)
    local code = packet:GetOpcode()
    if code ~= 221 and code ~= 912 and code ~= 169 and code ~= 502 then
    print(code)
    end
end

local function OnSpellCastHunger(event, player, spell, skipCheck)
    if spell:GetEntry() == 200103 then
        IncreaseHunger(25,player)
    end
end

-- Register the events
RegisterPlayerEvent(3, OnLogin) -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, OnLogout) -- PLAYER_EVENT_ON_LOGOUT
RegisterPlayerEvent(5, OnSpellCastHunger)

--RegisterPacketEvent("0x0AB", 5, OnPacketSend)

