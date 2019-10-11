[#ftl]

[#---------------------------------------------------
-- Public functions for stack output processing --
-----------------------------------------------------]

[#assign stackOutputsList = []]

[#assign stackOutputConfiguration = {
    "Properties" : [
        {
            "Type"  : "Description",
            "Value" : "Attributes of deployed resources"
        }
    ],
    "Attributes" : [
        {
            "Names" : "Account",
            "Type" : STRING_TYPE       
        },
        {
            "Names" : "Region",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Level",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "DeploymentUnit",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Id",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "*",
            "Type" : STRING_TYPE
        }
    ]
}]

[#macro addStackOutputs outputs ]
    [@internalMergeStackOutputs
        data=outputs
    /]
[/#macro]

[#function getStackOutputObject provider id deploymentUnit="" region="" account="" ]
    [#-- Build the stack outputs list --]
    [#local outputMacroOptions = 
        [
            [ provider, "input", commandLineOptions.Input.Source, "stackoutput" ],
            [ SHARED_PROVIDER, "input", commandLineOptions.Input.Source, "stackoutput" ]
        ]]
    
    [#local outputMacro = getFirstDefinedDirective(outputMacroOptions)]
    [#if outputMacro?has_content ]
        [@(.vars[outputMacro]) 
            id=id 
            deploymentUnit=deploymentUnit 
            region=region 
            account=account 
            level=level 
        /]
    [#else]
        [@debug
            message="Unable to invoke any of the output macro options"
            context=outputMacroOptions
            enabled=false
        /]
    [/#if]

    [#-- Apply default filters based on provider --]
    [#local filterFunctionOptions = 
        [
            [ provider, "input", commandLineOptions.Input.Source, "stackoutput", "filter" ],
            [ SHARED_PROVIDER, "input", commandLineOptions.Input.Source, "stackoutput", "filter" ]
        ]
    ] 
    
    [#local outputFilter = {
            "Account" : account,
            "Region" : region,
            "DeploymentUnit" : deploymentUnit
    }]

    [#local filterFunction = getFirstDefinedDirective(filterFunctionOptions)]
    [#if filterFunction?has_content ]
        [#local outputFilter = mergeObjects(
                                    (.vars[filterFunction])outputFilter,
                                    outputFilter
                                )]
    [#else]
        [@debug
            message="Unable to invoke any of the function options"
            context=filterFunctionOptions
            enabled=false
        /]
    [/#if]
    [#list stackOutputsList as stackOutputs]
        [#local outputId = stackOutputs[id]?has_content?then(
                id,
                formatId(id, stackOutputs.Region?replace("-", "X"))
            )
        ]

        [#if
            (( !outputFilter.Account?has_content) || (outputFilter.Account == stackOutputs.Account) ) &&
            (( !outputFilter.Region?has_content) || (outputFilter.Region == stackOutputs.Region) ) &&
            (( !outputFilter.DeploymentUnit?has_content) || (outputFilter.DeploymentUnit == stackOutputs.DeploymentUnit)) &&
            (stackOutputs[outputId]?has_content)
        ]
            [#return
                {
                    "Account" : stackOutputs.Account,
                    "Region" : stackOutputs.Region,
                    "Level" : stackOutputs.Level,
                    "DeploymentUnit" : stackOutputs.DeploymentUnit,
                    "Id" : id,
                    "Value" : stackOutputs[outputId]
                }
            ]
        [/#if]
    [/#list]
    [#return {}]
[/#function]

[#function getStackOutput provider id deploymentUnit="" region="" account=""]
    [#local result =
        getStackOutputObject(
            provider,
            id,
            deploymentUnit,
            region,
            account
        )
    ]
    [#return
        result?has_content?then(
            result.Value,
            ""
        )
    ]
[/#function]

[#-------------------------------------------------------
-- Internal support functions for component processing --
---------------------------------------------------------]

[#macro internalMergeStackOutputs data ]
    [#if data?has_content ]
        [#list data as content ]
            [#assign stackOutputsList = 
                combineEntities(
                    stackOutputsList,
                    [ getCompositeObject( stackOutputConfiguration.Attributes, content) ],
                    APPEND_COMBINE_BEHAVIOUR
                )]
        [/#list]
    [/#if]
[/#macro]