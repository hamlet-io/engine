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

    [#local imageLink = (_context.Links["image"])!{}]
    [#if ! imageLink?has_content ]
        [#return]
    [/#if]
    [#local image = imageLink.State.Images[_context.Inputs["input:ImageId"]] ]

    [#assign _context = mergeObjects(
        _context,
        {
            "Conditions" : {
                "registry_type" : {
                    "Test" : image.RegistryType
                }
            }
        }
    )]

[/#macro]
