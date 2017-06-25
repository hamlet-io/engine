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
                [#case "/"]
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

[#function deploymentSubsetRequired subset]
    [#return 
        deploymentUnitSubset?has_content &&
        deploymentUnitSubset?lower_case?contains(subset)]
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

[#-- S3 config/credentials/appdata storage  --]

[#function getCredentialsFilePrefix]
    [#return formatSegmentPrefixPath(
            "credentials",
            (appSettingsObject.FilePrefixes.Credentials)!
                (appSettingsObject.DefaultFilePrefix)!
                deploymentUnit)]
[/#function]

[#function getAppSettingsFilePrefix]
    [#return formatSegmentPrefixPath(
            "appsettings",
            (appSettingsObject.FilePrefixes.AppSettings)!
                (appSettingsObject.DefaultFilePrefix)!
                deploymentUnit)]
[/#function]

[#function getAppDataFilePrefix]
    [#return formatSegmentPrefixPath(
            "appdata",
            (appSettingsObject.FilePrefixes.AppData)!
                (appSettingsObject.DefaultFilePrefix)!
                deploymentUnit)]
[/#function]

[#function getBackupsFilePrefix]
    [#return formatSegmentPrefixPath(
            "backups",
            (appSettingsObject.FilePrefixes.Backups)!
                (appSettingsObject.DefaultFilePrefix)!
                deploymentUnit)]
[/#function]

[#function getSegmentCredentialsFilePrefix]
    [#return formatSegmentPrefixPath("credentials")]
[/#function]

[#function getSegmentAppSettingsFilePrefix]
    [#return formatSegmentPrefixPath("appsettings")]
[/#function]

[#function getSegmentAppDataFilePrefix]
    [#return formatSegmentPrefixPath("appdata")]
[/#function]

[#function getSegmentBackupsFilePrefix]
    [#return formatSegmentPrefixPath("backups")]
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

[#-- Is a resource part of a deployment unit --]
[#function isPartOfDeploymentUnit id deploymentUnit]
    [#local resourceValue = getKey(id)]
    [#local creatingDeploymentUnit = getKey(formatDeploymentUnitAttributeId(id))]
    [#local currentDeploymentUnit = 
                deploymentUnit +
                deploymentUnitSubset?has_content?then(
                    "-" + deploymentUnitSubset?lower_case,
                    "")]
    [#return !(resourceValue?has_content &&
                creatingDeploymentUnit?has_content &&
                creatingDeploymentUnit != currentDeploymentUnit)]
[/#function]

[#-- Is a resource part of the current deployment unit --]
[#function isPartOfCurrentDeploymentUnit id]
    [#return isPartOfDeploymentUnit(id, deploymentUnit)]
[/#function]

[#-- Utility Macros --]

[#-- Output hash as JSON --]
[#macro toJSON obj]
    [#if obj?is_hash]
    {
        [#list obj as key,value]
            "${key}" : [@toJSON value /]
            [#sep],[/#sep]
        [/#list]
    }
    [#else]
        [#if obj?is_sequence]
            [
                [#list obj as entry]
                    [@toJSON entry /]
                    [#sep],[/#sep]
                [/#list]
            ]
        [#else]
            [#if obj?is_string]
                "${obj}"
            [#else]
                ${obj?c}
            [/#if]
        [/#if]
    [/#if]
[/#macro]

[#-- Include a reference to a resource --]
[#-- Allows resources to share a template or be separated --]
[#-- Note that if separate, creation order becomes important --]
[#macro createReference value]
    [#if isPartOfCurrentDeploymentUnit(value)]
        { "Ref" : "${value}" }
    [#else]
        "${getKey(value)}"
    [/#if]
[/#macro]

[#macro createArnReference resourceId]
    [#if isPartOfCurrentDeploymentUnit(resourceId)]
        { "Fn::GetAtt" : ["${resourceId}", "Arn"] }
    [#else]
        "${getKey(formatArnAttributeId(resourceId))}"
    [/#if]
[/#macro]

[#macro noResourcesCreated]
    [#assign resourceCount = 0]
[/#macro]

[#macro resourcesCreated count=1]
    [#assign resourceCount += count]
[/#macro]

[#macro checkIfResourcesCreated]
    [#if resourceCount > 0],[/#if]
[/#macro]

[#-- Outputs generation --]
[#macro output resourceId outputId=""]
    [@checkIfResourcesCreated /]
    "${outputId?has_content?then(outputId,resourceId)}" : {
        "Value" : { "Ref" : "${resourceId}" }
    },
    [#-- Remember under which deployment unit this resource was created --]
    "${formatDeploymentUnitAttributeId(
        outputId?has_content?then(outputId,resourceId))}" : {
        "Value" : "${deploymentUnit + 
                        deploymentUnitSubset?has_content?then(
                            "-" + deploymentUnitSubset?lower_case,
                            "")}"
    }
    [@resourcesCreated /]
[/#macro]

[#macro outputAtt outputId resourceId attributeType]
    [@checkIfResourcesCreated /]
    "${outputId}" : {
        "Value" : { "Fn::GetAtt" : ["${resourceId}", "${attributeType}"] }
    }
    [@resourcesCreated /]
[/#macro]

[#macro outputValue outputId value]
    [@checkIfResourcesCreated /]
    "${outputId}" : {
        "Value" : "${value}"
    }
    [@resourcesCreated /]
[/#macro]

[#macro outputArn resourceId]
    [@outputAtt
        formatArnAttributeId(resourceId)
        resourceId
        "Arn" /]
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

[#macro outputCFDns resourceId]
    [@outputAtt
        formatDnsAttributeId(resourceId)
        resourceId
        "DomainName" /]
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
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
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
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [#break]

    [/#switch]
[/#macro]

[#macro createDependentSecurityGroup
            mode
            tier
            component
            resourceId
            resourceName]
    [@createSecurityGroup 
        mode 
        tier 
        component
        formatDependentSecurityGroupId(resourceId)
        resourceName
        "Security Group for " + resourceName /]
[/#macro]

[#macro createComponentSecurityGroup
            mode
            tier
            component
            idExtension=""
            nameExtension=""]
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

[#macro createDependentComponentSecurityGroup
            mode
            tier
            component
            resourceId
            resourceName
            idExtension=""
            nameExtension=""]
    [#local legacyId = formatComponentSecurityGroupId(
                        tier,
                        component,
                        idExtension)]
    [#if getKey(legacyId)?has_content]
        [@createComponentSecurityGroup 
            mode 
            tier 
            component
            idExtension
            nameExtension /]
    [#else]
        [@createDependentSecurityGroup 
            mode 
            tier 
            component
            resourceId
            resourceName /]
    [/#if]
[/#macro]

[#macro createTargetGroup mode tier component source destination name]
    [#local targetGroupId = formatALBTargetGroupId(tier, component, source, name)]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${targetGroupId}" : {
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
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output targetGroupId /]
            [#break]

    [/#switch]
[/#macro]

[#macro createLogGroup mode id name retention=0]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::Logs::LogGroup",
                "Properties" : {
                    "LogGroupName" : "${name}"
                    [#if retention > 0]
                        ,"RetentionInDays" : ${retention}
                    [#else]
                        [#if operationsExpiration?is_number]
                            ,"RetentionInDays" : ${operationsExpiration}
                        [/#if]
                    [/#if]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [@outputArn id /]
            [#break]

    [/#switch]
[/#macro]

[#macro createWAFIPSet mode id name cidr]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::WAF::IPSet",
                "Properties" : {
                    "Name": "${name}",
                    "IPSetDescriptors": [
                        [#list cidr as entry]
                            {
                                "Type" : "IPV4",
                                "Value" : "${entry}"
                            }
                            [#sep],[/#sep]
                        [/#list]
                    ]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [#break]

    [/#switch]
[/#macro]

[#macro createWAFRule mode id name metric conditions]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::WAF::Rule",
                "Properties" : {
                    "MetricName" : "${metric?replace("-","X")}",
                    "Name": "${name}",
                    "Predicates" : [
                        [#list conditions as condition]
                            {
                              "DataId" : [@createReference condition.Id /],
                              "Negated" : ${(condition.Negate?has_content &&
                                            condition.Negate)?c},
                              "Type" : "${condition.Type}"
                            }
                            [#sep],[/#sep]
                        [/#list]
                    ]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [#break]

    [/#switch]
[/#macro]

[#macro createWAFAcl mode id name metric default rules]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::WAF::WebACL",
                "Properties" : {
                    "DefaultAction" : {
                        "Type" : "${default}"
                    },
                    "MetricName" : "${metric?replace("-","X")}",
                    "Name": "${name}",
                    "Rules" : [
                        [#list rules as rule]
                            {
                              "RuleId" : [@createReference rule.Id /],
                              "Priority" : ${rule?counter?c},
                              "Action" : {
                                  "Type" : "${rule.Action}"
                              }
                            }
                            [#sep],[/#sep]
                        [/#list]
                    ]
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [#break]

    [/#switch]
[/#macro]

