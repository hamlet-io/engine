[#ftl]

[#macro aws_objectsql_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]

    [#local workGroupId = formatResourceId(AWS_ATHENA_WORKGROUP_RESOURCE_TYPE, core.Id)]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "AppData" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]

    [#assign componentState =
        {
            "Resources" : {
                "workgroup" : {
                    "Id" : workGroupId,
                    "Name" : core.Name,
                    "Type" : AWS_ATHENA_WORKGROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "WORKGROUP" : getExistingReference(id, NAME_ATTRIBUTE_TYPE),
                "QUERY_BUCKET" : dataBucket,
                "QUERY_PREFIX" : getAppDataFilePrefix(occurrence)
            },
            "Roles" : {
                "Inbound" : {}
                "Outbound" : {
                    "default" : "consume"
                    "consume" : athenaConsumePermission(workGroupId)
               }
            }
        }
    ]
[/#macro]
