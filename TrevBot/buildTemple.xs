rule buildTemple
  active
  minInterval 10
{
  string strBuildTemple = "buildTemple";
  aiEcho("Attempting to build Temple");
  int numTemples = kbUnitCount(cMyID, cUnitTypeTemple, cUnitStateAliveOrBuilding);
  if (numTemples > 0)
  {
    aiEcho("Found temple, disabling self");
    xsDisableSelf();
    return;
  }
  int templePlanID = -1;
  if (aiPlanGetID(strBuildTemple) > 0)
  {
    templePlanID = aiPlanGetID(strBuildTemple);
  }
  else
  {
    templePlanID = aiPlanCreate(strBuildTemple, cPlanBuild);
  }
  aiEcho("temple build plan: " + templePlanID);
  aiPlanSetVariableInt(templePlanID, cBuildPlanBuildingTypeID, 0, cUnitTypeAbstractTemple);
  //aiPlanSetVariableInt( int planID, int planVariableIndex, int valueIndex, int value )

}
