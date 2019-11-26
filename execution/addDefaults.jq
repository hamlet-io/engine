# Add missing attributes
# - .Id   = Parent key if object
# - .Name = .Id   if not present
# - .Id   = .Name if not present
# 
# Rename atributes
# - Slices = DeploymentUnits (change of terminology)
#
def walk_with_parent($parentKey):
  . as $in
  | if type == "object" then
      reduce keys[] as $key ( {}; 
            if ($key == "Slices") then
                . + { ("DeploymentUnits"):  ($in[$key] | walk_with_parent($key)) } 
            else
                . + { ($key):  ($in[$key] | walk_with_parent($key)) }
            end
        ) |
        if (.Id|not) and $parentKey then
            .Id = $parentKey
        else
            .
        end |
        if (.Name|not) and .Id then
            .Name = .Id
        else
            .
        end |
        if (.Id|not) and .Name then
            .Id = .Name
        else
            .
        end
  elif type == "array" then map( walk_with_parent(null) )
  else
    .
  end;

walk_with_parent(null)
