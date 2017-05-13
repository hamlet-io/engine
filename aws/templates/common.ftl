[#ftl]

[#-- Utility functions --]

[#-- Recursively concatenate sequence of non-empty strings with a separator --]
[#function concatenate args separator]
    [#local content = []]
    [#list args as arg]
        [#local argValue = arg]
        [#if argValue?is_sequence]
            [#local argValue = concatenate(argValue, separator)]
        [/#if]
        [#if argValue?is_hash]
            [#switch separator]
                [#case "X"]
                    [#if (argValue.Internal.IdExtensions)??]
                        [#local argValue = concatenate(
                                            argValue.Internal.IdExtensions,
                                            separator)]
                    [#else]
                        [#local argValue = argValue.Id!""]
                    [/#if]
                    [#break]
                [#case "-"]
                    [#if (argValue.Internal.NameExtensions)??]
                        [#local argValue = concatenate(
                                            argValue.Internal.NameExtensions,
                                            separator)]
                    [#else]
                        [#local argValue = argValue.Name!""]
                    [/#if]
                    [#break]
                [#default]
                    [#local argValue = ""]
                    [#break]
            [/#switch]
        [/#if]
        [#if argValue?has_content]
            [#local content += [argValue]]
        [/#if]
    [/#list]
    [#return content?join(separator)]
[/#function]

[#-- Check if a deployment unit occurs anywhere in provided object --]
[#function deploymentRequired obj unit]
    [#if obj?is_hash]
        [#if obj.DeploymentUnits?? && obj.DeploymentUnits?seq_contains(unit)]
            [#return true]
        [#else]
            [#list obj?values as attribute]
                [#if deploymentRequired(attribute unit)]
                    [#return true]
                [/#if]
            [/#list]
        [/#if]
    [/#if]
    [#return false]
[/#function]

[#-- Get stack output --]
[#function getKey args...]
    [#local key = formatId(args)]
    [#list stackOutputsObject as pair]
        [#if pair.OutputKey == key]
            [#return pair.OutputValue]
        [/#if]
    [/#list]
    [#return ""]
[/#function]

[#-- Calculate the closest power of 2 --]
[#function getPowerOf2 value]
    [#local exponent = -1]
    [#list powersOf2 as powerOf2]
        [#if powerOf2 <= value]
            [#local exponent = powerOf2?index]
        [#else]
            [#break]
        [/#if]
    [/#list]
    [#return exponent]
[/#function]

[#-- Tiers --]

[#-- Check if a tier exists --]
[#function isTier tierId]
    [#return (blueprintObject.Tiers[tierId])??]
[/#function]

[#-- Get a tier --]
[#function getTier tierId]
    [#if isTier(tierId)]
        [#return blueprintObject.Tiers[tierId]]
    [/#if]
[/#function]

[#-- Get the id for a tier --]
[#function getTierId tier]
    [#if tier?is_hash]
        [#return tier.Id]
    [#else]
        [#return tier]
    [/#if]
[/#function]

[#-- Get the name for a tier --]
[#function getTierName tier]
    [#return tier.Name]
[/#function]

[#-- Zones --]

[#-- Get the id for a zone --]
[#function getZoneId zone]
    [#if zone?is_hash]
        [#return zone.Id]
    [#else]
        [#return zone]
    [/#if]
[/#function]

[#-- Components --]

[#-- Get the id for a component --]
[#function getComponentId component]
    [#if component?is_hash]
        [#return component.Id?split("-")[0]]
    [#else]
        [#return component?split("-")[0]]
    [/#if]
[/#function]

[#-- Get the name for a component --]
[#function getComponentName component]
    [#return component.Name?split("-")[0]]
[/#function]

[#-- Get the type for a component --]
[#function getComponentType component]
    [#assign idParts = component.Id?split("-")]
    [#if idParts[1]??]
        [#return idParts[1]?lower_case]
    [#else]
        [#list component?keys as key]
            [#switch key]
                [#case "Id"]
                [#case "Name"]
                [#case "Title"]
                [#case "Description"]
                [#case "DeploymentUnits"]
                [#case "MultiAZ"]
                    [#break]

                [#default]
                    [#return key?lower_case]
                    [#break]
            [/#switch]
        [/#list]
    [/#if]
[/#function]

[#-- Get a component within a tier --]
[#function getComponent tierId componentId type=""]
    [#if isTier(tierId)]
        [#list getTier(tierId).Components?values as component]
            [#if component.Id == componentId]
                [#return component]
            [/#if]
            [#if type?has_content &&
                    (getComponentId(component) == componentId) &&
                    (getComponentType(component) == type)]
                [#return component]
            [/#if]
        [/#list]
    [/#if]
[/#function]

[#-- Get processor settings --]
[#function getProcessor tier component type extensions...]
    [#local tc = formatComponentShortName(
                    tier,
                    component,
                    extensions)]
    [#local defaultProfile = "default"]
    [#if (component[type].Processor)??]
        [#return component[type].Processor]
    [/#if]
    [#if (processors[solutionObject.CapacityProfile][tc])??]
        [#return processors[solutionObject.CapacityProfile][tc]]
    [/#if]
    [#if (processors[solutionObject.CapacityProfile][type])??]
        [#return processors[solutionObject.CapacityProfile][type]]
    [/#if]
    [#if (processors[defaultProfile][tc])??]
        [#return processors[defaultProfile][tc]]
    [/#if]
    [#if (processors[defaultProfile][type])??]
        [#return processors[defaultProfile][type]]
    [/#if]
[/#function]

[#-- Get storage settings --]
[#function getStorage tier component type extensions...]
    [#local tc = formatComponentShortName(
                    tier,
                    component,
                    extensions)]
    [#local defaultProfile = "default"]
    [#if (component[type].Storage)??]
        [#return component[type].Storage]
    [/#if]
    [#if (storage[solutionObject.CapacityProfile][tc])??]
        [#return storage[solutionObject.CapacityProfile][tc]]
    [/#if]
    [#if (storage[solutionObject.CapacityProfile][type])??]
        [#return storage[solutionObject.CapacityProfile][type]]
    [/#if]
    [#if (storage[defaultProfile][tc])??]
        [#return storage[defaultProfile][tc]]
    [/#if]
    [#if (storage[defaultProfile][type])??]
        [#return storage[defaultProfile][type]]
    [/#if]
[/#function]

[#-- Utility Macros --]

[#-- Output hash as JSON --]
[#macro toJSON obj]
    [#if obj?is_hash]
    {
        [#local objCount = 0]
        [#list obj as key,value]
            "${key}" : [@toJSON value /]
            [#if objCount > 0],[/#if]
            [#local objCount += 1]
        [/#list]
    }
    [#else]
        [#if obj?is_sequence]
            [
                [#local entryCount = 0]
                [#list obj as entry]
                    [@toJSON entry /]
                    [#if entryCount > 0],[/#if]
                    [#local entryCount += 1]
                [/#list]
            ]
        [#else]
            [#if obj?is_string]
                "${obj}"
            [#else]
                ${obj}
            [/#if]
        [/#if]
    [/#if]
[/#macro]

[#-- Include a reference to a resource in the output --]
[#macro createReference value]
    [#if value?is_hash && value.Ref??]
        { "Ref" : "${value.Ref}" }
    [#else]
        [#if getKey(value)?has_content]
            "${getKey(value)}"
        [#else]
            { "Ref" : "${value}" }
        [/#if]
    [/#if]
[/#macro]

[#-- Outputs generation --]
[#macro output resourceId outputId=""]
    "${outputId?has_content?then(outputId,resourceId)}" : {
        "Value" : { "Ref" : "${resourceId}" }
    }
[/#macro]

[#macro outputAtt outputId resourceId attributeType]
    "${outputId}" : {
        "Value" : { "Fn::GetAtt" : ["${resourceId}", "${attributeType}"] }
    }
[/#macro]

[#macro outputArn resourceId]
    [@outputAtt
        formatArnAttributeId(resourceId)
        resourceId
        "Arn" /]
[/#macro]

[#macro outputElasticSearchArn resourceId]
    [@outputAtt
        formatArnAttributeId(resourceId)
        resourceId
        "DomainArn" /]
[/#macro]

[#macro outputS3Url resourceId]
    [@outputAtt
        formatUrlAttributeId(resourceId)
        resourceId
        "WebsiteURL" /]
[/#macro]

[#macro outputSQSUrl resourceId]
    [@output
        resourceId
        formatUrlAttributeId(resourceId) /]
[/#macro]

[#macro outputLBDns resourceId]
    [@outputAtt
        formatDnsAttributeId(resourceId)
        resourceId
        "DNSName" /]
[/#macro]

[#macro outputElasticSearchUrl resourceId]
    [@outputAtt
        formatDnsAttributeId(resourceId)
        resourceId
        "DomainEndpoint" /]
[/#macro]

[#macro outputSQS resourceId]
    [@outputAtt
        resourceId
        resourceId
        "QueueName" /]
[/#macro]

[#macro outputIPAddress resourceId]
    [@output
        resourceId
        formatIPAddressAttributeId(resourceId) /]
[/#macro]

[#macro outputAllocation resourceId]
    [@outputAtt
        formatAllocationAttributeId(resourceId)
        resourceId
        "AllocationId" /]
[/#macro]

[#macro outputRoot resourceId]
    [@outputAtt
        formatRootAttributeId(resourceId)
        resourceId
        "RootResourceId" /]
[/#macro]


[#macro createSecurityGroup mode tier component id name description=""]
    [#if resourceCount > 0],[/#if]
    [#switch mode]
        [#case "definition"]
            "${id}" : {
                "Type" : "AWS::EC2::SecurityGroup",
                "Properties" : {
                    "GroupDescription": "${description?has_content?then(description, name)}",
                    "VpcId": "${vpc}",
                    "Tags" : [
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" },
                        { "Key" : "cot:tier", "Value" : "${getTierId(tier)}" },
                        { "Key" : "cot:component", "Value" : "${getComponentId(component)}" },
                        { "Key" : "Name", "Value" : "${name}" }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            [@output id /]
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#macro]

[#macro createDependentSecurityGroup mode tier component resourceId resourceName]
    [@createSecurityGroup 
        mode 
        tier 
        component
        formatDependentSecurityGroupId(resourceId)
        resourceName
        "Security Group for " + resourceName /]
[/#macro]

[#macro createComponentSecurityGroup mode tier component idExtension="" nameExtension=""]
    [@createSecurityGroup 
        mode 
        tier 
        component
        formatComponentSecurityGroupId(
            tier,
            component,
            idExtension)
        formatComponentFullName(
            tier,
            component,
            nameExtension) /]
[/#macro]

[#macro createTargetGroup tier component source destination name]
    "${formatALBTargetGroupId(tier, component, source, name)}" : {
        "Type" : "AWS::ElasticLoadBalancingV2::TargetGroup",
        "Properties" : {
            "HealthCheckPort" : "${(destination.HealthCheck.Port)!"traffic-port"}",
            "HealthCheckProtocol" : "${(destination.HealthCheck.Protocol)!destination.Protocol}",
            "HealthCheckPath" : "${destination.HealthCheck.Path}",
            "HealthCheckIntervalSeconds" : ${destination.HealthCheck.Interval},
            "HealthCheckTimeoutSeconds" : ${destination.HealthCheck.Timeout},
            "HealthyThresholdCount" : ${destination.HealthCheck.HealthyThreshold},
            "UnhealthyThresholdCount" : ${destination.HealthCheck.UnhealthyThreshold},
            [#if (destination.HealthCheck.SuccessCodes)?? ]
                "Matcher" : { "HttpCode" : "${destination.HealthCheck.SuccessCodes}" },
            [/#if]
            "Port" : ${destination.Port?c},
            "Protocol" : "${destination.Protocol}",
            "Tags" : [
                { "Key" : "cot:request", "Value" : "${requestReference}" },
                { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                { "Key" : "cot:account", "Value" : "${accountId}" },
                { "Key" : "cot:product", "Value" : "${productId}" },
                { "Key" : "cot:segment", "Value" : "${segmentId}" },
                { "Key" : "cot:environment", "Value" : "${environmentId}" },
                { "Key" : "cot:category", "Value" : "${categoryId}" },
                { "Key" : "cot:tier", "Value" : "${getTierId(tier)}" },
                { "Key" : "cot:component", "Value" : "${getComponentId(component)}" },
                { "Key" : "Name", "Value" : "${formatComponentFullName(
                                                tier, 
                                                component, 
                                                source.Port?c, 
                                                name)}" }
            ],
            "VpcId": "${vpc}",
            "TargetGroupAttributes" : [
                {
                    "Key" : "deregistration_delay.timeout_seconds",
                    "Value" : "${(destination.DeregistrationDelay)!30}"
                }
            ]
        }
    }
[/#macro]



