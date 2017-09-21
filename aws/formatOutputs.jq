def walk(f):
  . as $in
  | if type == "object" then
      reduce keys[] as $key
        ( {}; . + { ($key):  ($in[$key] | walk(f)) } ) | f
  elif type == "array" then map( walk(f) ) | f
  else f
  end;
  
def formatOutputs:
    if (type == "array") and 
        (map(type=="object" and .OutputKey) | any) then
        (
            {
                "Account" : $Account ,
                "Region" : $Region,
                "Level" : $Level,
                "DeploymentUnit" : $DeploymentUnit,
            } *
            (map( {"key" : .OutputKey, "value" : .OutputValue}) | from_entries)
        ) 
    else
        .
    end;

walk(formatOutputs)
