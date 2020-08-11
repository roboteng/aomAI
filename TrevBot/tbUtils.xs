
mutable void tbStatus() {}

rule status
  active
  minInterval 15
  {
    tbStatus();
  }

int tbGetScoutUnitID()
{
  return (0);
}

void tbStatus()
{
  aiEcho("====================");
  float seconds = xsGetTime()/1000.;
  aiEcho("Time: "+ seconds);
  aiEcho("Pop: " + kbGetPop() + " / " + kbGetPopCap());
  aiEcho("Res:");
  aiEcho("    Food: "+kbTotalResourceGet(cResourceFood) + " at " + kbGetResourceIncome(cResourceFood, 60, false));
  aiEcho("    Wood: "+kbTotalResourceGet(cResourceWood)+ " at " + kbGetResourceIncome(cResourceWood, 60, false));
  aiEcho("    Good: "+kbTotalResourceGet(cResourceGold)+ " at " + kbGetResourceIncome(cResourceGold, 60, false));
}
