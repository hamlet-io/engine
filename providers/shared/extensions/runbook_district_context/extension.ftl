[#ftl]

[@addExtension
    id="runbook_district_context"
    aliases=[
        "_runbook_district_context"
    ]
    description=[
        "Sets the required district context for an engine call"
    ]
    supportedTypes=[
        RUNBOOK_STEP_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_runbook_district_context_runbook_setup occurrence ]
    [#assign _context = mergeObjects(
        _context,
        {
            "TaskParameters" : {
                "GenerationFramework": getCLODeploymentFramework(),
                "GenerationProviders": getCLODeploymentProviders()?join(","),
                "GenerationInputSource" : getCLOInputSource(),
                "RootDir" : getCommandLineOptions().Input.RootDir,
                "DistrictType" : getCommandLineOptions()["Input"]["Filter"]["DistrictType"],
                "Tenant": (getActiveLayer(TENANT_LAYER_TYPE).Name)!"",
                "Account" : (getActiveLayer(ACCOUNT_LAYER_TYPE).Name)!"",
                "Product" : (getActiveLayer(PRODUCT_LAYER_TYPE).Name)!"",
                "Environment" : (getActiveLayer(ENVIRONMENT_LAYER_TYPE).Name)!"",
                "Segment" : (getActiveLayer(SEGMENT_LAYER_TYPE).Name)!""
            }
        }
    )]
[/#macro]
