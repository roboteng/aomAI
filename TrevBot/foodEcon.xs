
rule gather2
  active
  minInterval 8
{
  aiEcho("Starting gather2");
  int mainBaseID = kbBaseGetMainID(cMyID);

  bool gFarming = false;
  float distance = 50;
  int numAggressivePlans = 0;
  float gMaximumBaseResourceDistance = 100;

   int numberEasyResourceSpots=kbGetNumberValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeEasy, distance);
   if ( kbUnitCount(cMyID, cUnitTypeHerdable) > 0)
   {	 // We have herdables, make up for the fact that the resource count excludes them.
	  numberEasyResourceSpots = numberEasyResourceSpots + 1;
   }

   int numberAggressiveResourceSpots = 0;

   int numberHuntResourceSpots = kbGetNumberValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeHunt, distance);
   int totalNumberResourceSpots=numberAggressiveResourceSpots + numberEasyResourceSpots + numberHuntResourceSpots;
   aiEcho("Food resources:  "+numberAggressiveResourceSpots+" aggressive, "+numberHuntResourceSpots+" hunt, and "+numberEasyResourceSpots+" easy.");

   float aggressiveAmount=kbGetAmountValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeHuntAggressive, distance);
   float easyAmount=kbGetAmountValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeEasy, distance);
   easyAmount = easyAmount + 100* kbUnitCount(cMyID, cUnitTypeHerdable);	  // Add in the herdables, overlooked by the kbGetAmount call.
   float huntAmount=kbGetAmountValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeHunt, distance);
   float totalAmount=aggressiveAmount+easyAmount+huntAmount;
   aiEcho("Food amounts:  "+aggressiveAmount+" aggressive, "+huntAmount+" hunt, and "+easyAmount+" easy.");

   // Only do one aggressive site at a time, they tend to take lots of gatherers
   if (numberAggressiveResourceSpots > 1)
	  numberAggressiveResourceSpots = 1;

   totalNumberResourceSpots=numberAggressiveResourceSpots + numberEasyResourceSpots + numberHuntResourceSpots;

   int gathererCount = kbUnitCount(cMyID,kbTechTreeGetUnitIDTypeByFunctionIndex(cUnitFunctionGatherer, 0),cUnitStateAlive);
   if (cMyCulture == cCultureNorse)
	  gathererCount = gathererCount + kbUnitCount(cMyID,kbTechTreeGetUnitIDTypeByFunctionIndex(cUnitFunctionGatherer, 1),cUnitStateAlive);  // dwarves
   int foodGathererCount = 0.5 + aiGetResourceGathererPercentage(cResourceFood, cRGPActual) * gathererCount;

   if (foodGathererCount <= 0)
	  foodGathererCount = 1;	 // Avoid div 0

   // Preference order is existing farms (except in age 1), new farms if low on food sites, aggressive hunt (size permitting), hunt, easy, then age 1 farms.
   // MK:  "hunt" isn't supported in the kbGetNumberValidResource calls, but if we add it, this code should use it properly.
   int aggHunters = 0;
   int hunters = 0;
   int easy = 0;
   int farmers = 0;
   int unassigned = foodGathererCount;
   int farmerReserve = 0;  // Number of farms we already have, use them first unless Egypt first age (slow slow farming)
   int farmerPreBuild = 0; // Number of farmers to ask for ahead of time when food starts running low.

   int gFarmBaseID = mainBaseID;

   if (farmerReserve > unassigned)
	  farmerReserve = unassigned;   // Can't reserve more than we have!

  bool cvOkToFarmEarly = false;

   if ((farmerReserve > 0) && ((kbGetAge()>cAge1)||cvOkToFarmEarly) ) // Should we farm? Only after age 1
   {
	  unassigned = unassigned - farmerReserve;
   }

   if ( (aiGetGameMode() == cGameModeLightning) || (aiGetGameMode() == cGameModeDeathmatch) )
	  totalAmount = 200;   // Fake a shortage so that farming always starts early in these game modes
   if ( (kbGetAge() > cAge1) || (cMyCulture == cCultureEgyptian) )   // can build farms
   {
	  if ( ((totalNumberResourceSpots < 2) && (xsGetTime() > 150000)) || (totalAmount <= (500 + 50*foodGathererCount)) || (kbGetAge()==cAge3) )
	  {  // Start building if only one spot left, or if we're low on food.  In age 3, start farming anyway.
		 farmerPreBuild = 4;  // Starting prebuild
		 if (cMyCulture == cCultureAtlantean)
			farmerPreBuild = 2;
		 if (farmerPreBuild > unassigned)
			farmerPreBuild = unassigned;
		 //aiEcho("Reserving "+farmerPreBuild+" slots for prebuilding farms.");
		 unassigned = unassigned - farmerPreBuild;
		 if (farmerPreBuild > 0)
				gFarming = true;
	  }
   }
   // Want 1 plan per 12 vills, or fraction thereof.
   int numPlansWanted = 1 + unassigned/12;
   if (cMyCulture == cCultureAtlantean)
	  numPlansWanted = 1 + unassigned/4;
   if (unassigned == 0)
	  numPlansWanted = 0;

   if (numPlansWanted > totalNumberResourceSpots)
   {
	  numPlansWanted = totalNumberResourceSpots;
   }
   int numPlansUnassigned = numPlansWanted;


   int minVillsToStartAggressive = aiGetMinNumberNeedForGatheringAggressives()+0;   // Don't start a new aggressive plan unless we have this many vills...buffer above strict minimum.
   if (cMyCulture == cCultureAtlantean)
	  minVillsToStartAggressive = aiGetMinNumberNeedForGatheringAggressives()+0;


// Start a new plan if we have enough villies and we have the resource.
// If we have a plan open, don't kill it as long as we are within 2 of the needed min...the plan will steal from elsewhere.
   if ( (numPlansUnassigned > 0) && (numberAggressiveResourceSpots > 0)
		&& ( (unassigned > minVillsToStartAggressive)|| ((numAggressivePlans>0) && (unassigned>=(aiGetMinNumberNeedForGatheringAggressives()-2))) ) )   // Need a plan, have resources and enough hunters...or one plan exists already.
   {
	  aiPlanSetVariableInt(2, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHuntAggressive, 1);
	  //aiEcho("Making 1 aggressive plan.");
	  aggHunters = aiGetMinNumberNeedForGatheringAggressives(); // This plan will over-grab due to high priority
	  if (numPlansUnassigned == 1)
		 aggHunters = unassigned;   // use them all if we're small enough for 1 plan
	  numPlansUnassigned = numPlansUnassigned - 1;
	  unassigned = unassigned - aggHunters;
	  numberAggressiveResourceSpots = 1;  // indicates 1 used
   }
   else  // Can't go aggressive
   {
	  aiPlanSetVariableInt(2, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHuntAggressive, 0);
	  numberAggressiveResourceSpots = 0;  // indicate none used
   }

   if ( (numPlansUnassigned > 0) && (numberHuntResourceSpots > 0) )
   {
	  if (numberHuntResourceSpots > numPlansUnassigned)
		 numberHuntResourceSpots = numPlansUnassigned;
	  aiPlanSetVariableInt(2, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHunt, numberHuntResourceSpots);
	  hunters = (numberHuntResourceSpots * unassigned) / numPlansUnassigned;  // If hunters are 2 of 3 plans, they get 2/3 of gatherers.
	  unassigned = unassigned - hunters;
	  numPlansUnassigned = numPlansUnassigned - numberHuntResourceSpots;
   }
   else
   {
	  aiPlanSetVariableInt(2, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHunt, 0);
	  numberHuntResourceSpots = 0;
   }

   if ( (numPlansUnassigned > 0) && (numberEasyResourceSpots > 0) )
   {
	  if (numberEasyResourceSpots > numPlansUnassigned)
		 numberEasyResourceSpots = numPlansUnassigned;
	  aiPlanSetVariableInt(2, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy, numberEasyResourceSpots);
	  easy = (numberEasyResourceSpots * unassigned) / numPlansUnassigned;
	  unassigned = unassigned - easy;
	  numPlansUnassigned = numPlansUnassigned - numberEasyResourceSpots;
   }
   else
   {
	  aiPlanSetVariableInt(2, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy, 0);
	  numberEasyResourceSpots = 0;
   }

   // If we still have some unassigned, and we're in the first age, and we're not egyptian, try to dump them into a plan.
   if ( (kbGetAge() == cAge1) && (unassigned > 0) && (cMyCulture != cCultureEgyptian) )
   {
	  if ( (aggHunters > 0) && (unassigned > 0) )
	  {
		 aggHunters = aggHunters + unassigned;
		 unassigned = 0;
	  }
	  if ( (hunters > 0) && (unassigned > 0) )
	  {
		 hunters = hunters + unassigned;
		 unassigned = 0;
	  }
	  if ( (easy > 0) && (unassigned > 0) )
	  {
		 easy = easy + unassigned;
		 unassigned = 0;
	  }

	  // If we're here and unassigned > 0, we'll just make an easy plan and dump them there, hoping
	  // that there's easy food somewhere outside our base.
	  //aiEcho("Making an emergency easy plan.");
	  aiPlanSetVariableInt(2, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy, numberEasyResourceSpots+1);
	  easy = easy + unassigned;
	  unassigned = 0;
	  if ( (gMaximumBaseResourceDistance < 110.0) && (kbGetAge()<cAge2) )
	  {
		 gMaximumBaseResourceDistance = gMaximumBaseResourceDistance + 10.0;
		 aiEcho("**** Expanding gather radius to "+gMaximumBaseResourceDistance);
	  }
   }


   // Now, the number of farmers we want is the unassigned total, plus reserve (existing farms) and prebuild (plan ahead).
   farmers =farmerReserve + farmerPreBuild;
   unassigned = unassigned - farmers;

   if (unassigned > 0)
   {  // Still unassigned?  Make an extra easy plan, hope they can find food somewhere
	  aiPlanSetVariableInt(2, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy, numberEasyResourceSpots+1);
	  easy = easy + unassigned;
	  unassigned = 0;
   }

   int numFarmPlansWanted = 0;
   if (farmers > 0)
   {
	  numFarmPlansWanted = 1 + ( farmers / aiPlanGetVariableInt(2, cGatherGoalPlanFarmLimitPerPlan, 0) );
	  gFarming = true;
   }
   else
		gFarming = false;
   //Egyptians can farm in the first age and if we're forced to farm early we should do so
   if (((kbGetAge() > 0) || (cMyCulture == cCultureEgyptian)) && (gFarmBaseID != -1) && (xsGetTime() > 180000)||cvOkToFarmEarly)
   {
	  aiPlanSetVariableInt(2, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeFarm, numFarmPlansWanted);
   }
   else
   {
	  numFarmPlansWanted = 0;
   }

   aiEcho("Assignments are "+aggHunters+" aggressive hunters, "+hunters+" hunters, "+easy+" gatherers, and "+farmers+" farmers.");

   //Set breakdown based on goals.
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm, numFarmPlansWanted, 90, (100.0*farmers)/(foodGathererCount*100.0), gFarmBaseID);
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHuntAggressive, numberAggressiveResourceSpots, 45, (100.0*aggHunters)/(foodGathererCount*100.0), mainBaseID);
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHunt, numberHuntResourceSpots, , 66, (100.0*hunters)/(foodGathererCount*100.0), mainBaseID);
   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeEasy, numberEasyResourceSpots, 65, (100.0*easy)/(foodGathererCount*100.0), mainBaseID);
}
