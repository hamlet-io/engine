[#ftl]
[#include "/base.ftl" ]
[#include "/openapi.ftl" ]

[#assign openapiObject = openapi?eval_json ]
[#assign integrationsObject = integrations?eval_json ]
[#assign _context =
    {
        "Account" : account,
        "Region" : region
    } ]

[#-- Determine the Cognito User Pools --]
[#assign _context += {"CognitoPools" : getLegacyCognitoPools(_context, integrationsObject)} ]

[@toJSON extendOpenapiDefinition(openapiObject, integrationsObject, _context) /]
