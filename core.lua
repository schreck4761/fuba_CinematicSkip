local addonName, addon = ...

local DefaultDB = {
  options = {
    debug = false,
    skipAlreadySeen = true,
    skipOnlyInInstance = false,
    skipInScenario = false,
    lockSkipList = false,
  },
  skipThisCinematic = {},
  skipThisMovie = {},
  neverSkipMovie = {},
  lastMovieID = 0,
  version = 2,
}

-- hopefully fixed for Classic and Wrath -- thanks to Road-block!
local MovieFrame_StopMovie = MovieFrame_StopMovie or function(frame)
  if MovieFrame_OnMovieFinished then
    MovieFrame_OnMovieFinished(MovieFrame)
  else
    GameMovieFinished()
    MovieFrameSubtitleString:Hide()
    MovieFrame:StopMovie()
    WorldFrame:Show()
    if ( MovieFrame.uiParentShown ) then
      UIParent:Show()
      SetUIVisibility(true)
    end
  end
end

local function CreateDatabase()
  if (not fubaSkipCinematicDBTim) or (fubaSkipCinematicDBTim == nil) then fubaSkipCinematicDBTim = DefaultDB end
end

local function ReCreateDatabase()
  fubaSkipCinematicDBTim = DefaultDB
end

local function DebugPrint(debugtext)
  if fubaSkipCinematicDBTim and fubaSkipCinematicDBTim.options.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF0080FFfubaDebug\[|r"..debugtext.."|cFF0080FF\]")
  end
end

if not fubaSkipCinematicDBTim then
  CreateDatabase()
  DebugPrint("Database: Set Default Database because empty")
end

if fubaSkipCinematicDBTim.version and fubaSkipCinematicDBTim.version ~= DefaultDB.version then
  -- do something if "Database Version" is an older version and maybe need attention?!
  DebugPrint("\nDatabase: unsupported Database Version detected.\nDatabase will be resetted now.\This will result in some Cinematics will play again \"once\" but will work properly again after!")
	ReCreateDatabase()
end

MovieFrame:HookScript("OnEvent", function(self, event, ...)
  if event == "PLAY_MOVIE" then
    -- event PLAY_MOVIE has triggered
    if IsModifierKeyDown() then return end -- DO NOT SKIP if any ModifierKey is pressed (ALT, CTRL or SHIFT)
    local movieID = ...
    if (not movieID) then return end
    fubaSkipCinematicDBTim.lastMovieID = movieID -- save last MovieID for further actions maybe?!
    DebugPrint("Event: PLAY_MOVIE with ID: "..movieID);

    local skipScenario = true
    local isInstance, instanceType = IsInInstance()
    if instanceType == "scenario" then skipScenario = fubaSkipCinematicDBTim.options.skipInScenario end
    if (not fubaSkipCinematicDBTim.options.skipAlreadySeen) or (fubaSkipCinematicDBTim.options.skipOnlyInInstance and (not isInstance)) or (not skipScenario) then return end

    if fubaSkipCinematicDBTim.skipThisMovie[movieID] then
      MovieFrame_StopMovie(self)
    elseif (not fubaSkipCinematicDBTim.options.lockSkipList) then
      fubaSkipCinematicDBTim.skipThisMovie[movieID] = true
    end

  elseif event == "STOP_MOVIE" then
  -- event STOP_MOVIE has triggered
  end
end)

CinematicFrame:HookScript("OnEvent", function(self, event, ...)
  if event == "CINEMATIC_START" then
    -- event CINEMATIC_START has triggered
    if IsModifierKeyDown() then return end -- DO NOT SKIP if any ModifierKey is pressed (ALT, CTRL or SHIFT)
    DebugPrint("Event: CINEMATIC_START");

    local MapID = C_Map.GetBestMapForUnit("player")
    if not MapID then return end
    local subZoneText = GetSubZoneText() or ""
		local Name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()

    local skipScenario = true
    local isInstance, instanceType = IsInInstance()
    if instanceType == "scenario" then skipScenario = fubaSkipCinematicDBTim.options.skipInScenario end
    if (not fubaSkipCinematicDBTim.options.skipAlreadySeen) or (fubaSkipCinematicDBTim.options.skipOnlyInInstance and (not isInstance)) or (not skipScenario) then return end

    --if fubaSkipCinematicDBTim.skipThisCinematic[MapID..subZoneText] then
    if fubaSkipCinematicDBTim.skipThisCinematic[MapID..instanceID] then
      CinematicFrame_CancelCinematic()
    elseif (not fubaSkipCinematicDBTim.options.lockSkipList) then
      --fubaSkipCinematicDBTim.skipThisCinematic[MapID..subZoneText] = true
      fubaSkipCinematicDBTim.skipThisCinematic[MapID..instanceID] = true
    end

  elseif event == "CINEMATIC_STOP" then
  -- event CINEMATIC_STOP has triggered
  end
end)

-- Slash Commands for "Config" until i maybe or not add an Optionsframe ;)
_G.SLASH_FUBACANCELCINEMATIC1 = '/fcc'
SlashCmdList.FUBACANCELCINEMATIC = function(msg)
  if not msg or type(msg) ~= "string" or msg == "" or msg == "help" then
    print("|cff0080ff\nfuba's Cancel Cinematic Usage:\n|r============================================================\n|cff0080ff/fcc|r or |cff0080ff/fcc help|r - Show this message\n|cff0080ff/fcc all|r - Toggle \"Addon fuctionality\"\n|cff0080ff/fcc lockSkipList|r - Toggle \"Stop adding new movies to the skip list\"\n|cff0080ff/fcc instance|r - Toggle \"Instance Only\"\n|cff0080ff/fcc scenario|r - Toggle \"Skip also in Scenario\"\n\n\"Hold Down\" a Modifier Key (SHIFT, ALT or CTRL)\nwill \"temporary\" disable ANY Skip!\n|r============================================================")
    return
  end
  local cmd, arg = strsplit(" ", msg:trim():lower()) -- Try splitting by space

  if cmd == "all" then
    if fubaSkipCinematicDBTim.options.skipAlreadySeen then
      fubaSkipCinematicDBTim.options.skipAlreadySeen = false
      print("|cff0080ff[fuba's Cancel Cinematic]|r Overall: |cffFF0000Disabled|r")
    else
      fubaSkipCinematicDBTim.options.skipAlreadySeen = true
      print("|cff0080ff[fuba's Cancel Cinematic]|r Overall: |cff00FF00Enabled|r")
    end
  elseif cmd == "instance" then
    if fubaSkipCinematicDBTim.options.skipOnlyInInstance then
      fubaSkipCinematicDBTim.options.skipOnlyInInstance = false
      print("|cff0080ff[fuba's Cancel Cinematic]|r Skip ONLY in Instance: |cffFF0000Disabled|r")
    else
      fubaSkipCinematicDBTim.options.skipOnlyInInstance = true
      print("|cff0080ff[fuba's Cancel Cinematic]|r Skip ONLY in Instance: |cff00FF00Enabled|r")
    end
  elseif cmd == "scenario" then
    if fubaSkipCinematicDBTim.options.skipInScenario then
      fubaSkipCinematicDBTim.options.skipInScenario = false
      print("|cff0080ff[fuba's Cancel Cinematic]|r Skip also in Scenario: |cffFF0000Disabled|r")
    else
      fubaSkipCinematicDBTim.options.skipInScenario = true
      print("|cff0080ff[fuba's Cancel Cinematic]|r Skip also in Scenario: |cff00FF00Enabled|r")
    end
  elseif cmd == "debug" then
    if fubaSkipCinematicDBTim.options.debug then
      fubaSkipCinematicDBTim.options.debug = false
      print("|cff0080ff[fuba's Cancel Cinematic]|r Debug Messages: |cffFF0000Disabled|r")
    else
      fubaSkipCinematicDBTim.options.debug = true
      print("|cff0080ff[fuba's Cancel Cinematic]|r Debug Messages: |cff00FF00Enabled|r")
    end
  elseif cmd == "developer" and arg and arg == "rdb" then
    ReCreateDatabase()
    print("|cff0080ff[fuba's Cancel Cinematic]|r Reseted Databse to Default")
  elseif cmd == "lockskiplist" then
    if fubaSkipCinematicDBTim.options.lockSkipList then
      fubaSkipCinematicDBTim.options.lockSkipList = false
      print("|cff0080ff[fuba's Cancel Cinematic]|r Lock Skip List: |cffFF0000Disabled|r")
    else
      fubaSkipCinematicDBTim.options.lockSkipList = true
      print("|cff0080ff[fuba's Cancel Cinematic]|r Lock Skip List: |cff00FF00Enabled|r")
    end
  elseif cmd == "clearskiplist" then
    fubaSkipCinematicDBTim.skipThisMovie = {}
    print("|cff0080ff[fuba's Cancel Cinematic]|r Cleared skip list.")
  elseif cmd == "addlastmovie" then
    if fubaSkipCinematicDBTim.lastMovieID then
      fubaSkipCinematicDBTim.skipThisMovie[fubaSkipCinematicDBTim.lastMovieID] = true
      print("|cff0080ff[fuba's Cancel Cinematic]|r Added last movie to skip list:", fubaSkipCinematicDBTim.lastMovieID)
    else
      print("|cff0080ff[fuba's Cancel Cinematic]|r No movie id found to add.")
    end
  elseif cmd == "removemovie" and arg then
    local movieID = tonumber(arg)
    if fubaSkipCinematicDBTim.skipThisMovie[movieID] then
      fubaSkipCinematicDBTim.skipThisMovie[movieID] = nil
      print("|cff0080ff[fuba's Cancel Cinematic]|r Removing movie with id:", arg)
    else
      print("|cff0080ff[fuba's Cancel Cinematic]|r Didn't find movie with id:", arg)
    end
  elseif cmd == "addmovie" and arg then
    local movieID = tonumber(arg)
    fubaSkipCinematicDBTim.skipThisMovie[movieID] = true
    print("|cff0080ff[fuba's Cancel Cinematic]|r Adding movie with id:", arg)
  end
end
