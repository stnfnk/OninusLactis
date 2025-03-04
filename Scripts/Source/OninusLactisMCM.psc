;
; ██╗      █████╗  ██████╗████████╗██╗███████╗    ███╗   ███╗ ██████╗███╗   ███╗
; ██║     ██╔══██╗██╔════╝╚══██╔══╝██║██╔════╝    ████╗ ████║██╔════╝████╗ ████║
; ██║     ███████║██║        ██║   ██║███████╗    ██╔████╔██║██║     ██╔████╔██║
; ██║     ██╔══██║██║        ██║   ██║╚════██║    ██║╚██╔╝██║██║     ██║╚██╔╝██║
; ███████╗██║  ██║╚██████╗   ██║   ██║███████║    ██║ ╚═╝ ██║╚██████╗██║ ╚═╝ ██║
; ╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝╚══════╝    ╚═╝     ╚═╝ ╚═════╝╚═╝     ╚═╝
;                                                                               

Scriptname OninusLactisMCM extends SKI_ConfigBase
Quest Property OninusLactisQuest Auto

OninusLactis Main

; option references
Int optionKeyStartLactating
Int optionOffsetLeftX ; Player offset
Int optionOffsetLeftY
Int optionOffsetLeftZ
Int optionEmitterScale ; Player emitter scale
Int optionGlobalEmitterScale
Int optionNippleLeakEnabled
Int optionDebugAxisEnabled
Int optionRandomYRotEnabled
Int optionRandomEmitterScaleEnabled
Int optionRandomEmitterDeactivationEnabled
Int optionResetAll
Int optionUninstall
Int optionExportMCMSettings
Int optionImportMCMSettings

; NPC offsets options
Int optionNpcConsole
Int optionNpcOffsetLeftX
Int optionNpcOffsetLeftY
Int optionNpcOffsetLeftZ
Int optionNpcScale
Int optionNpcDelete
Int[] optionNpcActors


int Function GetVersion()
  return 2
EndFunction

Event OnConfigInit()
  Init()
  Pages = new string[2]
  Pages[0] = "Settings"
  Pages[1] = "Actor Offsets"
  Debug.Trace("Oninus Lactis MCM: OnConfigInit complete")
EndEvent

Function Init()
  Debug.Trace("Oninus Lactis MCM: Init start")
  Parent.OnGameReload()
  Debug.Trace("Oninus Lactis MCM: Parent.OnGameReload complete")
  if !OninusLactisQuest
    Debug.Trace("Oninus Lactis MCM: OninusLactisQuest property is not set!")
    Return
  endif
  Main = OninusLactisQuest as OninusLactis
  if !Main
    Debug.Trace("Oninus Lactis MCM: Failed to cast OninusLactisQuest to OninusLactis")
    Return
  endif
  Debug.Trace("Oninus Lactis MCM: Init complete successfully")
EndFunction

Event OnVersionUpdate(int a_version)
  ; a_version is the new version, CurrentVersion is the old version
  if (a_version >= 2 && CurrentVersion < 2)
    ; Debug.Trace(self + ": Updating script to version 2")
    Pages = new string[2]
    Pages[0] = "Settings"
    Pages[1] = "Actor Offsets"
  endIf
EndEvent

Event OnConfigOpen()
  {Called when this config menu is opened}
EndEvent

Event OnConfigClose()
  {Called when this config menu is closed}
EndEvent

Event OnPageReset(string page)
  Main.CleanupArmorRefs()
  if Page == "" || Page == "Settings"
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Keyboard (Manual mode)")        
    optionKeyStartLactating = AddKeyMapOption("Toggle nipple squirt key", Main.StartLactatingKey)
    AddHeaderOption("Player Nipple Offset")
    optionOffsetLeftX = AddSliderOption("Left / Right", Main.NippleOffsetL[0], "{2}")        
    optionOffsetLeftY = AddSliderOption("Up / Down", Main.NippleOffsetL[2], "{2}")
    optionOffsetLeftZ = AddSliderOption("Back / Forth", Main.NippleOffsetL[1], "{2}")
    optionEmitterScale = AddSliderOption("Emitter scale", Main.EmitterScale, "{2}")
    SetCursorPosition(1)
    AddHeaderOption("Global settings")
    optionDebugAxisEnabled = AddToggleOption("Enable debug axis", Main.DebugAxisEnabled)
    optionGlobalEmitterScale = AddSliderOption("Global emitter scale", Main.GlobalEmitterScale, "{2}")    
    optionNippleLeakEnabled = AddToggleOption("Enable nipple leak (CBBE EffectShader)", Main.NippleLeakEnabled)
    AddHeaderOption("Maintenance")
    ; optionRandomYRotEnabled = AddToggleOption("Enable random Y rotation", Main.UseRandomYRotation)
    ; optionRandomEmitterScaleEnabled = AddToggleOption("Enable random emitter scale", Main.UseRandomEmitterScale)
    ; optionRandomEmitterDeactivationEnabled = AddToggleOption("Enable random emitter deactivation", Main.UseRandomEmitterDeactivation)   
    
    AddTextOption("Active nipple squirts", Main.GetArmoredActorsCount() )
    optionResetAll = AddTextOption("Reset all", "Click")
    AddHeaderOption("Export / Import MCM Settings")
    optionExportMCMSettings = AddTextOption("Export MCM settings", "Click")   
    optionImportMCMSettings = AddTextOption("Import MCM settings", "Click")   
    optionUninstall = AddTextOption("Uninstall Oninus Lactis", "Uninstall")
    AddTextOption("Version", Main.GetVersion(), OPTION_FLAG_DISABLED)
  elseif Page == "Actor Offsets"    
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("Actor Nipple Offsets")
    Actor actorRef = GetTargetActor("Crosshair")
    int flags = 0
    if actorRef==None
      flags = OPTION_FLAG_DISABLED
    endif
    optionNpcConsole = AddTextOption("Crosshair: " + ActorName(actorRef), "Select", flags)
    AddEmptyOption()
    AddHeaderOption("Stored actor offsets")
    int npcCount = Main.actorStorage.GetNpcStorageCount()
    int i=0
    optionNpcActors = Utility.CreateIntArray(npcCount)
    while i<npcCount
      optionNpcActors[i] = AddTextOption(ActorName(Main.actorStorage.GetNpcActor(i)), "Select")
      i = i+1
    endwhile

    SetCursorPosition(1)
    if selectedActor
      AddHeaderOption(ActorName(selectedActor))     
      if !Main.actorStorage.HasNpcStorage(selectedActor)
        Main.actorStorage.InitNpcStorage(selectedActor)
      endif
      float[] offset = Main.actorStorage.GetNpcOffset(selectedActor)
      optionNpcOffsetLeftX = AddSliderOption("NPC Left / Right", offset[0], "{2}")        
          optionNpcOffsetLeftY = AddSliderOption("NPC Up / Down", offset[2], "{2}")
          optionNpcOffsetLeftZ = AddSliderOption("NPC Back / Forth", offset[1], "{2}")
      optionNpcScale = AddSliderOption("NPC Emitter Scale", Main.actorStorage.GetNpcScale(selectedActor), "{2}")
      AddEmptyOption()
      optionNpcDelete = AddTextOption("Delete actor offsets", "Delete")
    endif
  endif
EndEvent

Event OnOptionSelect(int option)
  string[] menuOptions = None ; Initialize empty menu options
  if (option == optionNippleLeakEnabled)
    Main.NippleLeakEnabled = !Main.NippleLeakEnabled
    SetToggleOptionValue(optionNippleLeakEnabled, Main.NippleLeakEnabled, menuOptions)
  elseif (option == optionDebugAxisEnabled)
    Main.DebugAxisEnabled = !Main.DebugAxisEnabled
    SetToggleOptionValue(optionDebugAxisEnabled, Main.DebugAxisEnabled, menuOptions)
  elseif (option == optionRandomYRotEnabled)    
    Main.UseRandomYRotation = !Main.UseRandomYRotation
    SetToggleOptionValue(optionRandomYRotEnabled, Main.UseRandomYRotation, menuOptions)    
  elseif (option == optionRandomEmitterScaleEnabled)    
    Main.UseRandomEmitterScale = !Main.UseRandomEmitterScale
    SetToggleOptionValue(optionRandomEmitterScaleEnabled, Main.UseRandomEmitterScale, menuOptions)
  elseif (option == optionRandomEmitterDeactivationEnabled)   
    Main.UseRandomEmitterDeactivation = !Main.UseRandomEmitterDeactivation
    SetToggleOptionValue(optionRandomEmitterDeactivationEnabled, Main.UseRandomEmitterDeactivation, menuOptions)
  elseif (option == optionResetAll)
    Main.StopAllNippleSquirts()   
  elseif option == optionUninstall
    Main.Uninstall()
    ShowMessage("You should save and exit the game now. Then disable the Lactis mod, start game, reload the save. Walk around, wait some time, save and exit game. Then use Resaver to clean the save.", false)
  elseif option == optionExportMCMSettings    
    if ShowMessage("Oninus Lactis MCM setttings will be exported to file 'SKSE/Plugins/Lactis/MCM_Settings.json'", a_withCancel=true) == true
      SetOptionFlags(optionExportMCMSettings, OPTION_FLAG_DISABLED)
      bool result = ExportSettings()
      if result == true
        ShowMessage("Oninus Lactis MCM settings exported succesfully. You can find the file at 'SKSE/Plugins/Lactis/MCM_Settings.json'", false)
      else
        ShowMessage("Oninus Lactis MCM settings export failed.", false)
      endIf
      SetOptionFlags(optionExportMCMSettings, OPTION_FLAG_NONE)
    endIf       
  elseif option == optionImportMCMSettings
    if ShowMessage("Import Oninus Lactis MCM settings from 'SKSE/Plugins/Lactis/MCM_Settings.json'?", true) == true
      SetOptionFlags(optionImportMCMSettings, OPTION_FLAG_DISABLED)     
      int result = ImportSettings()
      if result==1
        ShowMessage("Oninus Lactis MCM settings imported succesfully from 'SKSE/Plugins/Lactis/MCM_Settings.json'.", false)
      elseIf result == 0
        ShowMessage("Oninus Lactis MCM settings file not found. Check if the file exists at 'SKSE/Plugins/Lactis/MCM_Settings.json'", false)
      else
        ShowMessage("Oninus Lactis MCM settings import failed.", false)
      endIf
      SetOptionFlags(optionImportMCMSettings, OPTION_FLAG_NONE)
    endIf   
  elseif (option == optionNpcConsole)
    Actor actorRef = GetTargetActor("Crosshair")
    if actorRef && actorRef.GetActorBase().GetSex() == 1  ; Check if female
      SetSelectedActor(actorRef)
    else
      Debug.Notification("Oninus Lactis: Selected actor is not a valid female NPC")
    endif
  elseif optionNpcActors.Find(option)>=0
    SetSelectedActor(Main.actorStorage.GetNpcActor(optionNpcActors.Find(option)))
  elseif option == optionNpcDelete
    Main.actorStorage.DeleteNpcStorage(selectedActor)
    SetSelectedActor(None)
  endIf
EndEvent

Event OnOptionSliderOpen(int option)
  Actor actorRef = GetSelectedActor()
  if (option == optionOffsetLeftX)
    SetSliderDialogStartValue(Main.NippleOffsetL[0])
    SetSliderDialogDefaultValue(0.0)
    SetSliderDialogRange(-8.0, 8.0)
    SetSliderDialogInterval(0.1)
  elseIf (option == optionOffsetLeftY)
    SetSliderDialogStartValue(Main.NippleOffsetL[2])
    SetSliderDialogDefaultValue(0.0)
    SetSliderDialogRange(-16.0, 1.0)
    SetSliderDialogInterval(0.1)
  elseIf (option == optionOffsetLeftZ)
    SetSliderDialogStartValue(Main.NippleOffsetL[1])
    SetSliderDialogDefaultValue(0.0)
    SetSliderDialogRange(-4.0, 8.0)
    SetSliderDialogInterval(0.1)
  elseIf option == optionEmitterScale
    SetSliderDialogStartValue(Main.EmitterScale)
    SetSliderDialogDefaultValue(1.0)
    SetSliderDialogRange(0.1, 4.0)
    SetSliderDialogInterval(0.1)
  elseIf (option == optionGlobalEmitterScale)
    SetSliderDialogStartValue(Main.GlobalEmitterScale)
    SetSliderDialogDefaultValue(1.0)
    SetSliderDialogRange(0.1, 4.0)
    SetSliderDialogInterval(0.1)

  ; NPC offsets
  elseif (option == optionNpcOffsetLeftX)   
    if actorRef 
      if !Main.actorStorage.HasNpcStorage(actorRef)
        Main.actorStorage.InitNpcStorage(actorRef)
      endif
      float[] offset = Main.actorStorage.GetNpcOffset(actorRef)
      SetSliderDialogStartValue(offset[0])
      SetSliderDialogDefaultValue(0.0)
      SetSliderDialogRange(-14.0, 7.0)
      SetSliderDialogInterval(0.1)      
    endIf
  elseIf (option == optionNpcOffsetLeftY)   
    if actorRef 
      if !Main.actorStorage.HasNpcStorage(actorRef)
        Main.actorStorage.InitNpcStorage(actorRef)
      endif
      float[] offset = Main.actorStorage.GetNpcOffset(actorRef)
      SetSliderDialogStartValue(offset[2])
      SetSliderDialogDefaultValue(0.0)
      SetSliderDialogRange(-16.0, 1.0)
      SetSliderDialogInterval(0.1)
    endif
  elseIf (option == optionNpcOffsetLeftZ)
    if actorRef 
      if !Main.actorStorage.HasNpcStorage(actorRef)
        Main.actorStorage.InitNpcStorage(actorRef)
      endif
      float[] offset = Main.actorStorage.GetNpcOffset(actorRef)
      SetSliderDialogStartValue(offset[1])
      SetSliderDialogDefaultValue(0.0)
      SetSliderDialogRange(-7.0, 7.0)
      SetSliderDialogInterval(0.1)
    endif
  elseIf (option == optionNpcScale)
    if actorRef
      if !Main.actorStorage.HasNpcStorage(actorRef)
        Main.actorStorage.InitNpcStorage(actorRef)
      endif
      float scale = Main.actorStorage.GetNpcScale(actorRef)
      SetSliderDialogStartValue(scale)
      SetSliderDialogDefaultValue(1.0)
      SetSliderDialogRange(0.1, 3.0)
      SetSliderDialogInterval(0.1)
    endif
  endIf
EndEvent

Event OnOptionSliderAccept(int option, float value)
  Actor actorRef = GetSelectedActor()
  string[] menuOptions = None
  if (option == optionOffsetLeftX)
    Main.NippleOffsetL[0] = value
    SetSliderOptionValue(optionOffsetLeftX, Main.NippleOffsetL[0], "{2}", menuOptions)
  elseIf (option == optionOffsetLeftY)
    Main.NippleOffsetL[2] = value
    SetSliderOptionValue(optionOffsetLeftY, Main.NippleOffsetL[2], "{2}", menuOptions)
  elseIf (option == optionOffsetLeftZ)
    Main.NippleOffsetL[1] = value
    SetSliderOptionValue(optionOffsetLeftZ, Main.NippleOffsetL[1], "{2}", menuOptions)
  elseIf option == optionEmitterScale
    Main.EmitterScale = value   
    SetSliderOptionValue(optionEmitterScale, Main.EmitterScale, "{2}", menuOptions)
  elseIf (option == optionGlobalEmitterScale)
    Main.GlobalEmitterScale = value
    SetSliderOptionValue(optionGlobalEmitterScale, Main.GlobalEmitterScale, "{2}", menuOptions)
  elseif (option == optionNpcOffsetLeftX)
    if actorRef
      Main.actorStorage.SetNpcOffsetIndex(actorRef, 0, value)
      SetSliderOptionValue(optionNpcOffsetLeftX, value, "{2}", menuOptions)
    endif
  elseIf (option == optionNpcOffsetLeftY)
    if actorRef
      Main.actorStorage.SetNpcOffsetIndex(actorRef, 2, value)
      SetSliderOptionValue(optionNpcOffsetLeftY, value, "{2}", menuOptions)
    endif
  elseIf (option == optionNpcOffsetLeftZ)
    if actorRef
      Main.actorStorage.SetNpcOffsetIndex(actorRef, 1, value)
      SetSliderOptionValue(optionNpcOffsetLeftZ, value, "{2}", menuOptions)
    endif
  elseIf (option == optionNpcScale)
    if actorRef
      Main.actorStorage.SetNpcScale(actorRef, value)
      SetSliderOptionValue(optionNpcScale, value, "{2}", menuOptions)
    endif
  endIf
EndEvent

Event OnOptionKeyMapChange(Int Option, Int KeyCode, String ConflictControl, String ConflictName)
  Debug.Trace("Oninus Lactis MCM: Key mapping changed - Option: "+ Option + ", KeyCode: " + KeyCode)
  string[] menuOptions = None
  if (Option == optionKeyStartLactating)    
    Main.RemapStartLactatingKey(KeyCode)
    SetKeyMapOptionValue(Option, KeyCode, menuOptions)
    Debug.Trace("Oninus Lactis MCM: Start lactating key remapped to " + KeyCode)
  else
    Debug.Trace("Oninus Lactis MCM: Unknown key option " + Option + " changed")
  endIf
EndEvent

Event OnOptionHighlight(int option)
  {Called when the user highlights an option}
  if option == optionKeyStartLactating
    SetInfoText("Key for toggling nipple squirting on/off on the player.")
  elseIf option == optionOffsetLeftX || option == optionOffsetLeftY || option == optionOffsetLeftZ
    SetInfoText("Offset for the player's nipple squirt emitter origin. Adjust to match the player's body. Note that the offset will be used for both breasts, x offset will be adjusted for each side.")
  ; elseIf option == optionOffsetRightX || option == optionOffsetRightY || option == optionOffsetRightZ
  ; SetInfoText("Offset for the right nipple squirt emitter origin. Adjust to match the player's body.")
  elseIf option == optionEmitterScale
    SetInfoText("Scaling for the player's nipple squirt emitter.")
  elseif option == optionGlobalEmitterScale
    SetInfoText("Global emitter scale for all left and right emitters. Applies to all actors including the player.")
  elseif option == optionNippleLeakEnabled
    SetInfoText("Enables an CBBE overlay texture which simulates nipple leak.")
  elseif option == optionDebugAxisEnabled
    SetInfoText("Enables a debug axis for nipple offset adjustments.")
  elseif option == optionRandomYRotEnabled || option == optionRandomEmitterScaleEnabled || option == optionRandomEmitterDeactivationEnabled
    SetInfoText("Experimental feature which may result in unpredictable behaviour. Dont't use it.")
  elseif option == optionResetAll
    SetInfoText("Removes nipple squirt effect from all actors.")
  ;elseif option == optionNpcConsole
  ;  SetInfoText("Click this entry to set the current console selection as the selected actor. Only works for female actors.")
  elseIf optionNpcActors.Find(option)>=0
    SetInfoText("Click this entry to set as the selected actor.")
  elseif option == optionNpcOffsetLeftX || option == optionNpcOffsetLeftY || option == optionNpcOffsetLeftZ
    SetInfoText("Offset for the selected actor's nipple squirt emitter origin. Adjust to match the selected actor's body. Note that the offset will be used for both breasts, x offset will be adjusted for each side.")    
  elseif option == optionNpcScale
    SetInfoText("Scaling for the selected actor's nipple squirt emitter.")
  elseif option == optionNpcDelete
    SetInfoText("Delete the selected actor's values and remove the actor from the list of stored actors.")
  else 
    SetInfoText("")
  endIf
EndEvent

; Selected actor on the MCM actor offsets page
Actor selectedActor = None

Function SetSelectedActor(Actor actorRef)
  selectedActor = actorRef
  ForcePageReset()
EndFunction

Actor Function GetSelectedActor()
  return selectedActor
EndFunction

Actor Function GetTargetActor(string targetKind)
  if targetKind == "Player"
    return Main.PlayerRef
  elseif targetKind == "Crosshair"
    return Game.GetCurrentCrosshairRef() as Actor
  elseif targetKind == "Console"
    return Game.GetCurrentConsoleRef() as Actor
  else
    return None
  endif
EndFunction

String Function ActorName(Actor actorRef, String default="N/A")
  if actorRef
    return actorRef.GetLeveledActorBase().GetName()
  else
    return default
  endif
EndFunction

Bool Function ExportSettings()
  String filename = "../Lactis/MCM_Settings"
  Bool result
  JsonUtil.SetIntValue(filename, "optionKeyStartLactating", Main.StartLactatingKey as int)
  JsonUtil.SetFloatValue(filename, "optionOffsetLeftX", Main.NippleOffsetL[0])
  JsonUtil.SetFloatValue(filename, "optionOffsetLeftY", Main.NippleOffsetL[2])
  JsonUtil.SetFloatValue(filename, "optionOffsetLeftZ", Main.NippleOffsetL[1])
  JsonUtil.SetIntValue(filename, "optionDebugAxisEnabled", Main.DebugAxisEnabled as int)
  JsonUtil.SetFloatValue(filename, "optionGlobalEmitterScale", Main.GlobalEmitterScale)
  JsonUtil.SetIntValue(filename, "optionNippleLeakEnabled", Main.NippleLeakEnabled as int)
  result = JsonUtil.Save(filename)
  return result
EndFunction

Int Function ImportSettings()
  string[] menuOptions = None
  String filename = "../Lactis/MCM_Settings"
  if JsonUtil.JsonExists(filename) == false
    return 0
  elseIf JsonUtil.IsGood(filename) == false
    return -1
  endIf
  Main.StartLactatingKey = JsonUtil.GetIntValue(filename, "optionKeyStartLactating")
  Main.RemapStartLactatingKey(Main.StartLactatingKey)
  SetKeyMapOptionValue(optionKeyStartLactating, Main.StartLactatingKey, menuOptions)
  Main.NippleOffsetL[0] = JsonUtil.GetFloatValue(filename, "optionOffsetLeftX")
  SetSliderOptionValue(optionOffsetLeftX, Main.NippleOffsetL[0], "{2}", menuOptions)
  Main.NippleOffsetL[2] = JsonUtil.GetFloatValue(filename, "optionOffsetLeftY")
  SetSliderOptionValue(optionOffsetLeftY, Main.NippleOffsetL[2], "{2}", menuOptions)
  Main.NippleOffsetL[1] = JsonUtil.GetFloatValue(filename, "optionOffsetLeftZ")
  SetSliderOptionValue(optionNpcOffsetLeftY, Main.NippleOffsetL[1], "{2}", menuOptions)
  Main.DebugAxisEnabled = JsonUtil.GetIntValue(filename, "optionDebugAxisEnabled") as bool
  SetToggleOptionValue(optionDebugAxisEnabled, Main.DebugAxisEnabled, menuOptions)
  Main.GlobalEmitterScale = JsonUtil.GetFloatValue(filename, "optionGlobalEmitterScale")
  SetSliderOptionValue(optionGlobalEmitterScale, Main.GlobalEmitterScale, "{2}", menuOptions)
  Main.NippleLeakEnabled = JsonUtil.GetIntValue(filename, "optionNippleLeakEnabled") as bool
  SetToggleOptionValue(optionNippleLeakEnabled, Main.NippleLeakEnabled, menuOptions)
  ForcePageReset()
  return 1
EndFunction

; MCM Recorder support
string Function GetCustomControl(int option)
  Debug.Trace("Oninus Lactis MCM: GetCustomControl called for " + option)
  string[] result = new string[1]
  if option == optionKeyStartLactating
    result[0] = "Toggle nipple squirt key"
  endif
  return ""
EndFunction

Function FormatCustomControl(string fid, string value)
  Debug.Trace("Oninus Lactis MCM: FormatCustomControl called for " + fid + " with value " + value)
  if fid == "optionKeyStartLactating"
    Main.RemapStartLactatingKey(value as int)
  endif
EndFunction

string[] Function CreateStringArray(string value1, string value2 = "", string value3 = "", string value4 = "")
  string[] result
  if value4 != ""
    result = new string[4]
    result[3] = value4
  elseif value3 != ""
    result = new string[3]
    result[2] = value3
  elseif value2 != ""
    result = new string[2]
    result[1] = value2
  else
    result = new string[1]
  endif
  result[0] = value1
  return result
EndFunction