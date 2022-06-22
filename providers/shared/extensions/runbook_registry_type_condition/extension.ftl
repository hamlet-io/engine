[#ftl]

[@addExtension
    id="runbook_registry_type_condition"
    aliases=[
        "_runbook_registry_type_condition"
    ]
    description=[
        "Set condition value based on registry type"
    ]
    supportedTypes=[
        RUNBOOK_STEP_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_runbook_registry_type_condition_runbook_setup occurrence ]

    [#local image = (_context.Links["image"])!{}]
    [#if ! image?has_content]
        [#return]
    [/#if]

    [#assign _context = mergeObjects(
        _context,
        {
            "Conditions" : {
                "registry_type" : {
                    "Test" : (image.State.Resources["image"].RegistryType)!""
                }
            }
        }
    )]

[/#macro]
