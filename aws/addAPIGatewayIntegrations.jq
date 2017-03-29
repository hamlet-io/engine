# Add API Gateway Integration details to a swagger specification
# 
# Sample invocation
#  jq -f addAPIGatewayIntegration.jq --argjson template "${TEMPLATE}" --arg noResponses true swagger.json
#
# the template must be 
def walk_with_parent($parentKey):
  . as $in
  | if type == "object" then
      reduce keys[] as $key ( {};
                if ($key == "responses") and ($noResponses == "true") then
                    . + { ($key): {} }
                else
                    . + { ($key):  ($in[$key] | walk_with_parent($key)) }
                end
        ) |
        if $parentKey and ($parentKey | test("get|put|patch|post|delete|options|head")) then
            . + {"x-amazon-apigateway-integration" : $template }
        else
            .
        end
  else
    .
  end;

walk_with_parent(null)
