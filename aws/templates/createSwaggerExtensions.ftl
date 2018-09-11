[#ftl]
[#include "base.ftl" ]
[#include "swagger.ftl" ]

[#assign swaggerObject = swagger?eval ]
[#assign integrationsObject = integrations?eval ]
[#assign context =
    {
        "Account" : account,
        "Region" : region
    } ]

[#-- Determine the Cognito User Pools --]
[#assign context += {"CognitoPools" : getLegacyCognitoPools(context, integrationsObject)} ]

[@toJSON extendSwaggerDefinition(swaggerObject, integrationsObject, context) /]

