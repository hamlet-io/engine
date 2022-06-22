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

    [#local image = (_context.Links["image"])!{}]
    [#if ! image?has_content]
        [#return]
    [/#if]

    [#assign _context = mergeObjects(
        _context,
        {
            "TaskParameters" : {
                "DestinationPath" : {
                    "Value" : "__output:zip_stage_path:path__/" + (image.State.Resources["image"].ImageFileName)!""
                }
            }
        }
    )]

[/#macro]
