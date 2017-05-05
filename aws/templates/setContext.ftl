[#ftl]
[#-- Standard inputs --]
[#assign blueprintObject = blueprint?eval]
[#assign credentialsObject = (credentials?eval).Credentials]                    
[#assign appSettingsObject = appsettings?eval]
[#assign stackOutputsObject = stackOutputs?eval]

[#-- Reference data --]
[#assign regions = blueprintObject.Regions]
[#assign environments = blueprintObject.Environments]
[#assign categories = blueprintObject.Categories]
[#assign routeTables = blueprintObject.RouteTables]
[#assign networkACLs = blueprintObject.NetworkACLs]
[#assign storage = blueprintObject.Storage]
[#assign processors = blueprintObject.Processors]
[#assign ports = blueprintObject.Ports]
[#assign portMappings = blueprintObject.PortMappings]
[#assign powersOf2 = blueprintObject.PowersOf2]

[#-- Region --]
[#if region??]
    [#assign regionId = region]
    [#assign regionObject = regions[regionId]]
    [#assign regionName = regionObject.Name]
[/#if]

[#-- Tenant --]
[#if blueprintObject.Tenant??]
    [#assign tenantObject = blueprintObject.Tenant]
    [#assign tenantId = tenantObject.Id]
    [#assign tenantName = tenantObject.Name]
[/#if]

[#-- Account --]
[#if blueprintObject.Account??]
    [#assign accountObject = blueprintObject.Account]
    [#assign accountId = accountObject.Id]
    [#assign accountName = accountObject.Name]
    [#if accountRegion??]
        [#assign accountRegionId = accountRegion]
        [#assign accountRegionObject = regions[accountRegionId]]
        [#assign accountRegionName = accountRegionObject.Name]
    [/#if]
    [#assign credentialsBucket = getKey("s3","account", "credentials")]
    [#assign codeBucket = getKey("s3","account","code")]
    [#assign registryBucket = getKey("s3", "account", "registry")]
[/#if]

[#-- Product --]
[#if blueprintObject.Product??]
    [#assign productObject = blueprintObject.Product]
    [#assign productId = productObject.Id]
    [#assign productName = productObject.Name]
    [#if productRegion??]
        [#assign productRegionId = productRegion]
        [#assign productRegionObject = regions[productRegionId]]
        [#assign productRegionName = productRegionObject.Name]
    [/#if]
[/#if]

[#-- Segment --]
[#if blueprintObject.Segment??]
    [#assign segmentObject = blueprintObject.Segment]
    [#assign segmentId = segmentObject.Id]
    [#assign segmentName = segmentObject.Name]
    [#assign sshPerSegment = segmentObject.SSHPerSegment]
    [#assign internetAccess = segmentObject.InternetAccess]
    [#assign jumpServer = internetAccess && segmentObject.NAT.Enabled]
    [#assign jumpServerPerAZ = jumpServer && segmentObject.NAT.MultiAZ]
    [#assign operationsBucket = "unknown"]
    [#assign operationsBucketSegment = "segment"]
    [#assign operationsBucketType = "ops"]
    [#if getKey(formatSegmentS3ResourceId("ops"))?has_content]
        [#assign operationsBucket = getKey(formatSegmentS3ResourceId("ops"))]        
    [/#if]
    [#if getKey(formatSegmentS3ResourceId("operations"))?has_content]
        [#assign operationsBucket = getKey(formatSegmentS3ResourceId("operations"))]        
    [/#if]
    [#if getKey(formatSegmentS3ResourceId("logs"))?has_content]
        [#assign operationsBucket = getKey(formatSegmentS3ResourceId("logs"))]        
        [#assign operationsBucketType = "logs"]
    [/#if]
    [#if getKey(formatContainerS3ResourceId("logs"))?has_content]
        [#assign operationsBucket = getKey(formatContainerS3ResourceId("logs"))]        
        [#assign operationsBucketSegment = "container"]
        [#assign operationsBucketType = "logs"]
    [/#if]
    [#assign dataBucket = "unknown"]
    [#assign dataBucketSegment = "segment"]
    [#assign dataBucketType = "data"]
    [#if getKey(formatSegmentS3ResourceId("data"))?has_content]
        [#assign dataBucket = getKey(formatSegmentS3ResourceId("data"))]        
    [/#if]
    [#if getKey(formatSegmentS3ResourceId("backups"))?has_content]
        [#assign dataBucket = getKey(formatSegmentS3ResourceId("backups"))]        
        [#assign dataBucketType = "backups"]
    [/#if]
    [#if getKey(formatContainerS3ResourceId("backups"))?has_content]
        [#assign dataBucket = getKey(formatContainerS3ResourceId("backups"))]        
        [#assign dataBucketSegment = "container"]
        [#assign dataBucketType = "backups"]
    [/#if]
    [#assign segmentDomain = getKey("domain", "segment", "domain")]
    [#assign segmentDomainQualifier = getKey("domain", "segment", "qualifier")]
    [#assign certificateId = getKey("domain", "segment", "certificate")]
    [#assign vpc = getKey("vpc", "segment", "vpc")]
    [#assign securityGroupNAT = getKey("securityGroup", "mgmt", "nat")]
    [#if segmentObject.Environment??]
        [#assign environmentId = segmentObject.Environment]
        [#assign environmentObject = environments[environmentId]]
        [#assign environmentName = environmentObject.Name]
        [#assign categoryId = segmentObject.Category!environmentObject.Category]
        [#assign categoryObject = categories[categoryId]]
    [/#if]
[/#if]

[#-- Solution --]
[#if blueprintObject.Solution??]
    [#assign solutionObject = blueprintObject.Solution]
    [#assign solnMultiAZ = solutionObject.MultiAZ!(environmentObject.MultiAZ)!false]
[/#if]

[#-- Recursively concatenate sequence of non-empty strings with a separator --]
[#function concatenate args separator]
    [#local content = []]
    [#list args as arg]
        [#local argValue = arg]
        [#if argValue?is_sequence]
            [#local argValue = concatenate(argValue, separator)]
        [/#if]
        [#if argValue?has_content]
            [#local content += [argValue]]
        [/#if]
    [/#list]
    [#return content?join(separator)]
[/#function]

[#-- Format an id - largely used for resource ids which have severe character constraints --]
[#function formatId ids...]
    [#return concatenate(ids, "X")]
[/#function]

[#function formatIdExtension extensions...]
    [#return formatId(extensions)]
[/#function]

[#-- Format a name - largely used for names that appear in the AWS console --]
[#function formatName names...]
    [#return concatenate(names, "-")]
[/#function]

[#function formatNameExtension extensions...]
    [#return formatName(extensions)]
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

[#-- Get the id for a zone --]
[#function getZoneId zone]
    [#if zone?is_hash]
        [#return zone.Id]
    [#else]
        [#return zone]
    [/#if]
[/#function]

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

[#-- Format a component id stem --]
[#function formatComponentIdStem tier component extensions...]
    [#return formatId(
                getTierId(tier),
                getComponentId(component),
                extensions)]
[/#function]

[#-- Format a component short name stem --]
[#function formatComponentShortNameStem tier component extensions...]
    [#return formatName(
                getTierId(tier),
                getComponentId(component),
                extensions)]
[/#function]

[#-- Format a component name stem --]
[#function formatComponentNameStem tier component extensions...]
    [#return formatName(
                getTierName(tier),
                getComponentName(component),
                extensions)]
[/#function]

[#-- Format a component "short" full name stem --]
[#function formatComponentShortFullNameStem tier component extensions...]
    [#return formatName(
                productId,
                segmentId,
                getTierName(tier),
                getComponentName(component),
                extensions)]
[/#function]

[#-- Format a component full name stem --]
[#function formatComponentFullNameStem tier component extensions...]
    [#return formatName(
                productName,
                segmentName,
                getTierName(tier),
                getComponentName(component),
                extensions)]
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

[#-- Required tiers --]
[#assign tiers = []]
[#list segmentObject.Tiers.Order as tierId]
    [#if isTier(tierId)]
        [#assign tier = getTier(tierId)]
        [#if tier.Components??
            || ((tier.Required)?? && tier.Required)
            || (jumpServer && (tierId == "mgmt"))]
            [#assign tiers += [tier + 
                {"Index" : tierId?index}]]
        [/#if]
    [/#if]
[/#list]

[#-- Required zones --]
[#assign zones = []]
[#list segmentObject.Zones.Order as zoneId]
    [#if regions[region].Zones[zoneId]??]
        [#assign zone = regions[region].Zones[zoneId]]
        [#assign zones += [zone +  
            {"Index" : zoneId?index}]]
    [/#if]
[/#list]

[#-- Get processor settings --]
[#function getProcessor tier component type]
    [#local tc = formatComponentShortNameStem(tier, component)]
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
[#function getStorage tier component type]
    [#local tc = formatComponentShortNameStem(tier, component)]
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

[#-- Resource id formatting routines --]

[#function formatResourceId type ids...]
    [#return formatId(
                type,
                ids)]
[/#function]

[#-- TODO: Remove when use of "container" is removed --]
[#function formatContainerResourceId type extensions...]
    [#return formatResourceId(
                type,
                "container",
                extensions)]
[/#function]

[#function formatSegmentResourceId type extensions...]
    [#return formatResourceId(
                type,
                "segment",
                extensions)]
[/#function]

[#function formatZoneResourceId type tier zone extensions...]
    [#return formatResourceId(
                type,
                getTierId(tier),
                getZoneId(zone),
                extensions)]
[/#function]

[#function formatComponentResourceId type tier component extensions...]
    [#return formatResourceId(
                type,
                formatComponentIdStem(
                    tier, 
                    component,
                    extensions))]
[/#function]


[#-- Resource attribute id formatting routines --]

[#function formatResourceAttributeId resourceId attribute]
    [#return formatId(
                resourceId,
                attribute)]
[/#function]

[#function formatResourceArnAttributeId resourceId]
    [#return formatResourceAttributeId(
                resourceId,
                "arn")]
[/#function]

[#function formatResourceUrlAttributeId resourceId]
    [#return formatResourceAttributeId(
                resourceId,
                "url")]
[/#function]

[#function formatResourceDnsAttributeId resourceId]
    [#return formatResourceAttributeId(
                resourceId,
                "dns")]
[/#function]

[#function formatResourceIPAddressAttributeId resourceId]
    [#return formatResourceAttributeId(
                resourceId,
                "ip")]
[/#function]

[#function formatResourceAllocationIdAttributeId resourceId]
    [#return formatResourceAttributeId(
                resourceId,
                "id")]
[/#function]

[#-- Certificate resources --]

[#function formatCertificateResourceId ids...]
    [#return formatResourceId(
                "certificate",
                ids)]
[/#function]

[#function formatComponentCertificateResourceId tier component extensions...]
    [#return formatCertificateResourceId(
                formatComponentIdStem(   
                    tier,
                    component,
                    extensions))]
[/#function]

[#-- Policy resources --]

[#function formatPolicyResourceId ids...]
    [#return formatResourceId(
                "policy",
                ids)]
[/#function]

[#function formatComponentPolicyResourceId tier component extensions...]
    [#return formatPolicyResourceId(
                formatComponentIdStem(   
                    tier,
                    component,
                    extensions))]
[/#function]

[#-- Role resources --]

[#function formatRoleResourceId ids...]
    [#return formatResourceId(
                "role",
                ids)]
[/#function]

[#function formatSubRoleResourceId subRole ids...]
    [#return formatRoleResourceId(
                ids,
                subRole)]
[/#function]

[#function formatComponentRoleResourceId tier component extensions...]
    [#return formatRoleResourceId(
                formatComponentIdStem(   
                    tier,
                    component,
                    extensions))]
[/#function]

[#function formatComponentSubRoleResourceId tier component subRole extensions...]
    [#return formatSubRoleResourceId(
                subRole,
                formatComponentIdStem(
                    tier,
                    component,
                    extensions))]
[/#function]

[#-- Security Group resources --]

[#function formatSecurityGroupResourceId ids...]
    [#return formatResourceId(
                "securityGroup",
                ids)]
[/#function]

[#function formatComponentSecurityGroupResourceId tier component extensions...]
    [#-- Lookup somewhat convoluted to allow for possibility of ids for tier and component --]
    [#local componentType = getComponentType(component)]

    [#-- Add a suffix to the type to ensure uniqueness when more than one component --]
    [#-- in a tier sharing the same componentId (but having a different type --]
    [#return formatSecurityGroupResourceId(
                (componentType == "lambda")?then(componentType, ""),
                formatComponentIdStem(
                    tier,
                    component,
                    extensions))]
[/#function]

[#macro createSecurityGroup mode tier component idExtension="" nameExtension=""]
    [#if resourceCount > 0],[/#if]
    [#switch mode]
        [#case "definition"]
            [#assign securityGroupResourceId = formatComponentSecurityGroupResourceId(
                                                tier,
                                                component,
                                                idExtension)]
            [#assign securityGroupName = formatComponentFullNameStem(
                                            tier,
                                            component,
                                            nameExtension)]
            "${securityGroupResourceId}" : {
                "Type" : "AWS::EC2::SecurityGroup",
                "Properties" : {
                    "GroupDescription": "${securityGroupName}",
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
                        { "Key" : "Name", "Value" : "${securityGroupName}" }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            "${securityGroupResourceId}" : {
                "Value" : { "Ref" : "${securityGroupResourceId}" }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#macro]

[#function formatSecurityGroupIngressResourceId ids...]
    [#return formatResourceId(
                "securityGroupIngress",
                ids)]
[/#function]

[#function formatComponentSecurityGroupIngressResourceId tier component extensions...]
    [#return formatSecurityGroupIngressResourceId(
                formatComponentIdStem(   
                    tier,
                    component,
                    extensions))]
[/#function]

[#-- ELB resources --]

[#function formatELBResourceId tier component]
    [#return formatComponentResourceId(
                "elb",
                tier,
                component)]
[/#function]

[#-- ALB resources --]

[#function formatALBResourceId tier component extensions...]
    [#return formatComponentResourceId(
                "alb",
                tier,
                component,
                extensions)]
[/#function]

[#function formatALBResourceDNSId tier component extensions...]
    [#return formatResourceAttributeId(
                formatALBResourceId(
                    tier,
                    component,
                    extensions),
                "dns")]
[/#function]

[#function formatALBListenerResourceId tier component source]
    [#return formatComponentResourceId(
                "listener",
                tier,
                component,
                source.Port?c)]
[/#function]

[#function formatALBListenerSecurityGroupIngressResourceId tier component source]
    [#return formatComponentSecurityGroupIngressResourceId(
                tier,
                component,
                source.Port?c)]
[/#function]

[#function formatALBListenerRuleResourceId tier component source name]
    [#return formatComponentResourceId(
                "listenerRule", 
                tier,
                component,
                source.Port?c,
                name)]
[/#function]

[#function formatALBTargetGroupResourceId tier component source name]
    [#return formatComponentResourceId(
                "tg",
                tier,
                component,
                source.Port?c,
                name)]
[/#function]

[#macro createTargetGroup tier component source destination name]
    "${formatALBTargetGroupResourceId(tier, component, source, name)}" : {
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
                { "Key" : "Name", "Value" : "${formatComponentFullNameStem(tier, component, source.Port?c, name)}" }
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

[#-- APIGateway handling --]

[#function formatAPIGatewayAPIResourceId tier component apigateway]
    [#return formatComponentResourceId(
                "api",
                tier,
                component,
                apigateway.Internal.VersionId,
                apigateway.Internal.InstanceId)]

[/#function]

[#function formatAPIGatewayDeployResourceId tier component apigateway]
    [#return formatComponentResourceId(
                "apiDeploy",
                tier,
                component,
                apigateway.Internal.VersionId,
                apigateway.Internal.InstanceId)]
[/#function]

[#function formatAPIGatewayStageResourceId tier component apigateway]
    [#return formatComponentResourceId(
                "apiStage",
                tier,
                component,
                apigateway.Internal.VersionId,
                apigateway.Internal.InstanceId)]
[/#function]

[#function formatAPIGatewayLambdaPermissionResourceId tier component apigateway link fn]
    [#return formatComponentResourceId(
                "apiLambdaPermission",
                tier,
                component,
                apigateway.Internal.VersionId,
                apigateway.Internal.InstanceId,
                link.Id,
                fn.Id)]
[/#function]

[#-- Lambda resources --]

[#function formatLambdaSecurityGroupResourceId tier component lambda]
    [#return formatComponentSecurityGroupResourceId(
                    tier,
                    component,
                    lambda.Internal.VersionId,
                    lambda.Internal.InstanceId)]
[/#function]

[#function formatLambdaFunctionResourceId tier component lambda fn]
    [#return formatComponentResourceId(
                "lambda",
                tier,
                component,
                lambda.Internal.VersionId,
                lambda.Internal.InstanceId
                fn.Id)]
[/#function]

[#function formatLambdaFunctionName tier component lambda fn ]
    [#return formatComponentFullNameStem(
                tier,
                component,
                lambda.Internal.VersionName,
                lambda.Internal.InstanceName,
                fn.Name)]
[/#function]

[#-- ECS resources --]

[#function formatECSResourceId tier component]
    [#return formatComponentResourceId(
                "ecs",
                tier,
                component)]
[/#function]

[#function formatECSRoleResourceId tier component]
    [#return formatComponentRoleResourceId(
                tier,
                component)]
[/#function]

[#function formatECSServiceRoleResourceId tier component]
    [#return formatComponentSubRoleResourceId(
                tier,
                component,
                "service")]
[/#function]

[#function formatECSServiceResourceId tier component service]
    [#return formatComponentResourceId(
                "ecsService",
                tier,
                component,
                service.Internal.ServiceId,
                service.Internal.VersionId,
                service.Internal.InstanceId)]
[/#function]

[#function formatECSTaskResourceId tier component task]
    [#return formatComponentResourceId(
                "ecsTask",
                tier,
                component,
                task.Internal.TaskId,
                task.Internal.VersionId,
                task.Internal.InstanceId)]
[/#function]

[#-- Container based resources --]

[#function formatContainerId tier component host container]
    [#return formatName(
                container.Id,
                host.Internal.VersionId,
                host.Internal.InstanceId)]
[/#function]

[#function formatContainerName tier component host container]
    [#return formatComponentNameStem(
                tier,
                component,
                container.Name)]
[/#function]

[#function formatContainerPolicyResourceId tier component host container]
    [#return formatComponentPolicyResourceId(
                tier,
                component,
                host.Internal.HostId,
                host.Internal.VersionId,
                host.Internal.InstanceId,
                container.Id)]
[/#function]

[#function formatContainerPolicyName tier component host container]
    [#return formatName(
                container.Name)]
[/#function]

[#function formatContainerHostRoleResourceId tier component host]
    [#return formatComponentRoleResourceId(
                tier,
                component,
                host.Internal.HostId,
                host.Internal.VersionId,
                host.Internal.InstanceId)]
[/#function]

[#function formatContainerSecurityGroupIngressResourceId tier component task container portRange]
    [#return formatComponentSecurityGroupIngressResourceId(
                tier,
                component,
                task.Internal.VersionId,
                task.Internal.InstanceId,
                container.Id,
                portRange)]
[/#function]


[#-- SQS resources --]

[#function formatSQSResourceId ids...]
    [#return formatResourceId(
                "sqs",
                ids)]
[/#function]

[#function formatSQSResourceUrlId ids...]
    [#return formatResourceUrlAttributeId(
                formatSQSResourceId(
                    ids))]
[/#function]

[#function formatSQSResourceArnId ids...]
    [#return formatResourceArnAttributeId(
                formatSQSResourceId(
                    ids))]
[/#function]

[#function formatComponentSQSResourceId tier component sqs extensions...]
    [#local sqsExtensions = sqs?is_hash?then(
                                                [
                                                    sqs.Internal.VersionId,
                                                    sqs.Internal.InstanceId
                                                ],
                                                extensions)]
    [#return formatSQSResourceId(
                formatComponentIdStem(
                    tier,
                    component,
                    sqsExtensions))]
[/#function]

[#function formatComponentSQSResourceUrlId tier component sqs extensions...]
    [#return formatResourceUrlAttributeId(
                formatComponentSQSResourceId(
                    tier,
                    component,
                    sqs,
                    extensions))]
[/#function]

[#function formatComponentSQSResourceArnId tier component sqs extensions...]
    [#return formatResourceArnAttributeId(
                formatComponentSQSResourceId(
                    tier,
                    component,
                    sqs,
                    extensions))]
[/#function]

[#-- EC2 resources --]

[#function formatEC2InstanceProfileResourceId tier component]
    [#return formatComponentResourceId(
                "instanceProfile",
                tier,
                component)]
[/#function]

[#function formatEC2AutoScaleGroupResourceId tier component]
    [#return formatComponentResourceId(
                "asg",
                tier,
                component)]
[/#function]

[#function formatEC2LaunchConfigResourceId tier component]
    [#return formatComponentResourceId(
                "launchConfig",
                tier,
                component)]
[/#function]

[#-- EIP resources --]

[#function formatEIPResourceId ids...]
    [#return formatResourceId(
                "eip",
                ids)]
[/#function]

[#function formatEIPResourceIPAddressId ids...]
    [#return formatResourceIPAddressAttributeId(
                formatEIPResourceId(
                    ids))]
[/#function]

[#function formatEIPResourceAllocationIdId ids...]
    [#return formatResourceAllocationIdAttributeId(
                formatEIPResourceId(
                    ids))]
[/#function]

[#function formatComponentEIPResourceId tier component extensions...]
    [#return formatEIPResourceId(
                formatComponentIdStem(
                    tier,
                    component,
                    extensions))]
[/#function]

[#function formatComponentEIPResourceIPAddressId tier component extensions...]
    [#return formatResourceIPAddressAttributeId(
                formatComponentEIPResourceId(
                    tier,
                    component,
                    extensions))]
[/#function]

[#function formatComponentEIPResourceAllocationId tier component extensions...]
    [#return formatResourceAllocationIdAttributeId(
                formatComponentEIPResourceId(
                    tier,
                    component,
                    extensions))]
[/#function]

[#-- VPC resources --]

[#function formatVPCSubnetResourceId tier zone]
    [#return formatZoneResourceId(
                "subnet",
                tier,
                zone)]
[/#function]

[#-- KMS resources --]

[#function formatKMSCMKResourceId ]
    [#return formatResourceId(
                "cmk",
                "segment",
                "cmk")]
[/#function]

[#function formatKMSCMKResourceArnId ]
    [#return formatResourceArnAttributeId(
                formatKMSCMKResourceId())]
[/#function]

[#-- S3 resources --]

[#function formatS3ResourceId ids...]
    [#return formatResourceId(
                "s3",
                ids)]
[/#function]

[#function formatS3ResourceUrlId ids...]
    [#return formatResourceUrlAttributeId(
                formatS3ResourceId(
                    ids))]
[/#function]

[#-- TODO: Remove when use of "container" is removed --]
[#function formatContainerS3ResourceId type extensions...]
    [#return formatContainerResourceId(
                "s3",
                type,
                extensions)]
[/#function]

[#function formatSegmentS3ResourceId type extensions...]
    [#return formatSegmentResourceId(
                "s3",
                type,
                extensions)]
[/#function]

[#function formatComponentS3ResourceId tier component s3 extensions...]
    [#local s3Extensions = sqs?is_hash?then(
                                                [
                                                    s3.Internal.VersionId,
                                                    s3.Internal.InstanceId
                                                ],
                                                extensions)]
    [#return formatS3ResourceId(
                formatComponentIdStem(
                    tier,
                    component,
                    sqsExtensions))]
[/#function]

[#function formatS3ResourceUrlId tier component s3 extensions...]
    [#return formatResourceUrlAttributeId(
                formatComponentS3ResourceId(
                    tier,
                    component,
                    s3,
                    extensions))]
[/#function]

