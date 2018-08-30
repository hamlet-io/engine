[#ftl]
[#include "base.ftl" ]
[#include "swagger.ftl" ]

[@toJSON
    extendSwaggerDefinition(
        swagger?eval,
        integrations?eval,
        {
            "account" : account,
            "region" : region
        }
    ) /]

