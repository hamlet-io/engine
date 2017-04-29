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
    [#assign credentialsBucket = getKey("s3","account", "credentials")!"unknown"]
    [#assign codeBucket = getKey("s3","account","code")!"unknown"]
    [#assign registryBucket = getKey("s3", "account", "registry")!"unknown"]
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
    [#if getKey("s3", "segment", "ops")??]
        [#assign operationsBucket = getKey("s3", "segment", "ops")]        
    [/#if]
    [#if getKey("s3", "segment", "operations")??]
        [#assign operationsBucket = getKey("s3", "segment", "operations")]        
    [/#if]
    [#if getKey("s3", "segment", "logs")??]
        [#assign operationsBucket = getKey("s3", "segment", "logs")]        
        [#assign operationsBucketType = "logs"]
    [/#if]
    [#if getKey("s3", "container", "logs")??]
        [#assign operationsBucket = getKey("s3", "container", "logs")]        
        [#assign operationsBucketSegment = "container"]
        [#assign operationsBucketType = "logs"]
    [/#if]
    [#assign dataBucket = "unknown"]
    [#assign dataBucketSegment = "segment"]
    [#assign dataBucketType = "data"]
    [#if getKey("s3", "segment", "data")??]
        [#assign dataBucket = getKey("s3", "segment", "data")]        
    [/#if]
    [#if getKey("s3", "segment", "backups")??]
        [#assign dataBucket = getKey("s3", "segment", "backups")]        
        [#assign dataBucketType = "backups"]
    [/#if]
    [#if getKey("s3", "container", "backups")??]
        [#assign dataBucket = getKey("s3", "container", "backups")]        
        [#assign dataBucketSegment = "container"]
        [#assign dataBucketType = "backups"]
    [/#if]
    [#assign segmentDomain = getKey("domain", "segment", "domain")!"unknown"]
    [#assign segmentDomainQualifier = getKey("domain", "segment", "qualifier")!"unknown"]
    [#assign certificateId = getKey("domain", "segment", "certificate")!"unknown"]
    [#assign vpc = getKey("vpc", "segment", "vpc")!"unknown"]
    [#assign securityGroupNAT = getKey("securityGroup", "mgmt", "nat")!"none"]
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

[#-- Concatenate sequence of non-empty strings with a separator --]
[#function concatenate args separator]
    [#local content = []]
    [#list args as arg]
        [#if arg?has_content]
            [#local content += [arg]]
        [/#if]
    [/#list]
    [#return content?join(separator)]
[/#function]

[#-- Format an id - largely used for resource ids which have severe character constraints --]
[#function formatId args...]
    [#return concatenate(args, "X")]
[/#function]

[#-- Format a name - largely used for names that appear in the AWS console --]
[#function formatName args...]
    [#return concatenate(args, "-")]
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
    [#-- Line below should be sufficient but triggers bug in jq --]
    [#-- where result of call to concatenate is returned if no match --]
    [#-- on a stack output is found --]
    [#-- TODO: remove copied code when fixed in new version of jq --]
    [#-- local key = concatenate(args, "X") --]
    [#local content = []]
    [#list args as arg]
        [#if arg?has_content]
            [#local content += [arg]]
        [/#if]
    [/#list]
    [#local key = content?join("X")]
    [#list stackOutputsObject as pair]
        [#if pair.OutputKey == key]
            [#return pair.OutputValue]
        [/#if]
    [/#list]
[/#function]

[#-- Get a reference to a resource --]
[#-- Check if resource has already been defined via getKey --]
[#-- If not, assume a reference to a resource in the existing template --]
[#function getReference args...]
    [#local key = concatenate(args, "X")]
    [#if getKey(key)??]
        [#return getKey(key) ]
    [#else]
        [#return { "Ref" : key }]
    [/#if]
[/#function]

[#-- Include a reference to a resource in the output --]
[#macro createReference value]
    [#if value?is_hash && value.Ref??]
        { "Ref" : "${value.Ref}" }
    [#else]
        "${value}"
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
    [#return tier.Id]
[/#function]

[#-- Get the name for a tier --]
[#function getTierName tier]
    [#return tier.Name]
[/#function]

[#-- Get the id for a component --]
[#function getComponentId component]
    [#return component.Id?split("-")[0]]
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

[#-- Get the primary resource type for a component --]
[#function getComponentPrimaryResourceType component]
    [#assign componentType = getComponentType(component)]
    [#assign primaryResourceType = componentType]
    [#switch componentType]
        [#case "elasticache"]
            [#assign primaryResourceType = "es"]
            [#break]
        [#case "elasticsearch"]
            [#assign primaryResourceType = "cache"]
            [#break]
    [/#switch]
    [#return primaryResourceType]
[/#function]

[#-- Format a component id stem --]
[#function formatComponentIdStem tier component]
    [#return formatId(getTierId(tier), getComponentId(component))]
[/#function]

[#-- Format a component short name stem --]
[#function formatComponentShortNameStem tier component]
    [#return formatName(getTierId(tier), getComponentId(component))]
[/#function]

[#-- Format a component name stem --]
[#function formatComponentNameStem tier component]
    [#return formatName(getTierName(tier), getComponentName(component))]
[/#function]

[#-- Format a component full name stem --]
[#function formatComponentFullNameStem tier component]
    [#return formatName(productName, segmentName, formatComponentNameStem(tier, component))]
[/#function]

[#-- Get a component within a tier --]
[#function getComponent tierId componentId type]
    [#if isTier(tierId)]
        [#list getTier(tierId).Components?values as component]
            [#if (getComponentId(component) == componentId) &&
                    (getComponentType(component) == type)]
                [#return component]
            [/#if]
        [/#list]
    [/#if]
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

[#function formatSecurityGroupPrimaryResourceId idStem]
    [#return formatId("securityGroup", idStem)]
[/#function]

[#macro createSecurityGroup mode tier component idStem nameStem]
    [#if resourceCount > 0],[/#if]
    [#switch mode]
        [#case "definition"]
            "${formatId("securityGroup", idStem)}" : {
                "Type" : "AWS::EC2::SecurityGroup",
                "Properties" : {
                    "GroupDescription": "${nameStem}",
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
                        { "Key" : "Name", "Value" : "${nameStem}" }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            "${formatId("securityGroup", idStem)}" : {
                "Value" : { "Ref" : "${formatId("securityGroup", idStem)}" }
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#macro]

[#function formatTargetGroupPrimaryResourceId tier component, source, name]
    [#return formatId("tg", getComponentIdStem(tier, component), source.Port?c, name)]
[/#function]

[#macro createTargetGroup tier component source destination name]
    "${formatId("tg", getComponentIdStem(tier, component), source.Port?c, name)}" : {
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
                { "Key" : "Name", "Value" : "${formatName(formatComponentFullNameStem(tier, component), source.Port?c, name)}" }
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
