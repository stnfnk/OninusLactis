;
; ██╗      █████╗  ██████╗████████╗██╗███████╗
; ██║     ██╔══██╗██╔════╝╚══██╔══╝██║██╔════╝
; ██║     ███████║██║        ██║   ██║███████╗
; ██║     ██╔══██║██║        ██║   ██║╚════██║
; ███████╗██║  ██║╚██████╗   ██║   ██║███████║
; ╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝╚══════╝
;
; If you are a mod developer and want to integrate the nipple squirt effect
; into your own mod, use the following public API. See the indiviudal functions
; for documentation.
;
; Public API
; ---
;
; + StartNippleSquirt(Actor actorRef, int level=0)
; + StopNippleSquirt(Actor actorRef)
; + ToggleNippleSquirt(Actor actorRef, int level=0)
; + PlayNippleSquirt(Actor actorRef, float duration, int level=0)
; + HasNippleSquirt(Actor actorRef)
;
; All other functions and properties are considered private and should not be
; used by other mods.

ScriptName OninusLactis extends SKI_QuestBase

Actor Property PlayerRef Auto
Armor NippleSquirtArmor

EffectShader LactisNippleLeakCBBE

Int Property StartLactatingKey Auto
Float[] Property NippleOffsetL Auto
Float Property EmitterScale Auto
Float Property GlobalEmitterScale Auto
Bool Property NippleLeakEnabled Auto
Bool Property DebugAxisEnabled Auto
Bool Property UseRandomYRotation Auto
Bool Property UseRandomEmitterScale Auto
Bool Property UseRandomEmitterDeactivation Auto
Actor[] Property QueuedStopActors Auto Hidden
float[] Property QueuedStopTimes Auto Hidden

string fVersion = "NG"

Actor[] armorActors
ObjectReference[] armorRefsLeft

; Actor data storage. Stores offset and scale for NPCs.
LactisActorStorage Property actorStorage Auto

Event OnInit()
  Debug.Notification("Installing Oninus Lactis " + fVersion + "...")
  Maintenance()
  RegisterModEvents()
EndEvent

Event OnPlayerLoadGame()
  RegisterModEvents()
  StopAllNippleSquirts()
endEvent

int Function GetVersion()
  return 2
EndFunction

string Function GetVerboseVersion()
  return fVersion
EndFunction

Function Maintenance()
  CleanupAllArrays()
  if !QueuedStopActors
    QueuedStopActors = new Actor[20]
    QueuedStopTimes = new float[20]
  endif
  ; Initialize or recreate armor tracking arrays
  if (armorActors.Length != 20)
    ; If the arrays exist but are wrong size, recreate them
    Actor[] tempActors = armorActors
    ObjectReference[] tempRefsLeft = armorRefsLeft
    
    ; Create new arrays
    armorActors = new Actor[20]
    armorRefsLeft = new ObjectReference[20]
    
    ; Copy existing data if available
    if tempActors && tempActors.Length > 0
      int copyLimit = tempActors.Length
      if copyLimit > 20  ; if old array is larger than new array
        copyLimit = 20   ; limit to new array size
      endif
      int i = 0
      while i < copyLimit
        armorActors[i] = tempActors[i]
        if i < tempRefsLeft.Length
          armorRefsLeft[i] = tempRefsLeft[i]
        endif
        i += 1
      endwhile
    endif
  endif
  RegisterForSingleUpdate(20.0)
  Debug.Trace("Oninus Lactis: Loading forms...")
  NippleSquirtArmor = game.GetFormFromFile(0xD6B, "OninusLactis.esp") as Armor
  LactisNippleLeakCBBE = game.GetFormFromFile(0xD69, "OninusLactis.esp") as EffectShader
  if !NippleSquirtArmor || !LactisNippleLeakCBBE
    Debug.Trace("Oninus Lactis: ERROR - Could not load forms!")
    Return
  endif
  if !actorStorage
    Debug.Trace("Oninus Lactis: ERROR - Could not initialize actorStorage!")
    Return
  endif
  Debug.Trace("Oninus Lactis: actorStorage initialized: " + actorStorage)
  actorStorage = (self as Form) as LactisActorStorage
  Debug.Trace("Oninus Lactis: loaded version is " + fVersion)
  RegisterForKey(StartLactatingKey)
  ApplyArmoredActorProperties()
  Utility.Wait(0.05)
EndFunction

Function RegisterModEvents()
  Utility.Wait(3)
  UnregisterForModEvent("OLactis.Lactating")
  RegisterForModEvent("OLactis.Lactating","OnModEvent_Lactating")
  UnregisterForModEvent("OLactis.SetOffset")
  RegisterForModEvent("OLactis.SetOffset","OnModEvent_SetOffset")
  UnregisterForModEvent("OLactis.RemoveOffset")
  RegisterForModEvent("OLactis.RemoveOffset","OnModEvent_RemoveOffset")
EndFunction

Function OnModEvent_Lactating(Form Who, Int Duration, Int Stage)
  PlayNippleSquirt(Who as Actor, Duration, Stage)
EndFunction

Function OnModEvent_SetOffset(Form Who, Float XOffset, Float ZOffset, Float YOffset, Float LactisScale)
  actorStorage.SetNpcOffsetIndex(Who as Actor, 0, XOffset)
  actorStorage.SetNpcOffsetIndex(Who as Actor, 1, ZOffset)
  actorStorage.SetNpcOffsetIndex(Who as Actor, 2, YOffset)
  actorStorage.SetNpcScale(Who as Actor,LactisScale)
EndFunction

Function OnModEvent_OnModEvent_RemoveOffset(Form Who)
  actorStorage.DeleteNpcStorage(Who as Actor)
EndFunction

;
; ██████╗ ██╗   ██╗██████╗ ██╗     ██╗ ██████╗     █████╗ ██████╗ ██╗
; ██╔══██╗██║   ██║██╔══██╗██║     ██║██╔════╝    ██╔══██╗██╔══██╗██║
; ██████╔╝██║   ██║██████╔╝██║     ██║██║         ███████║██████╔╝██║
; ██╔═══╝ ██║   ██║██╔══██╗██║     ██║██║         ██╔══██║██╔═══╝ ██║
; ██║     ╚██████╔╝██████╔╝███████╗██║╚██████╗    ██║  ██║██║     ██║
; ╚═╝      ╚═════╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝    ╚═╝  ╚═╝╚═╝     ╚═╝

; Start the nipple squirt effect on the given 'actorRef' using the given squirt
; 'level' in the range [0..2].
; If there are already 10 actors with an active effect the call will be ignored.
; If the given 'actorRef' already has the nipple squirt effect running the call
; will be ignored.
; If the "Nipple Leak" feature is enabled in the MCM this function will also
; start the nipple leak overlay.

Function StartNippleSquirt(Actor actorRef, int level=0)
  if !actorRef
    return
  endif
  
  if actorRef.GetLeveledActorBase().GetSex() == 1
    if GetArmoredActorsCount() >= 20
      return
    endif
    if HasArmorRefs(actorRef)
      return
    endif
    LactisNippleSquirtArmor armorRef = StartNippleSquirtLeft(actorRef, level)
    StoreArmorRefs(actorRef, armorRef)
    if NippleLeakEnabled && actorRef.Is3DLoaded()
      StartNippleLeak(actorRef, 18)
    endif
  else
    Debug.Trace("Oninus Lactis: Cannot apply effect to male actor")
    return
  endif
  Utility.Wait(0.05)
EndFunction

; Stops the nipple squirt effect on the given 'actorRef'.
; If the actor does not have an nipple squirt effect running the call will be ignored.
; If the "Nipple Leak" feature is enabled in the MCM this function will also stop
; the nipple leak overlay.
Function StopNippleSquirt(Actor actorRef)
  if !actorRef || !HasArmorRefs(actorRef)
    return
  endif
  
  if NippleLeakEnabled && actorRef.Is3DLoaded()
    StopNippleLeak(actorRef)
  endif
  
  LactisNippleSquirtArmor actorArmor = GetArmorRefs(actorRef)
  StopNippleSquirtInternal(actorRef, actorArmor)
  Utility.Wait(0.05)
  RemoveArmorRefs(actorRef)
EndFunction

; Toggles the nipple squirt effect for the given 'actorRef' on or off using
; the given squirt 'level' in the range [0..2].
Function ToggleNippleSquirt(Actor actorRef, int level=0)
  if !actorRef
    return
  endif
  bool hasNippleSquirt = HasArmorRefs(actorRef)
  ; How long does our operation take?
  ; float ftimeStart = Utility.GetCurrentRealTime()
  if !hasNippleSquirt
    StartNippleSquirt(actorRef, level)
  else
    StopNippleSquirt(actorRef)
  endif
  ; float ftimeEnd = Utility.GetCurrentRealTime()
  ; Console("Starting/stopping took " + (ftimeEnd - ftimeStart) + " seconds to run")
  Utility.Wait(0.05)
EndFunction

; Plays the nipple squirt effect on the given 'actorRef' for the given 'duration'
; specified in seconds using the given squirt 'level' in the range [0..2].
; The effect will automatically stop and removed from the actor after the given
; duration.
Function PlayNippleSquirt(Actor actorRef, float duration, int level=0)
  if !actorRef
    return
  endif
  int inclvl = (level + 1)
  Debug.Trace("Oninus Lactis: " + actorRef.GetDisplayName() + " playing level " + inclvl + " nipple squirt for " + duration as int + " seconds")
  
  ; Start the effect
  StartNippleSquirt(actorRef, level)
  
  ; First, remove any existing scheduled stops for this actor to prevent overlapping timers
  int i = 0
  while i < QueuedStopActors.Length
    if QueuedStopActors[i] == actorRef
      ; Found existing timer for this actor, clear it
      Debug.Trace("Oninus Lactis: Removing previously scheduled effect stop for " + actorRef.GetDisplayName())
      QueuedStopActors[i] = None
      QueuedStopTimes[i] = 0.0
      ; Don't break - clear all instances in case there are duplicates
    endif
    i += 1
  endwhile
  
  ; Now find an empty slot for the new timer
  int emptySlot = QueuedStopActors.Find(None)
  
  ; If found empty slot, use it
  if emptySlot >= 0
    QueuedStopActors[emptySlot] = actorRef
    QueuedStopTimes[emptySlot] = Utility.GetCurrentRealTime() + duration
    Debug.Trace("Oninus Lactis: Scheduled effect stop for " + actorRef.GetDisplayName() + " in " + duration + " seconds")
    
    ; Make sure updates are running
    RegisterForSingleUpdate(1.0)
  else
    Debug.Trace("Oninus Lactis: Warning - No free slots to queue effect stop")
  endif
EndFunction

Event OnUpdate()
  ; First process existing cleanup logic
  CleanupAllArrays()
  
  ; Now check for queued stops
  float currentTime = Utility.GetCurrentRealTime()
  bool hasActiveStops = false
  
  int i = 0
  while i < QueuedStopActors.Length
    Actor actorRef = QueuedStopActors[i]
    
    if actorRef
      if currentTime >= QueuedStopTimes[i]
        ; Time to stop the effect
        if HasNippleSquirt(actorRef)
          StopNippleSquirt(actorRef)
        endif
        
        ; Clear this slot
        QueuedStopActors[i] = None
        QueuedStopTimes[i] = 0.0
      else
        ; Still waiting
        hasActiveStops = true
      endif
    endif
    
    i += 1
  endwhile
  
  ; Schedule next update
  if hasActiveStops
    RegisterForSingleUpdate(1.0)  ; Check again in 1 second
  else
    RegisterForSingleUpdate(20.0)  ; Default cleanup interval from original code
  endif
EndEvent

; Checks whether the given 'actorRef' has the nipple squirt effect running.
bool Function HasNippleSquirt(Actor actorRef)
  if !actorRef || !NippleSquirtArmor
    return false
  endif
  return actorRef.IsEquipped(NippleSquirtArmor)
EndFunction

;
; ██████╗ ██████╗ ██╗██╗   ██╗ █████╗ ████████╗███████╗     █████╗ ██████╗ ██╗
; ██╔══██╗██╔══██╗██║██║   ██║██╔══██╗╚══██╔══╝██╔════╝    ██╔══██╗██╔══██╗██║
; ██████╔╝██████╔╝██║██║   ██║███████║   ██║   █████╗      ███████║██████╔╝██║
; ██╔═══╝ ██╔══██╗██║╚██╗ ██╔╝██╔══██║   ██║   ██╔══╝      ██╔══██║██╔═══╝ ██║
; ██║     ██║  ██║██║ ╚████╔╝ ██║  ██║   ██║   ███████╗    ██║  ██║██║     ██║
; ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚═╝  ╚═╝   ╚═╝   ╚══════╝    ╚═╝  ╚═╝╚═╝     ╚═╝
;

LactisNippleSquirtArmor Function StartNippleSquirtLeft(Actor actorRef, int level=0)
  if !actorRef
    return None
  endif
  LactisNippleSquirtArmor armorRef = actorRef.PlaceAtMe(NippleSquirtArmor, 1, true) as LactisNippleSquirtArmor
  armorRef.ActorRef = actorRef
  armorRef.SetLevel(level, false)
  if actorStorage.HasNpcStorage(actorRef)
    ; update npc armors
    UpdateArmorProperties(armorRef, actorStorage.GetNpcOffset(actorRef), actorStorage.GetNpcScale(actorRef))
  else
    ; update the player's armor
    UpdateArmorProperties(armorRef, NippleOffsetL, EmitterScale)
  endif
  actorRef.AddItem(armorRef, 1, true)
  return armorRef
EndFunction

Function StopNippleSquirtInternal(Actor actorRef, LactisNippleSquirtArmor armorRef)
  if !actorRef || !armorRef
    return
  endif
  actorRef.RemoveItem(armorRef, 1, true)
  Int OnUnEquipp = ModEvent.Create("OLactis.Unequipped")
  ModEvent.PushForm(OnUnEquipp, actorRef as Form)
  ModEvent.Send(OnUnEquipp)
  Utility.Wait(0.05)
  Debug.SendAnimationEvent(actorRef, "RefreshObject")
EndFunction

Function ForceStopNippleSquirt(Actor actorRef)
  if !actorRef
    return
  endif
  actorRef.RemoveItem(NippleSquirtArmor)
  if HasArmorRefs(actorRef)
    RemoveArmorRefs(actorRef)
  endif
  Utility.Wait(0.05)
  actorRef.QueueNiNodeUpdate()
EndFunction

Function StopAllNippleSquirts()
  int i = 0
  int len = armorActors.Length
  Actor actorRef = None
  Debug.Trace("Oninus Lactis: Stopping all nipple squirts")
  while i < len
    actorRef = armorActors[i]
    if actorRef
      LactisNippleSquirtArmor actorArmor = GetArmorRefs(actorRef)
      StopNippleSquirtInternal(actorRef, actorArmor)
      RemoveArmorRefs(actorRef)
      Utility.Wait(0.05)
      actorRef.QueueNiNodeUpdate()
    endif
    i += 1
  endwhile
  FixStuckEffects()
  CleanupAllArrays()
EndFunction

; Updates the properties of the given armor object reference.
; Note that all parameters apply to the left and right armor and
; cannot be controlled individually.
Function UpdateArmorProperties(LactisNippleSquirtArmor armorRef, Float[] nippleOffset, float actorEmitterScale)
  if !armorRef || !nippleOffset
    return
  endif
  armorRef.NippleOffset = nippleOffset
  ; invert x-axis for the right side
  float[] nippleOffsetR = new float[3]
  nippleOffsetR[0] = -nippleOffset[0]
  nippleOffsetR[1] = nippleOffset[1]
  nippleOffsetR[2] = nippleOffset[2]
  armorRef.NippleOffsetR = nippleOffsetR
  armorRef.DebugAxisEnabled = DebugAxisEnabled
  armorRef.GlobalEmitterScale = GlobalEmitterScale
  armorRef.EmitterScale = actorEmitterScale
  armorRef.UseRandomEmitterScale = UseRandomEmitterScale
  armorRef.UseRandomYRotation = UseRandomYRotation
  armorRef.UseRandomEmitterDeactivation = UseRandomEmitterDeactivation
  armorRef.UpdateNodeProperties()
EndFunction

Function ApplyArmoredActorProperties()
  int i = 0
  Actor actorRef = None
  while i < armorActors.Length
    actorRef = armorActors[i]
    if actorRef != None
      LactisNippleSquirtArmor actorArmor = GetArmorRefs(actorRef)
      if actorArmor
        actorArmor.UpdateNodeProperties()
      endif
    endif
    i += 1
  endwhile
EndFunction

; ----------------------------- Nipple leak

; Plays the nipple leaking effect on both breasts of the given 'ActorRef'.
; The 'duration' is in seconds, use -1 to play the effect forever.
Function StartNippleLeak(Actor actorRef, int duration)
  if !actorRef || !LactisNippleLeakCBBE
    return
  endif
  LactisNippleLeakCBBE.play(actorRef, duration)
EndFunction

; Stops the milk leaking effect on both breasts
Function StopNippleLeak(Actor actorRef)
  if !actorRef || !LactisNippleLeakCBBE
    return
  endif
  LactisNippleLeakCBBE.Stop(actorRef)
EndFunction

; ------------------------- Armor reference storage utilities
;
; Actors with active nipple squirt effect (i.e. the nipple squirt armor equipped)
; are stored in the 'armorActors' array.
;

; Returns whether the given 'actorRef' has the nipple squirt armor equipped, by
; checking the internal 'armorActors' for the 'actorRef'.
bool Function HasArmorRefs(Actor actorRef)
  if !actorRef
    return false
  endif
  int actorIndex = armorActors.Find(actorRef)
  if actorIndex >= 0
    return true
  Else
    return false
  endif
EndFunction

; Stores the left and right armor references for the given actorRef in the
; internal 'armorActors' array.
int Function StoreArmorRefs(Actor actorRef, LactisNippleSquirtArmor armorRefLeft)
  if !actorRef || !armorRefLeft
    Debug.Trace("Oninus Lactis: Error - Tried to store null actor or armor reference")
    return -1
  endif
  int firstFreeIndex = armorActors.Find(None)
  if firstFreeIndex>=0
    ; Console("Storing armor refs for actor=" + actorRef + ", armorRef=" + armorRefLeft)
    armorActors[firstFreeIndex] = actorRef
    armorRefsLeft[firstFreeIndex] = armorRefLeft
  else
    Debug.Trace("Oninus Lactis: Nipple squirt ArmorRef storage full!")
  endif
  return firstFreeIndex
EndFunction

; Gets the left and right armor references for the given actorRef or None if the actor has no
; nipple squirt armor equipped.
LactisNippleSquirtArmor Function GetArmorRefs(Actor actorRef)
  if !actorRef
    return None
  endif
  int actorIndex = armorActors.Find(actorRef)
  if actorIndex >= 0
    return armorRefsLeft[actorIndex] as LactisNippleSquirtArmor
  endif
  ; we cannot return None explicitly here as this will result in a runtime cast error
  ; luckily returning nothing seems to actually return None :)
  return None
EndFunction

; Removes the armor references for the given actorRef from the internal storage.
Function RemoveArmorRefs(Actor actorRef)
  if !actorRef
    return
  endif
  int actorIndex = armorActors.Find(actorRef)
  if actorIndex >= 0
    ; Console("Removing armor refs for actor=" + actorRef)
    armorActors[actorIndex] = None
    armorRefsLeft[actorIndex] = None
  endif
EndFunction

Function CleanupAllArrays()
  int i = 0
  while i < armorActors.Length
    ; Clean up armor refs
    Actor actorRef = armorActors[i]
    if actorRef && !HasNippleSquirt(actorRef)
      armorActors[i] = None
      armorRefsLeft[i] = None
    endif
    i += 1
  endwhile
EndFunction

; Gets the number of actors with active nipple squirt armor stored in the internal
; 'armorActors' arrary.
Int Function GetArmoredActorsCount()
  int i = 0
  int len = armorActors.Length
  int count = 0
  Actor actorRef = None
  while i < len
    actorRef = armorActors[i]
    if actorRef && HasNippleSquirt(actorRef)
      count += 1
    endif
    i += 1
  endwhile
  return count
EndFunction

; ---------------------------- Utility functions

Event OnKeyDown(Int keyCode)
  ; https://www.creationkit.com/index.php?title=Input_Script#DXScanCodes
  if (Utility.IsInMenuMode() || UI.IsMenuOpen("console"))
    Return
  endif
  Debug.Trace("Oninus Lactis: Key pressed: " + keyCode)

  ; Handle StartLactatingKey
  if (keyCode == StartLactatingKey)
    Debug.Trace("Oninus Lactis: Start lactating key pressed")
    ObjectReference crosshairObjRef = Game.GetCurrentCrosshairRef()
    Actor crosshairActor = crosshairObjRef as Actor
    Actor affectedActor = PlayerRef
    if crosshairActor != None
      affectedActor = crosshairActor
    endif
    ToggleNippleSquirt(affectedActor)
    Return ; Added return to prevent checking other keys
  endif
  ; Your other key handlers can stay below this...
  ; keycode 34 = G
  ; keycode 35 = H
  ; keycode 42 = left shift
  ; keycode 54 = right shift
EndEvent

Function Uninstall()
  Debug.Notification("Uninstalling Oninus Lactis")
  UnregisterForUpdate()
  StopAllNippleSquirts()
  actorStorage.Clear()
  UnregisterForAllModEvents()
  UnregisterForAllKeys()
  Reset()
  Stop()
EndFunction

Function RemapStartLactatingKey(Int zKey)
  Debug.Trace("Oninus Lactis: Remapping ToggleNippleSquirt from " + StartLactatingKey + " to "+ zKey)
  UnregisterForKey(StartLactatingKey)
  StartLactatingKey = zKey
  RegisterForKey(StartLactatingKey)
EndFunction

Event OnUnload()
  CleanupAllArrays()
EndEvent

Function FixStuckEffects()
    Cell currentCell = PlayerRef.GetParentCell()
    if currentCell
        ; Get all references in the player's current cell
        int fixedCount = 0
        
        ; First check the player
        if PlayerRef.IsEquipped(NippleSquirtArmor)
            bool isTracked = false
            int i = 0
            while i < armorActors.Length
                if armorActors[i] == PlayerRef
                    isTracked = true
                    i = armorActors.Length
                endif
                i += 1
            endwhile
            
            if !isTracked
                ForceStopNippleSquirt(PlayerRef)
                fixedCount += 1
                Debug.Trace("Fixed player")
            endif
        endif
        
        ; Check all references in the cell
        int count = currentCell.GetNumRefs(43) ; 43 is kActor
        int j = 0
        
        while j < count
            Actor cellActor = currentCell.GetNthRef(j, 43) as Actor            
            if cellActor && cellActor.IsEquipped(NippleSquirtArmor)
                bool isTracked = false
                int k = 0
                while k < armorActors.Length
                    if armorActors[k] == cellActor
                        isTracked = true
                        k = armorActors.Length
                    endif
                    k += 1
                endwhile
                
                if !isTracked
                    ForceStopNippleSquirt(cellActor)
                    fixedCount += 1
                    Debug.Trace("Fixed " + cellActor.GetDisplayName())
                endif
            endif            
            j += 1
        endwhile
        if fixedCount > 0
            Debug.Notification("Oninus Lactis: Fixed " + fixedCount + " stuck effects")
        endif
    endif
EndFunction

bool Function IsActorInArray(Actor akActor, Actor[] akArray)
  int i = 0
  while i < akArray.Length
    if akArray[i] == akActor
      return true
    endif
    i += 1
  endwhile
  return false
EndFunction

; Maps the specified value val from the interval defined by srcMin and
; srcMax to the interval defined by dstMin and dstMax.
; returns: The value mapped to the destination interval.
; param 'srcMin': The minimum value of the source interval.
; param 'srcMax': The maximum value of the source interval.
; param 'dstMin': The minimum value of the destination interval.
; param 'dstMax': The maximum value of the destination interval.
; param 'clamp': clamp values outside [dstMin..dstMax] or not.
float Function MapValue(float val, float srcMin, float srcMax, float dstMin, float dstMax, bool clamp) global
  if clamp
    if (val>=srcMax)
      return dstMax
    endif
    if (val<=srcMin)
      return dstMin
    endif
  endif
  return dstMin + (val-srcMin) / (srcMax-srcMin) * (dstMax-dstMin)
EndFunction