[#ftl]
[#include "base.ftl" ]
[#include "swagger.ftl" ]

[#assign swaggerObject = swagger?eval ]
[#assign integrationsObject = integrations?eval ]
[#assign _context =
    {
        "Account" : account,
        "Region" : region
    } ]

[#-- Determine the Cognito User Pools --]
[#assign _context += {"CognitoPools" : getLegacyCognitoPools(_context, integrationsObject)} ]

[@toJSON extendSwaggerDefinition(swaggerObject, integrationsObject, _context) /]

