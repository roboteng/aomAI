//cUnitTypeUIIdleVillagerBanner
//cPlanGather
//cUnitTypeHuntable
//kbResourceGet

rule test
  active //if on
  runImmediately //still runs at the start of game if off
  minInterval 1 //number of seconds
{
  int time = xsGetTime();
  aiEcho("imiditate "+time);
}


int findIdleVillager()
{
  int queryID = kbUnitQueryCreate("Idle Villagers");
  kbUnitQuerySetUnitType(queryID, cUnitTypeUIIdleVillagerBanner );
  int numResults = kbUnitQueryExecute(queryID);
  aiEcho("Found "+numResults+" Results");
  return (numResults);

}


void setAllOnFood()
{
  int planID = aiPlanCreate("gather", cPlanGather);
  aiPlanAddUnitType(planID, cUnitTypeVillagerGreek, 1, 10, 10);
  aiEcho("PlanID is "+planID);
  aiPlanSetActive(planID);

}

int maintainNumberOfUnits( int unitID=-1, int num=-1 )
{
  int planID = aiPlanCreate("maintain"+kbGetProtoUnitName(unitID), cPlanTrain);

  if (planID < 0) {
    aiAttemptResign();
  }

  aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, cUnitTypeVillagerGreek);
  aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, 15);

  aiPlanSetActive(planID);
}

void setupEscrow()
{
  kbEscrowSetPercentage(cEconomyEscrowID, cAllResources, 0.);
  kbEscrowSetPercentage(cMilitaryEscrowID, cAllResources, 0.);
  kbEscrowAllocateCurrentResources();

  aiSetAutoGatherEscrowID(cRootEscrowID);
  aiSetAutoFarmEscrowID(cRootEscrowID);
  aiSetResourceGathererPercentageWeight(cRGPScript, 1);
  aiSetResourceGathererPercentageWeight(cRGPCost, 0);
}

void setupEconomyBalance(int baseID=-1)
{
  kbSetAICostWeight(cResourceFood, 1.);
  kbSetAICostWeight(cResourceWood, .75);
  kbSetAICostWeight(cResourceGold, .75);
  kbSetAICostWeight(cResourceFavor, 2.);

  aiSetResourceGathererPercentage(cResourceFood, 1., false, cRGPScript);
  aiSetResourceGathererPercentage(cResourceWood, 0., false, cRGPScript);
  aiSetResourceGathererPercentage(cResourceGold, 0., false, cRGPScript);
  aiNormalizeResourceGathererPercentages();

  aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm,1, 50, .5, baseID);
  aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHunt,1, 50, .5, baseID);
  aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy,1, 50, .5, baseID);
  aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy,1, 50, .5, baseID);
}

void scout()
{
  int gLandScout=cUnitTypeScout;
  int exploreID=aiPlanCreate("Explore_SpecialGreek", cPlanExplore);
  if (exploreID >= 0)
  {
     aiPlanAddUnitType(exploreID, cUnitTypeScout, 1, 1, 1);
     aiPlanSetActive(exploreID);
  }
}

void main(void){

  //Do some stuff, don't really know what...
  kbLookAtAllUnitsOnMap();
  kbAreaCalculate(1200.0);
  aiRandSetSeed();

  aiEcho("Hello world!");
  maintainNumberOfUnits(cUnitTypeVillagerGreek, 10);

  int mainBaseID = kbBaseCreate(1, "Main Base", kbGetTownLocation());

  setupEscrow();

  setupEconomyBalance(mainBaseID);

  int gatherPlan = aiPlanCreate("Make Villagers Gather Food");
  aiPlanAddUnitType(gatherPlan, cUnitTypeUIIdleVillagerBanner, 1, 10, 10);

  scout();
  setAllOnFood();
}
