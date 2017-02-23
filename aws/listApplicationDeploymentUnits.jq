# Locate an application deployment unit
def walk:
  . as $in
  | if type == "object" then
      reduce keys[] as $key
        ( []; if ($key == "DeploymentUnits") then
                if ($in["Containers"]) then
                  . + $in[$key]
                else
                  . + []
                end
              else
                . + ($in[$key] | walk) 
              end)
  elif type == "array" then 
    .[] | walk
  else
    []
  end;

walk | unique | .[]