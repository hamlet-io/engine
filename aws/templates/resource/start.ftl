[#ftl]

[#macro noResourcesCreated]
    [#assign resourceCount = 0]
[/#macro]

[#macro resourcesCreated count=1]
    [#assign resourceCount += count]
[/#macro]

[#macro checkIfResourcesCreated]
    [#if resourceCount > 0],[/#if]
[/#macro]

[#function cfTemplateCoreTags name="" tier="" component="" zone="" propagate=false]
    [#local result = 
        [
            { "Key" : "cot:request", "Value" : requestReference },
            { "Key" : "cot:configuration", "Value" : configurationReference },
            { "Key" : "cot:tenant", "Value" : tenantId },
            { "Key" : "cot:account", "Value" : accountId },
            { "Key" : "cot:product", "Value" : productId },
            { "Key" : "cot:segment", "Value" : segmentId },
            { "Key" : "cot:environment", "Value" : environmentId },
            { "Key" : "cot:category", "Value" : categoryId }
        ]
    ]
    [#if tier?has_content]
        [#local result += [{ "Key" : "cot:tier", "Value" : getTierId(tier) }]]
    [/#if]
    [#if component?has_content]
        [#local result += [{ "Key" : "cot:component", "Value" : getComponentId(component) }]]
    [/#if]
    [#if zone?has_content]
        [#local result += [{ "Key" : "cot:zone", "Value" : getZoneId(zone) }]]
    [/#if]
    [#if name?has_content]
        [#local result += [{ "Key" : "Name", "Value" : name }]]
    [/#if]
    [#if propagate]
        [#local returnValue = []]
        [#list result as entry]
            [#local returnValue +=
                [
                    entry + {"PropagateAtLaunch" : "True" }
                ]]
        [/#list]
        [#return returnValue]
    [#else]
        [#return result]
    [/#if]
[/#function]

[#macro cfTemplateOutput id value region=""]
    [@checkIfResourcesCreated /]
    "${id +
        region?has_content?then(
            "X" + region?replace("-", "X"),
            "")}" : {
        "Value" : [@toJSON value /]
    }
    [@resourcesCreated /]
[/#macro]

[#macro cfTemplate
            mode
            id 
            type 
            properties={}
            outputs=[{"UseRef" : true}]
            tags=[]
            region=""
            dependencies=[]
            metadata=[]
            deletionPolicy=""]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}": {
                "Type" : "${type}"
                [#if metadata?has_content]
                    ,"Metadata" : [@toJSON metadata /]
                [/#if]
                [#if properties?has_content || tags?has_content]
                    ,"Properties" : {
                        [#list properties as key,value]
                            "${key}" : [@toJSON value /]
                            [#sep],[/#sep]
                        [/#list]
                        [#if tags?has_content]
                            [#if properties?has_content],[/#if]
                            "Tags" : [@toJSON tags /]
                        [/#if]
                    }
                [/#if]
                [#if dependencies?has_content]
                    ,"DependsOn" : [@toJSON dependencies /]
                [/#if]
                [#if deletionPolicy?has_content]
                    ,"DeletionPolicy" : [@toJSON deletionPolicy /]
                [/#if]
            }
            [@resourcesCreated /]        
            [#break]

        [#case "outputs"]
            [#list outputs as output]
                [#assign outputId = (output.AlternateId)!id]
                [#if (output.UseRef)!false]
                    [@cfTemplateOutput 
                        formatAttributeId(outputId, (output.Type)!""),
                        {
                            "Ref" : id
                        },
                        region /]
                    [#if !(output.Type?has_content)]
                        [@cfTemplateOutput 
                            formatDeploymentUnitAttributeId(outputId),
                            deploymentUnit + 
                                deploymentUnitSubset?has_content?then(
                                    "-" + deploymentUnitSubset?lower_case,
                                    ""),
                            region /]
                    [/#if]
                [/#if]
                [#if output.Attribute?has_content]
                    [@cfTemplateOutput
                        formatAttributeId(outputId, (output.Type)!""),
                        {
                            "Fn::GetAtt" : [id, output.Attribute] 
                        },
                        region/]
                [/#if]
            [/#list]
            [#break]

    [/#switch]
[/#macro]