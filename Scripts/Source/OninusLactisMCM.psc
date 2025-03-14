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
  Pages[0] = "$OL_SETTINGS"
  Pages[1] = "$OL_ACTOR_OFFSETS"
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
    Pages = new string[2]
    Pages[0] = "$OL_SETTINGS"
    Pages[1] = "$OL_ACTOR_OFFSETS"
  endIf
EndEvent

Event OnConfigOpen()
  {Called when this config menu is opened}
EndEvent

Event OnConfigClose()
  {Called when this config menu is closed}
EndEvent

Event OnPageReset(string page)
  Main.CleanupAllArrays()
  if Page == "" || Page == "$OL_SETTINGS"
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("$OL_KEYBOARD_MANUAL_MODE")        
    optionKeyStartLactating = AddKeyMapOption("$OL_TOGGLE_NIPPLE_SQUIRT_KEY", Main.StartLactatingKey)
    AddHeaderOption("$OL_PLAYER_NIPPLE_OFFSET")
    optionOffsetLeftX = AddSliderOption("$OL_LEFT_RIGHT", Main.NippleOffsetL[0], "{2}")        
    optionOffsetLeftY = AddSliderOption("$OL_UP_DOWN", Main.NippleOffsetL[2], "{2}")
    optionOffsetLeftZ = AddSliderOption("$OL_BACK_FORTH", Main.NippleOffsetL[1], "{2}")
    optionEmitterScale = AddSliderOption("$OL_EMITTER_SCALE", Main.EmitterScale, "{2}")
    SetCursorPosition(1)
    AddHeaderOption("$OL_GLOBAL_SETTINGS")
    optionDebugAxisEnabled = AddToggleOption("$OL_ENABLE_DEBUG_AXIS", Main.DebugAxisEnabled)
    optionGlobalEmitterScale = AddSliderOption("$OL_GLOBAL_EMITTER_SCALE", Main.GlobalEmitterScale, "{2}")    
    optionNippleLeakEnabled = AddToggleOption("$OL_ENABLE_NIPPLE_LEAK", Main.NippleLeakEnabled)
    AddHeaderOption("$OL_MAINTENANCE")
    AddTextOption("$OL_ACTIVE_NIPPLE_SQUIRTS", Main.GetArmoredActorsCount())
    optionResetAll = AddTextOption("$OL_RESET_ALL", "$OL_CLICK")
    AddHeaderOption("$OL_EXPORT_IMPORT_MCM_SETTINGS")
    optionImportMCMSettings = AddTextOption("$OL_IMPORT_MCM_SETTINGS", "$OL_CLICK") 
    optionExportMCMSettings = AddTextOption("$OL_EXPORT_MCM_SETTINGS", "$OL_CLICK")   
    AddTextOption("$OL_VERSION", Main.GetVerboseVersion(), OPTION_FLAG_DISABLED)
    optionUninstall = AddTextOption("$OL_UNINSTALL_ONINUS_LACTIS", "$OL_UNINSTALL")
    
  elseif Page == "$OL_ACTOR_OFFSETS"    
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddHeaderOption("$OL_ACTOR_NIPPLE_OFFSETS")
    Actor actorRef = GetTargetActor("Crosshair")
    int flags = 0
    if actorRef==None
      flags = OPTION_FLAG_DISABLED
    endif
    optionNpcConsole = AddTextOption(">>> " + ActorName(actorRef), "$OL_SELECT", flags)
    AddEmptyOption()
    AddHeaderOption("$OL_STORED_ACTOR_OFFSETS")
    int npcCount = Main.actorStorage.GetNpcStorageCount()
    int i=0
    optionNpcActors = Utility.CreateIntArray(npcCount)
    while i<npcCount
      optionNpcActors[i] = AddTextOption(ActorName(Main.actorStorage.GetNpcActor(i)), "$OL_SELECT")
      i = i+1
    endwhile

    SetCursorPosition(1)
    if selectedActor
      AddHeaderOption(ActorName(selectedActor))     
      if !Main.actorStorage.HasNpcStorage(selectedActor)
        Main.actorStorage.InitNpcStorage(selectedActor)
      endif
      float[] offset = Main.actorStorage.GetNpcOffset(selectedActor)
      optionNpcOffsetLeftX = AddSliderOption("$OL_LEFT_RIGHT", offset[0], "{2}")        
      optionNpcOffsetLeftY = AddSliderOption("$OL_UP_DOWN", offset[2], "{2}")
      optionNpcOffsetLeftZ = AddSliderOption("$OL_BACK_FORTH", offset[1], "{2}")
      optionNpcScale = AddSliderOption("$OL_EMITTER_SCALE", Main.actorStorage.GetNpcScale(selectedActor), "{2}")
      AddEmptyOption()
      optionNpcDelete = AddTextOption("$OL_DELETE_ACTOR_OFFSETS", "$OL_DELETE")
    endif
  endif
EndEvent


Event OnOptionSelect(int option)
  if (option == optionNippleLeakEnabled)
    Main.NippleLeakEnabled = !Main.NippleLeakEnabled
    SetToggleOptionValue(optionNippleLeakEnabled, Main.NippleLeakEnabled)
  elseif (option == optionDebugAxisEnabled)
    Main.DebugAxisEnabled = !Main.DebugAxisEnabled
    SetToggleOptionValue(optionDebugAxisEnabled, Main.DebugAxisEnabled)
  elseif (option == optionRandomYRotEnabled)    
    Main.UseRandomYRotation = !Main.UseRandomYRotation
    SetToggleOptionValue(optionRandomYRotEnabled, Main.UseRandomYRotation)    
  elseif (option == optionRandomEmitterScaleEnabled)    
    Main.UseRandomEmitterScale = !Main.UseRandomEmitterScale
    SetToggleOptionValue(optionRandomEmitterScaleEnabled, Main.UseRandomEmitterScale)
  elseif (option == optionRandomEmitterDeactivationEnabled)   
    Main.UseRandomEmitterDeactivation = !Main.UseRandomEmitterDeactivation
    SetToggleOptionValue(optionRandomEmitterDeactivationEnabled, Main.UseRandomEmitterDeactivation)
  elseif (option == optionResetAll)
    Main.StopAllNippleSquirts()
  elseif option == optionUninstall
    Main.Uninstall()
    ShowMessage("$OL_MOD_UNINSTALLED", false)
  elseif option == optionExportMCMSettings    
    if ShowMessage("$OL_MCM_EXPORT_CONFIRM", a_withCancel=true) == true
      SetOptionFlags(optionExportMCMSettings, OPTION_FLAG_DISABLED)
      bool result = ExportSettings()
      if result == true
        ShowMessage("$OL_MCM_EXPORT_SUCCESS", false)
      else
        ShowMessage("$OL_MCM_EXPORT_FAILED", false)
      endIf
      SetOptionFlags(optionExportMCMSettings, OPTION_FLAG_NONE)
    endIf       
  elseif option == optionImportMCMSettings
    if ShowMessage("$OL_MCM_IMPORT_CONFIRM", true) == true
      SetOptionFlags(optionImportMCMSettings, OPTION_FLAG_DISABLED)     
      int result = ImportSettings()
      if result==1
        ShowMessage("$OL_MCM_IMPORT_SUCCESS", false)
      elseIf result == 0
        ShowMessage("$OL_MCM_IMPORT_FILE_NOT_FOUND", false)
      else
        ShowMessage("$OL_MCM_IMPORT_FAILED", false)
      endIf
      SetOptionFlags(optionImportMCMSettings, OPTION_FLAG_NONE)
    endIf   
  elseif (option == optionNpcConsole)
    Actor actorRef = GetTargetActor("Crosshair")
    if actorRef && actorRef.GetActorBase().GetSex() == 1  ; Check if female
      SetSelectedActor(actorRef)
    else
      Debug.Notification("$OL_INVALID_FEMALE_NPC")
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
  if (option == optionOffsetLeftX)
    Main.NippleOffsetL[0] = value
    SetSliderOptionValue(optionOffsetLeftX, Main.NippleOffsetL[0], "{2}")
  elseIf (option == optionOffsetLeftY)
    Main.NippleOffsetL[2] = value
    SetSliderOptionValue(optionOffsetLeftY, Main.NippleOffsetL[2], "{2}")
  elseIf (option == optionOffsetLeftZ)
    Main.NippleOffsetL[1] = value
    SetSliderOptionValue(optionOffsetLeftZ, Main.NippleOffsetL[1], "{2}")
  elseIf option == optionEmitterScale
    Main.EmitterScale = value   
    SetSliderOptionValue(optionEmitterScale, Main.EmitterScale, "{2}")
  elseIf (option == optionGlobalEmitterScale)
    Main.GlobalEmitterScale = value
    SetSliderOptionValue(optionGlobalEmitterScale, Main.GlobalEmitterScale, "{2}")
  elseif (option == optionNpcOffsetLeftX)
    if actorRef
      Main.actorStorage.SetNpcOffsetIndex(actorRef, 0, value)
      SetSliderOptionValue(optionNpcOffsetLeftX, value, "{2}")
    endif
  elseIf (option == optionNpcOffsetLeftY)
    if actorRef
      Main.actorStorage.SetNpcOffsetIndex(actorRef, 2, value)
      SetSliderOptionValue(optionNpcOffsetLeftY, value, "{2}")
    endif
  elseIf (option == optionNpcOffsetLeftZ)
    if actorRef
      Main.actorStorage.SetNpcOffsetIndex(actorRef, 1, value)
      SetSliderOptionValue(optionNpcOffsetLeftZ, value, "{2}")
    endif
  elseIf (option == optionNpcScale)
    if actorRef
      Main.actorStorage.SetNpcScale(actorRef, value)
      SetSliderOptionValue(optionNpcScale, value, "{2}")
    endif
  endIf
  ForcePageReset()
EndEvent

Event OnOptionKeyMapChange(Int Option, Int KeyCode, String ConflictControl, String ConflictName)
  Debug.Trace("Oninus Lactis MCM: Key mapping changed - Option: "+ Option + ", KeyCode: " + KeyCode)
  if (Option == optionKeyStartLactating)    
    Main.RemapStartLactatingKey(KeyCode)
    SetKeyMapOptionValue(Option, KeyCode)
    Debug.Trace("Oninus Lactis MCM: Start lactating key remapped to " + KeyCode)
  else
    Debug.Trace("Oninus Lactis MCM: Unknown key option " + Option + " changed")
  endIf
EndEvent

Event OnOptionHighlight(int option)
  {Called when the user highlights an option}
  if option == optionKeyStartLactating
    SetInfoText("$OL_HELP_TOGGLE_KEY")
  elseIf option == optionOffsetLeftX || option == optionOffsetLeftY || option == optionOffsetLeftZ
    SetInfoText("$OL_HELP_PLAYER_OFFSET")
  elseIf option == optionEmitterScale
    SetInfoText("$OL_HELP_PLAYER_EMITTER_SCALE")
  elseif option == optionGlobalEmitterScale
    SetInfoText("$OL_HELP_GLOBAL_EMITTER_SCALE")
  elseif option == optionNippleLeakEnabled
    SetInfoText("$OL_HELP_NIPPLE_LEAK")
  elseif option == optionDebugAxisEnabled
    SetInfoText("$OL_HELP_DEBUG_AXIS")
  elseif option == optionRandomYRotEnabled || option == optionRandomEmitterScaleEnabled || option == optionRandomEmitterDeactivationEnabled
    SetInfoText("$OL_HELP_EXPERIMENTAL_FEATURE")
  elseif option == optionResetAll
    SetInfoText("$OL_HELP_RESET_ALL")
  elseIf optionNpcActors.Find(option)>=0
    SetInfoText("$OL_HELP_SELECT_ACTOR")
  elseif option == optionNpcOffsetLeftX || option == optionNpcOffsetLeftY || option == optionNpcOffsetLeftZ
    SetInfoText("$OL_HELP_NPC_OFFSET")    
  elseif option == optionNpcScale
    SetInfoText("$OL_HELP_NPC_EMITTER_SCALE")
  elseif option == optionNpcDelete
    SetInfoText("$OL_HELP_DELETE_ACTOR")
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
  String filename = "../Lactis/MCM_Settings"
  if JsonUtil.JsonExists(filename) == false
    return 0
  elseIf JsonUtil.IsGood(filename) == false
    return -1
  endIf
  Main.StartLactatingKey = JsonUtil.GetIntValue(filename, "optionKeyStartLactating")
  Main.RemapStartLactatingKey(Main.StartLactatingKey)
  SetKeyMapOptionValue(optionKeyStartLactating, Main.StartLactatingKey)
  Main.NippleOffsetL[0] = JsonUtil.GetFloatValue(filename, "optionOffsetLeftX")
  SetSliderOptionValue(optionOffsetLeftX, Main.NippleOffsetL[0], "{2}")
  Main.NippleOffsetL[2] = JsonUtil.GetFloatValue(filename, "optionOffsetLeftY")
  SetSliderOptionValue(optionOffsetLeftY, Main.NippleOffsetL[2], "{2}")
  Main.NippleOffsetL[1] = JsonUtil.GetFloatValue(filename, "optionOffsetLeftZ")
  SetSliderOptionValue(optionOffsetLeftZ, Main.NippleOffsetL[1], "{2}")
  Main.DebugAxisEnabled = JsonUtil.GetIntValue(filename, "optionDebugAxisEnabled") as bool
  SetToggleOptionValue(optionDebugAxisEnabled, Main.DebugAxisEnabled)
  Main.GlobalEmitterScale = JsonUtil.GetFloatValue(filename, "optionGlobalEmitterScale")
  SetSliderOptionValue(optionGlobalEmitterScale, Main.GlobalEmitterScale, "{2}")
  Main.NippleLeakEnabled = JsonUtil.GetIntValue(filename, "optionNippleLeakEnabled") as bool
  SetToggleOptionValue(optionNippleLeakEnabled, Main.NippleLeakEnabled)
  ForcePageReset()
  return 1
EndFunction

; MCM Recorder support
string Function GetCustomControl(int option)
  Debug.Trace("Oninus Lactis MCM: GetCustomControl called for " + option)
  if option == optionKeyStartLactating
    return "$OL_TOGGLE_NIPPLE_SQUIRT_KEY"
  endif
  return ""
EndFunction

Function FormatCustomControl(string fid, string value)
  Debug.Trace("Oninus Lactis MCM: FormatCustomControl called for " + fid + " with value " + value)
  if fid == "optionKeyStartLactating"
    Main.RemapStartLactatingKey(value as int)
  endif
EndFunction