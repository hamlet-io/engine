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

    [#local imageLink = (_context.Links["image"])!{}]
    [#if ! imageLink?has_content ]
        [#return]
    [/#if]
    [#local image = imageLink.State.Images[_context.Inputs["input:ImageId"]] ]

    [#assign _context = mergeObjects(
        _context,
        {
            "TaskParameters" : {
                "StackOutputContent" : getJSON(
                    {
                        image.Id: "__input:Reference__",
                        formatId(image.Id, NAME_ATTRIBUTE_TYPE): "__input:Tag__"
                    }
                ),
                "DeploymentUnit" : getOccurrenceDeploymentUnit(imageLink),
                "DeploymentGroup" : getOccurrenceDeploymentGroup(imageLink)
            }
        }
    )]
[/#macro]
