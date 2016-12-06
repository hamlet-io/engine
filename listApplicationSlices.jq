# Locate an application slice
def walk:
  . as $in
  | if type == "object" then
      reduce keys[] as $key
        ( []; if ($key == "Slices") then
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