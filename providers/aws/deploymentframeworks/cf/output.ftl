[#ftl]

[#assign AWS_OUTPUT_RESOURCE_TYPE = "resource" ]

[#function getCFTemplateCoreOutputs region={ "Ref" : "AWS::Region" } account={ "Ref" : "AWS::AccountId" } deploymentUnit=deploymentUnit deploymentMode=deploymentMode ]
    [#return {
        "Account" :{ "Value" : account },
        "Region" : {"Value" : region },
        "DeploymentUnit" : {
            "Value" :
                deploymentUnit +
                (
                    (!(ignoreDeploymentUnitSubsetInOutputs!false)) &&
                    (deploymentUnitSubset?has_content)
                )?then(
                    "-" + deploymentUnitSubset?lower_case,
                    ""
                )
        },
        "DeploymentMode" : { "Value" : deploymentMode }
    }]
[/#function]

[#function getCfTemplateCoreTags name="" tier="" component="" zone="" propagate=false flatten=false maxTagCount=-1]
    [#local result =
        [
            { "Key" : "cot:request", "Value" : requestReference }
        ] +
        accountObject.CostCentre?has_content?then(
            [
                { "Key" : "cot:costcentre", "Value" : accountObject.CostCentre }
            ],
            []
        ) +
        [
            { "Key" : "cot:configuration", "Value" : configurationReference },
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
            mode
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

    [@addToJsonOutput
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

[#macro cfConfig mode content={} ]
    [@addToDefaultJsonOutput content=content /]
[/#macro]

[#macro cfCli mode id command content={} ]
    [@addCliToDefaultJsonOutput
        id=id
        command=command
        content=content
    /]
[/#macro]

[#macro cfScript mode content=[] ]
    [@addToDefaultBashOutput lines=content /]
[/#macro]

[#macro cfDebug mode value enabled=true]
    [@debug message=value enabled=enabled /]
[/#macro]

[#macro cfException mode description context={} detail="" ]
    [@fatal
        message=description
        context=
            valueIfContent(
                {
                    "Context" : context,
                    "Detail" : detail
                },
                detail,
                context
            )
        enabled=true
    /]
[/#macro]

[#macro cfPreconditionFailed
            mode
            function
            context={}
            description=""]

    [@cfException
        mode=mode
        description=function + " precondition failed"
        context=context
        detail=description
    /]
[/#macro]

[#macro cfPostconditionFailed
            mode
            function
            context={}
            description=""]

    [@cfException
        mode=mode
        description=function + " postcondition failed"
        context=context
        detail=description
    /]
[/#macro]

[#macro cf_output_resource level="" include=""]

    [#-- Initialise outputs --]
    [@initialiseJsonOutput "resources" /]
    [@initialiseJsonOutput "outputs" /]

    [#-- Resources --]
    [#if include?has_content]
        [#include include?ensure_starts_with("/")]
    [#else]
        [@processComponents level /]
    [/#if]

    [#if getOutput("resources")?has_content || logMessages?has_content]
        [@toJSON
            {
                "AWSTemplateFormatVersion" : "2010-09-09",
                "Metadata" :
                    {
                        "Prepared" : .now?iso_utc,
                        "RequestReference" : requestReference,
                        "ConfigurationReference" : configurationReference,
                        "RunId" : runId
                    } +
                    attributeIfContent("CostCentre", accountObject.CostCentre!""),
                "Resources" : getOutput("resources"),
                "Outputs" :
                    getOutput("outputs") +
                    getCFTemplateCoreOutputs()
            } +
            attributeIfContent("COTMessages", logMessages)
        /]
    [/#if]
[/#macro]
