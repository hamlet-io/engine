[#ftl]

[#function getCFTemplateCoreOutputs region={ "Ref" : "AWS::Region" } account={ "Ref" : "AWS::AccountId" } deploymentUnit=getDeploymentUnit() deploymentMode=commandLineOptions.Deployment.Mode ]
    [#return {
        "Account" :{ "Value" : account },
        "Region" : {"Value" : region },
        "DeploymentUnit" : {
            "Value" :
                deploymentUnit +
                (
                    (!(ignoreDeploymentUnitSubsetInOutputs!false)) &&
                    (commandLineOptions.Deployment.Unit.Subset?has_content)
                )?then(
                    "-" + commandLineOptions.Deployment.Unit.Subset?lower_case,
                    ""
                )
        },
        "DeploymentMode" : { "Value" : deploymentMode }
    }]
[/#function]

[#function getCfTemplateCoreTags name="" tier="" component="" zone="" propagate=false flatten=false maxTagCount=-1]
    [#local result =
        [
            { "Key" : "cot:request", "Value" : commandLineOptions.References.Request }
        ] +
        accountObject.CostCentre?has_content?then(
            [
                { "Key" : "cot:costcentre", "Value" : accountObject.CostCentre }
            ],
            []
        ) +
        [
            { "Key" : "cot:configuration", "Value" : commandLineOptions.References.Configuration },
            { "Key" : "cot:tenant", "Value" : tenantName },
            { "Key" : "cot:account", "Value" : accountName }
        ] +
        productId?has_content?then(
            [
                { "Key" : "cot:product", "Value" : productName }
            ],
            []
        ) +
        environmentId?has_content?then(
            [
                { "Key" : "cot:environment", "Value" : environmentName }
            ],
            []
        ) +
        [
            { "Key" : "cot:category", "Value" : categoryName }
        ] +
        segmentId?has_content?then(
            [
                { "Key" : "cot:segment", "Value" : segmentName }
            ],
            []
        ) +
        tier?has_content?then(
            [
                { "Key" : "cot:tier", "Value" : getTierName(tier) }
            ],
            []
        ) +
        component?has_content?then(
            [
                { "Key" : "cot:component", "Value" : getComponentName(component) }
            ],
            []
        ) +
        zone?has_content?then(
            [
                { "Key" : "cot:zone", "Value" : getZoneName(zone) }
            ],
            []
        ) +
        name?has_content?then(
            [
                { "Key" : "Name", "Value" : name }
            ],
            []
        )
    ]
    [#if propagate]
        [#local returnValue = []]
        [#list result as entry]
            [#local returnValue +=
                [
                    entry + {"PropagateAtLaunch" : "True" }
                ]
            ]
        [/#list]
        [#local result=returnValue]
    [/#if]
    [#if flatten ]
        [#local returnValue = {} ]
        [#list result as entry ]
            [#local returnValue +=
                {
                    entry.Key, entry.Value
                }
            ]
        [/#list]
        [#local result=returnValue]
    [/#if]

    [#if maxTagCount gte 0 ]
        [#local maxTagCount = ( maxTagCount -1 lt result?size )?then(
                                    maxTagCount,
                                    result?size
        )]
        [#local result=result[0..( maxTagCount -1 )]]
    [/#if]
    [#return result]
[/#function]

[#function getCfTemplateDefaultOutputs]
    [#return
        {
            REFERENCE_ATTRIBUTE_TYPE : {
                "UseRef" : true
            }
        }
    ]
[/#function]

[#macro cfOutput id value ]
    [@mergeWithJsonOutput
        name="outputs"
        content=
            {
                id : { "Value" : value }
            }
    /]
[/#macro]

[#macro cfResource
            id
            type
            properties={}
            tags=[]
            outputs=getCfTemplateDefaultOutputs()
            outputId=""
            dependencies=[]
            metadata={}
            deletionPolicy=""
            updateReplacePolicy=""
            updatePolicy={}
            creationPolicy={}]

    [#local localDependencies = [] ]
    [#list asArray(dependencies) as resourceId]
        [#if getReference(resourceId)?is_hash]
            [#local localDependencies += [resourceId] ]
        [/#if]
    [/#list]

    [@mergeWithJsonOutput
        name="resources"
        content=
            {
                id :
                    {
                        "Type" : type
                    } +
                    attributeIfContent("Metadata", metadata) +
                    attributeIfTrue(
                        "Properties",
                        properties?has_content || tags?has_content,
                        properties + attributeIfContent("Tags", tags)) +
                    attributeIfContent("DependsOn", localDependencies) +
                    attributeIfContent("DeletionPolicy", deletionPolicy) +
                    attributeIfContent("UpdateReplacePolicy", updateReplacePolicy) +
                    attributeIfContent("UpdatePolicy", updatePolicy) +
                    attributeIfContent("CreationPolicy", creationPolicy)
            }
    /]

    [#assign oId = outputId?has_content?then(outputId, id)]
    [#list outputs as type,value]
        [#if type == REFERENCE_ATTRIBUTE_TYPE]
            [@cfOutput
                oId,
                {
                    "Ref" : id
                }
            /]
        [#else]
            [@cfOutput
                formatAttributeId(oId, type),
                ((value.UseRef)!false)?then(
                    {
                        "Ref" : id
                    },
                    value.Value?has_content?then(
                        value.Value,
                        {
                            "Fn::GetAtt" : [id, value.Attribute]
                        }
                    )
                )
            /]
        [/#if]
    [/#list]
[/#macro]

[#macro cf_output_resource level="" include=""]
    [#-- Resources --]
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@processComponents level /]
    [/#if]

    [#if getOutputContent("resources")?has_content || logMessages?has_content]
        [@toJSON
            {
                "AWSTemplateFormatVersion" : "2010-09-09",
                "Metadata" :
                    {
                        "Prepared" : .now?iso_utc,
                        "RequestReference" : commandLineOptions.References.Request,
                        "ConfigurationReference" : commandLineOptions.References.Configuration,
                        "RunId" : commandLineOptions.Run.Id
                    } +
                    attributeIfContent("CostCentre", accountObject.CostCentre!""),
                "Resources" : getOutputContent("resources"),
                "Outputs" :
                    getOutputContent("outputs") +
                    getCFTemplateCoreOutputs()
            } +
            attributeIfContent("COTMessages", logMessages)
        /]
    [/#if]
[/#macro]


[#-- Initialise the possible outputs to make sure they are available to all steps --]
[@initialiseJsonOutput name="resources" /]
[@initialiseJsonOutput name="outputs" /]

[#assign AWS_OUTPUT_RESOURCE_TYPE = "resource" ]

[#-- Add Output Step mappings for each output --]

[@addGenerationContractStepOutputMapping
    provider=AWS_PROVIDER
    subset="template"
    outputType=AWS_OUTPUT_RESOURCE_TYPE
    outputFormat=""
    outputSuffix="template.json"
/]
