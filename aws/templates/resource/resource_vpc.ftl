[#-- VPC --]

[#macro createSecurityGroupIngressFragment port cidr groupId=""]
    [#local cidrs = cidr?is_sequence?then(
            cidr,
            [cidr]
        )]
    [#list cidrs as cidrBlock]
        {
            [#if groupId?has_content]
                "GroupId": [@createReference groupId /],
            [/#if]
            "IpProtocol": "${ports[port]?has_content?then(
                                ports[port].IPProtocol,
                                "-1")}",
            "FromPort": "${ports[port]?has_content?then(
                                ports[port].Port?c,
                                "1")}",
            "ToPort": "${ports[port]?has_content?then(
                                ports[port].Port?c,
                                "65535")}",
            [#if cidrBlock?contains("X")]
                "SourceSecurityGroupId": [@createReference cidrBlock /]
            [#else]
                [#if cidrBlock?contains(":") ]
                    "CidrIpv6": "${cidrBlock}"
                [#else]
                    "CidrIp": "${cidrBlock}"
                [/#if]
            [/#if]
        }
        [#sep],[/#sep]
    [/#list]
[/#macro]

[#macro createSecurityGroupIngress mode id port cidr groupId]
    [#local cidrs = cidr?is_sequence?then(
            cidr,
            [cidr]
        )]
    [#list cidrs as cidrBlock]
        [#switch mode]
            [#case "definition"]
                [@checkIfResourcesCreated /]
                "${formatId(
                    id,
                    (cidrs?size > 1)?then(
                        cidrBlock?index?c,
                        ""))}" : {
                    "Type" : "AWS::EC2::SecurityGroupIngress",
                    "Properties" : 
                        [@createSecurityGroupIngressFragment port cidrBlock groupId/]
                }
                [@resourcesCreated /]
            [#break]
        [/#switch]
        [#sep],[/#sep]
    [/#list]
[/#macro]

[#macro createSecurityGroup mode tier component id name description="" ingressRules=""]
    [#local nonemptyIngressRules = []]
    [#if ingressRules?has_content && ingressRules?is_sequence]
        [#list ingressRules as ingressRule]
            [#if ingressRule.CIDR?has_content]
                [#local nonemptyIngressRules += [ingressRule]]
            [/#if]
        [/#list]
    [/#if]
    [#switch mode]
        [#case "definition"]
            [@checkIfResourcesCreated /]
            "${id}" : {
                "Type" : "AWS::EC2::SecurityGroup",
                "Properties" : {
                    "GroupDescription": "${description?has_content?then(description, name)}",
                    [#if vpcId?has_content]
                        "VpcId": [@createReference vpcId /]
                    [#else]
                        "VpcId": "${vpc}"
                    [/#if]
                    ,"Tags" : [
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
                    [#if nonemptyIngressRules?has_content]
                    ,"SecurityGroupIngress" : [
                        [#list nonemptyIngressRules as ingressRule]
                            [@createSecurityGroupIngressFragment ingressRule.Port ingressRule.CIDR /]
                            [#sep],[/#sep]
                        [/#list]
                    ]
                    [/#if]
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
            resourceName
            ingressRules=""]
    [@createSecurityGroup 
        mode 
        tier 
        component
        formatDependentSecurityGroupId(resourceId)
        resourceName
        "Security Group for " + resourceName
        ingressRules /]
[/#macro]

[#macro createComponentSecurityGroup
            mode
            tier
            component
            idExtension=""
            nameExtension=""
            ingressRules=""]
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
            nameExtension)
        ""
        ingressRules /]
[/#macro]

[#macro createDependentComponentSecurityGroup
            mode
            tier
            component
            resourceId
            resourceName
            idExtension=""
            nameExtension=""
            ingressRules=""]
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
            nameExtension
            ingressRules /]
    [#else]
        [@createDependentSecurityGroup 
            mode 
            tier 
            component
            resourceId
            resourceName
            ingressRules /]
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

