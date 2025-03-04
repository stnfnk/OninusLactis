ScriptName OninusLactisPlayerAlias extends ReferenceAlias

OninusLactis Property QuestScript Auto
 
Event OnPlayerLoadGame()
  if QuestScript 
    (QuestScript as SKI_QuestBase).OnGameReload()
  else
    Debug.Trace("Oninus Lactis: Error - Main quest reference is None in PlayerAlias")
  endif
	QuestScript.Maintenance()
EndEvent