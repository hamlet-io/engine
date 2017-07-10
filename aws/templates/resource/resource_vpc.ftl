[#-- VPC --]

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

[#macro createFlowLog 
            mode
            id
            roleId
            logGroupName
            resourceId
            resourceType
            trafficType]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::EC2::FlowLog",
                "Properties" : {
                    "DeliverLogsPermissionArn" : 
                        [@createArnReference roleId /],
                    "LogGroupName" : "${logGroupName}",
                    "ResourceId" : 
                        [@createReference resourceId /],
                    "ResourceType" : "${resourceType}",
                    "TrafficType" : "${trafficType}"
                }
            }
            [@resourcesCreated /]
            [#break]

        [#case "outputs"]
            [@output id /]
            [#break]

    [/#switch]
[/#macro]

