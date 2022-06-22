[#ftl]

[@addExtension
    id="runbook_image_reference_output"
    aliases=[
        "_runbook_image_reference_output"
    ]
    description=[
        "Create the outputs required for an image reference"
    ]
    supportedTypes=[
        RUNBOOK_STEP_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_runbook_image_reference_output_runbook_setup occurrence ]

    [#local image = (_context.Links["image"])!{}]
    [#if ! image?has_content]
        [#return]
    [/#if]

    [#assign _context = mergeObjects(
        _context,
        {
            "TaskParameters" : {
                "StackOutputContent" : getJSON(
                    {
                        image.State.Resources.image.Id: "__input:Reference__",
                        formatId(image.State.Resources.image.Id, NAME_ATTRIBUTE_TYPE): "__input:Tag__"
                    }
                ),
                "DeploymentUnit" : getOccurrenceDeploymentUnit(image),
                "DeploymentGroup" : getOccurrenceDeploymentGroup(image)
            }
        }
    )]
[/#macro]
