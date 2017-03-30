# Post-process extended swagger file
# 
def walk_with_parent($parentKey):
  . as $in
  | if type == "object" then
      reduce keys[] as $key ( {};
                if ($in["x-amazon-apigateway-integration"].type == "aws_proxy") and ($key == "responses") then
                    . + { ($key): {} }
                else
                    . + { ($key):  ($in[$key] | walk_with_parent($key)) }
                end
        )
  else
    .
  end;

walk_with_parent(null)
