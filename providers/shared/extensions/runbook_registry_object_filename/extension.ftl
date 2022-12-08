[#ftl]

[@addExtension
    id="runbook_registry_object_filename"
    aliases=[
        "_runbook_registry_object_filename"
    ]
    description=[
        "Set the registry local image path after zip"
    ]
    supportedTypes=[
        RUNBOOK_STEP_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_runbook_registry_object_filename_runbook_setup occurrence ]

    [#local imageLink = (_context.Links["image"])!{}]
    [#if ! imageLink?has_content ]
        [#return]
    [/#if]
    [#local image = imageLink.State.Images[_context.Inputs["input:ImageId"]] ]

    [#assign _context = mergeObjects(
        _context,
        {
            "TaskParameters" : {
                "DestinationPath" : {
                    "Value" : "__output:zip_stage_path:path__/" + (image.ImageFileName)!""
                }
            }
        }
    )]

[/#macro]
