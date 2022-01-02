[#ftl]

[@addExtension
    id="runbook_get_region"
    aliases=[
        "_runbook_get_region"
    ]
    description=[
        "Get the current provider region"
    ]
    supportedTypes=[
        RUNBOOK_STEP_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_runbook_get_region_runbook_setup occurrence ]
    [#assign _context = mergeObjects(
        _context,
        {
            "TaskParameters" : {
                "Region" : getRegion()
            }
        }
    )]
[/#macro]
