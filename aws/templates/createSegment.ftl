[#ftl]
[#-- Standard inputs --]
[#assign blueprintObject = blueprint?eval]
[#assign credentialsObject = credentials?eval]
[#assign appSettingsObject = appsettings?eval]
[#assign stackOutputsObject = stackOutputs?eval]

[#-- High level objects --]
[#assign tenantObject = blueprintObject.Tenant]
[#assign accountObject = blueprintObject.Account]
[#assign productObject = blueprintObject.Product]
[#assign solutionObject = blueprintObject.Solution]
[#assign segmentObject = blueprintObject.Segment]
[#assign powersOf2 = blueprintObject.PowersOf2]

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

[#-- Reference Objects --]
[#assign regionId = region]
[#assign regionObject = regions[regionId]]
[#assign accountRegionId = accountRegion]
[#assign accountRegionObject = regions[accountRegionId]]
[#assign productRegionId = productRegion]
[#assign productRegionObject = regions[productRegionId]]
[#assign environmentId = segmentObject.Environment]
[#assign environmentObject = environments[environmentId]]
[#assign categoryId = segmentObject.Category!environmentObject.Category]
[#assign categoryObject = categories[categoryId]]

[#-- Key ids/names --]
[#assign tenantId = tenantObject.Id]
[#assign accountId = accountObject.Id]
[#assign productId = productObject.Id]
[#assign productName = productObject.Name]
[#assign segmentId = segmentObject.Id]
[#assign segmentName = segmentObject.Name]
[#assign environmentName = environmentObject.Name]

[#-- Domains --]
[#assign productDomainStem = productObject.Domain.Stem]
[#assign segmentDomainBehaviour = (productObject.Domain.SegmentBehaviour)!""]
[#assign segmentDomainCertificateId = productObject.Domain.Certificate.Id]
[#switch segmentDomainBehaviour]
    [#case "segmentProductInDomain"]
        [#assign segmentDomain = segmentName + "." + productName + "." + productDomainStem]
        [#assign segmentDomainQualifier = ""]
        [#assign segmentDomainCertificateId = segmentDomainCertificateId + "-" + productId + "-" + segmentId]
        [#break]
    [#case "segmentInDomain"]
        [#assign segmentDomain = segmentName + "." + productDomainStem]
        [#assign segmentDomainQualifier = ""]
        [#assign segmentDomainCertificateId = segmentDomainCertificateId + "-" + segmentId]
        [#break]
    [#case "naked"]
        [#assign segmentDomain = productDomainStem]
        [#assign segmentDomainQualifier = ""]
        [#break]
    [#case "segmentInHost"]
        [#assign segmentDomain = productDomainStem]
        [#assign segmentDomainQualifier = "-" + segmentName]
        [#break]
    [#case "segmentProductInHost"]
    [#default]
        [#assign segmentDomain = productDomainStem]
        [#assign segmentDomainQualifier = "-" + segmentName + "-" + productName]
        [#break]
[/#switch]
[#assign segmentDomainCertificateId = segmentDomainCertificateId?replace("-","X")]

[#-- Buckets --]
[#assign credentialsBucket = getKey("s3XaccountXcredentials")!"unknown"]
[#assign codeBucket = getKey("s3XaccountXcode")!"unknown"]

[#-- Get stack output --]
[#function getKey key]
    [#list stackOutputsObject as pair]
        [#if pair.OutputKey==key]
            [#return pair.OutputValue]
        [/#if]
    [/#list]
[/#function]

[#-- Calculate the closest power of 2 --]
[#function getPowerOf2 value]
    [#assign exponent = -1]
    [#list powersOf2 as powerOf2]
        [#if powerOf2 <= value]
            [#assign exponent = powerOf2?index]
        [#else]
            [#break]
        [/#if]
    [/#list]
    [#return exponent]
[/#function]

[#-- Segment --]
[#assign baseAddress = segmentObject.CIDR.Address?split(".")]
[#assign addressOffset = baseAddress[2]?number*256 + baseAddress[3]?number]
[#assign addressesPerTier = powersOf2[getPowerOf2(powersOf2[32 - segmentObject.CIDR.Mask]/(segmentObject.Tiers.Order?size))]]
[#assign addressesPerZone = powersOf2[getPowerOf2(addressesPerTier / (segmentObject.Zones.Order?size))]]
[#assign subnetMask = 32 - powersOf2?seq_index_of(addressesPerZone)]

[#assign internetAccess = segmentObject.InternetAccess]
[#assign dnsSupport = segmentObject.DNSSupport]
[#assign dnsHostnames = segmentObject.DNSHostnames]
[#assign jumpServer = internetAccess && segmentObject.NAT.Enabled]
[#assign jumpServerPerAZ = jumpServer && segmentObject.NAT.MultiAZ]
[#assign sshPerSegment = segmentObject.SSHPerSegment]
[#assign rotateKeys = (segmentObject.RotateKeys)!true]
[#-- Current bucket naming --]
[#assign operationsBucket = "operations" + segmentDomainQualifier + "." + segmentDomain]
[#assign dataBucket = "data" + segmentDomainQualifier + "." + segmentDomain]
[#-- Support presence of existing s3 buckets (naming has changed over time) --]
[#assign operationsBucket = getKey("s3XsegmentXoperations")!getKey("s3XsegmentXlogs")!operationsBucket]
[#assign dataBucket = getKey("s3XsegmentXdata")!getKey("s3XsegmentXbackups")!dataBucket]

[#assign operationsExpiration = (segmentObject.Operations.Expiration)!(environmentObject.Operations.Expiration)]
[#assign dataExpiration = (segmentObject.Data.Expiration)!(environmentObject.Data.Expiration)]

[#-- Required tiers --]
[#function isTier tierId]
    [#return (blueprintObject.Tiers[tierId])??]
[/#function]

[#function getTier tierId]
    [#return blueprintObject.Tiers[tierId]]
[/#function]

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
    [#assign tc = tier.Id + "-" + component.Id]
    [#assign defaultProfile = "default"]
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

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    "Resources" : {
        [#assign sliceCount = 0]
        [#if slice?contains("eip")]
            [#-- Define EIPs --]
            [#if sliceCount > 0],[/#if]
            [#assign eipCount = 0]
            [#if jumpServer]
                [#assign tier = getTier("mgmt")]
                [#list zones as zone]
                    [#if jumpServerPerAZ || (zones[0].Id == zone.Id)]
                        [#if eipCount > 0],[/#if]
                        "eipX${tier.Id}XnatX${zone.Id}": {
                            "Type" : "AWS::EC2::EIP",
                            "Properties" : {
                                "Domain" : "vpc"
                            }
                        }
                        [#assign eipCount += 1]
                    [/#if]
                [/#list]
                [#assign sliceCount += 1]
            [/#if]
        [/#if]
                
        [#if slice?contains("cmk")]
            [#-- Define KMS CMK --]
            [#if sliceCount > 0],[/#if]
            "cmk" : {
                "Type" : "AWS::KMS::Key",
                "Properties" : {
                    "Description" : "${productName}-${segmentName}",
                    "Enabled" : true,
                    "EnableKeyRotation" : ${(rotateKeys)?string("true","false")},
                    "KeyPolicy" : {
                        "Version": "2012-10-17",
                        "Statement": [ 
                            {
                                "Effect": "Allow",
                                "Principal": { 
                                    "AWS": { 
                                        "Fn::Join": [
                                            "", 
                                            [
                                                "arn:aws:iam::",
                                                { "Ref" : "AWS::AccountId" },
                                                ":root"
                                            ]
                                        ]
                                    }
                                },
                                "Action": [ "kms:*" ],
                                "Resource": "*"
                            }
                        ]
                    }
                }
            },
            "aliasXcmk" : {
                "Type" : "AWS::KMS::Alias",
                "Properties" : {
                    "AliasName" : "alias/${productName}-${segmentName}",
                    "TargetKeyId" : { "Fn::GetAtt" : ["cmk", "Arn"] }
                }
            }
            [#assign sliceCount += 1]
        [/#if]

        [#if slice?contains("cert")]
            [#-- Generate certificate --]
            [#if sliceCount > 0],[/#if]
            "certificate" : {
                "Type" : "AWS::CertificateManager::Certificate",
                "Properties" : {
                    "DomainName" : "*.${segmentDomain}",
                    "DomainValidationOptions" : [
                        {
                            "DomainName" : "*.${segmentDomain}",
                            "ValidationDomain" : "${tenantObject.Domain.Validation}"
                        }
                    ]
                }
            }
            [#assign sliceCount += 1]
        [/#if]
        
        [#if slice?contains("dns")]
            [#-- Define private DNS zone --]
            [#if sliceCount > 0],[/#if]
            "dns" : {
                "Type" : "AWS::Route53::HostedZone",
                "Properties" : {
                    "HostedZoneConfig" : {
                        "Comment" : "${productName}-${segmentName}" 
                    },
                    "HostedZoneTags" : [ 
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" }
                    ],
                    "Name" : "${segmentName}.${productName}.internal",
                    "VPCs" : [                
                        { "VPCId" : "${getKey("vpcXsegmentXvpc")}", "VPCRegion" : "${regionId}" }
                    ]
                }
            }
            [#assign sliceCount += 1]
        [/#if]
        
        [#if slice?contains("vpc")]
            [#-- Define VPC --]
            [#if sliceCount > 0],[/#if]
            "vpc" : {
                "Type" : "AWS::EC2::VPC",
                "Properties" : {
                    "CidrBlock" : "${segmentObject.CIDR.Address}/${segmentObject.CIDR.Mask}",
                    "EnableDnsSupport" : ${(dnsSupport)?string("true","false")},
                    "EnableDnsHostnames" : ${(dnsHostnames)?string("true","false")},
                    "Tags" : [ 
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" },
                        { "Key" : "Name", "Value" : "${productName}-${segmentName}" } 
                    ]
                }
            }
            
            [#-- Define Internet Gateway and connect it to the VPC --]
            [#if internetAccess]
                ,"igw" : {
                    "Type" : "AWS::EC2::InternetGateway",
                    "Properties" : {
                        "Tags" : [ 
                            { "Key" : "cot:request", "Value" : "${requestReference}" },
                            { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                            { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                            { "Key" : "cot:account", "Value" : "${accountId}" },
                            { "Key" : "cot:product", "Value" : "${productId}" },
                            { "Key" : "cot:segment", "Value" : "${segmentId}" },
                            { "Key" : "cot:environment", "Value" : "${environmentId}" },
                            { "Key" : "cot:category", "Value" : "${categoryId}" },
                            { "Key" : "Name", "Value" : "${productName}-${segmentName}" } 
                        ]
                    }
                },
                "igwXattachment" : {
                    "Type" : "AWS::EC2::VPCGatewayAttachment",
                    "Properties" : {
                        "InternetGatewayId" : { "Ref" : "igw" },
                        "VpcId" : { "Ref" : "vpc" }
                    }
                }
            [/#if]
            
            [#-- Define route tables --]
            [#assign solutionRouteTables = []]
            [#list tiers as tier]
                [#assign routeTableId = tier.RouteTable]
                [#assign routeTable = routeTables[routeTableId]]
                [#list zones as zone]
                    [#assign tableId = routeTableId + jumpServerPerAZ?string("X" + zone.Id,"")]
                    [#assign tableName = routeTable.Name + jumpServerPerAZ?string("-" + zone.Id,"")]
                    [#if !solutionRouteTables?seq_contains(tableId)]
                        [#assign solutionRouteTables = solutionRouteTables + [tableId]]
                        ,"routeTableX${tableId}" : {
                            "Type" : "AWS::EC2::RouteTable",
                            "Properties" : {
                                "VpcId" : { "Ref" : "vpc" },
                                "Tags" : [ 
                                    { "Key" : "cot:request", "Value" : "${requestReference}" },
                                    { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                                    { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                                    { "Key" : "cot:account", "Value" : "${accountId}" },
                                    { "Key" : "cot:product", "Value" : "${productId}" },
                                    { "Key" : "cot:segment", "Value" : "${segmentId}" },
                                    { "Key" : "cot:environment", "Value" : "${environmentId}" },
                                    { "Key" : "cot:category", "Value" : "${categoryId}" },
                                    [#if jumpServerPerAZ]
                                        { "Key" : "cot:zone", "Value" : "${zone.Id}" },
                                    [/#if]
                                    { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tableName}" } 
                                ]
                            }
                        }
                        [#list routeTable.Routes?values as route]
                            [#if route?is_hash]
                                ,"routeX${tableId}X${route.Id}" : {
                                    "Type" : "AWS::EC2::Route",
                                    "Properties" : {
                                        "RouteTableId" : { "Ref" : "routeTableX${tableId}" },
                                        [#switch route.Type]
                                            [#case "gateway"]
                                                "DestinationCidrBlock" : "0.0.0.0/0",
                                                "GatewayId" : { "Ref" : "igw" }
                                                [#break]
                                        [/#switch]
                                    }
                                }
                            [/#if]
                        [/#list]
                    [/#if]
                [/#list]
            [/#list]
            
            [#-- Define network ACLs --]
            [#assign solutionNetworkACLs = []]
            [#list tiers as tier]
                [#assign networkACLId = tier.NetworkACL]
                [#assign networkACL = networkACLs[networkACLId]]
                [#if !solutionNetworkACLs?seq_contains(networkACLId)]
                    [#assign solutionNetworkACLs = solutionNetworkACLs + [networkACLId]]
                    ,"networkACLX${networkACLId}" : {
                        "Type" : "AWS::EC2::NetworkAcl",
                        "Properties" : {
                            "VpcId" : { "Ref" : "vpc" },
                            "Tags" : [ 
                                { "Key" : "cot:request", "Value" : "${requestReference}" },
                                { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                                { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                                { "Key" : "cot:account", "Value" : "${accountId}" },
                                { "Key" : "cot:product", "Value" : "${productId}" },
                                { "Key" : "cot:segment", "Value" : "${segmentId}" },
                                { "Key" : "cot:environment", "Value" : "${environmentId}" },
                                { "Key" : "cot:category", "Value" : "${categoryId}" },
                                { "Key" : "Name", "Value" : "${productName}-${segmentName}-${networkACL.Name}" } 
                            ]
                        }
                    }                    
                    [#list ["Inbound", "Outbound"] as direction]
                        [#if networkACL.Rules[direction]??]
                            [#list networkACL.Rules[direction]?values as rule]
                                [#if rule?is_hash]
                                    ,"ruleX${networkACLId}X${(direction="Outbound")?string("out", "in")}X${rule.Id}" : {
                                        "Type" : "AWS::EC2::NetworkAclEntry",
                                        "Properties" : {
                                            "NetworkAclId" : { "Ref" : "networkACLX${networkACLId}" },
                                            "Egress" : "${(direction="Outbound")?string("true","false")}",
                                            "RuleNumber" : "${rule.RuleNumber}",
                                            "RuleAction" : "${rule.Allow?string("allow","deny")}",
                                            "CidrBlock" : "${rule.CIDRBlock}",
                                            [#switch rule.Protocol]
                                                [#case "all"]
                                                    "Protocol" : "-1",
                                                    "PortRange" : { "From" : "${((rule.PortRange.From)!0)?c}", "To" : "${((rule.PortRange.To)!65535)?c}"}
                                                    [#break]
                                                [#case "icmp"]
                                                    "Protocol" : "1",
                                                    "Icmp" : {"Code" : "${((rule.ICMP.Code)!-1)?c}", "Type" : "${((rule.ICMP.Type)!-1)?c}"}
                                                    [#break]
                                                [#case "udp"]
                                                    "Protocol" : "17",
                                                    "PortRange" : { "From" : "${((rule.PortRange.From)!0)?c}", "To" : "${((rule.PortRange.To)!65535)?c}"}
                                                    [#break]
                                                [#case "tcp"]
                                                    "Protocol" : "6",
                                                    "PortRange" : { "From" : "${((rule.PortRange.From)!0)?c}", "To" : "${((rule.PortRange.To)!65535)?c}"}
                                                    [#break]
                                            [/#switch]
                                        }
                                    }
                                [/#if]
                            [/#list]
                        [/#if]
                    [/#list]
                [/#if]
            [/#list]

            [#-- Define subnets --]
            [#list tiers as tier]
                [#assign routeTableId = tier.RouteTable]
                [#assign routeTable = routeTables[routeTableId]]
                [#assign networkACLId = tier.NetworkACL]
                [#assign networkACL = networkACLs[networkACLId]]
                [#list zones as zone]
                    ,"subnetX${tier.Id}X${zone.Id}" : {
                        "Type" : "AWS::EC2::Subnet",
                        "Properties" : {
                            "VpcId" : { "Ref" : "vpc" },
                            "AvailabilityZone" : "${zone.AWSZone}",
                            [#assign subnetAddress = addressOffset + (tier.Index * addressesPerTier) + (zone.Index * addressesPerZone)]
                            "CidrBlock" : "${baseAddress[0]}.${baseAddress[1]}.${(subnetAddress/256)?int}.${(subnetAddress%256)}/${subnetMask}",
                            "Tags" : [
                                { "Key" : "cot:request", "Value" : "${requestReference}" },
                                { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                                { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                                { "Key" : "cot:account", "Value" : "${accountId}" },
                                { "Key" : "cot:product", "Value" : "${productId}" },
                                { "Key" : "cot:segment", "Value" : "${segmentId}" },
                                { "Key" : "cot:environment", "Value" : "${environmentId}" },
                                { "Key" : "cot:category", "Value" : "${categoryId}" },
                                { "Key" : "cot:tier", "Value" : "${tier.Id}" },
                                { "Key" : "cot:zone", "Value" : "${zone.Id}" },
                                [#if routeTable.Private!false]
                                    { "Key" : "network", "Value" : "private" },
                                [/#if]
                                { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${zone.Name}" } 
                            ]
                        }
                    },
                    
                    "routeTableXassociationX${tier.Id}X${zone.Id}" : {
                        "Type" : "AWS::EC2::SubnetRouteTableAssociation",
                        "Properties" : {
                            "SubnetId" : { "Ref" : "subnetX${tier.Id}X${zone.Id}" },
                            "RouteTableId" : { "Ref" : "routeTableX${routeTableId + jumpServerPerAZ?string("X" + zone.Id,"")}" }
                        }
                    },
                    
                    "networkACLXassociationX${tier.Id}X${zone.Id}" : {
                        "Type" : "AWS::EC2::SubnetNetworkAclAssociation",
                        "Properties" : {
                            "SubnetId" : { "Ref" : "subnetX${tier.Id}X${zone.Id}" },
                            "NetworkAclId" : { "Ref" : "networkACLX${networkACLId}" }
                        }
                    }
                [/#list]
            [/#list]
                        
            [#if jumpServer]
                [#assign tier = getTier("mgmt")]
                ,"roleX${tier.Id}Xnat": {
                    "Type" : "AWS::IAM::Role",
                    "Properties" : {
                        "AssumeRolePolicyDocument" : {
                            "Version": "2012-10-17",
                            "Statement": [ 
                                {
                                    "Effect": "Allow",
                                    "Principal": { "Service": [ "ec2.amazonaws.com" ] },
                                    "Action": [ "sts:AssumeRole" ]
                                }
                            ]
                        },
                        "Path": "/",
                        "Policies": [
                            {
                                "PolicyName": "${tier.Id}-nat",
                                "PolicyDocument" : {
                                    "Version" : "2012-10-17",
                                    "Statement" : [
                                        {
                                            "Effect" : "Allow",
                                            "Action" : [
                                                "ec2:DescribeInstances",
                                                "ec2:ModifyInstanceAttribute",
                                                "ec2:DescribeSubnets",
                                                "ec2:DescribeRouteTables",
                                                "ec2:CreateRoute",
                                                "ec2:ReplaceRoute",
                                                "ec2:DescribeAddresses",
                                                "ec2:AssociateAddress"
                                            ],
                                            "Resource": "*"
                                        },
                                        {
                                            "Resource": [
                                                "arn:aws:s3:::${codeBucket}"
                                            ],
                                            "Action": [
                                                "s3:ListBucket"
                                            ],
                                            "Effect": "Allow"
                                        },
                                        {
                                            "Resource": [
                                                "arn:aws:s3:::${codeBucket}/*"
                                            ],
                                            "Action": [
                                                "s3:GetObject",
                                                "s3:ListObjects"
                                            ],
                                            "Effect": "Allow"
                                        }
                                    ]
                                }
                            }
                        ]
                    }
                },
                "instanceProfileX${tier.Id}Xnat" : {
                    "Type" : "AWS::IAM::InstanceProfile",
                    "Properties" : {
                        "Path" : "/",
                        "Roles" : [ 
                            { "Ref" : "roleX${tier.Id}Xnat" } 
                        ]
                    }
                },
                "securityGroupX${tier.Id}Xnat" : {
                    "Type" : "AWS::EC2::SecurityGroup",
                    "Properties" : {
                        "GroupDescription": "Security Group for HA NAT instances",
                        "VpcId": { "Ref": "vpc" },
                        "Tags" : [
                            { "Key" : "cot:request", "Value" : "${requestReference}" },
                            { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                            { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                            { "Key" : "cot:account", "Value" : "${accountId}" },
                            { "Key" : "cot:product", "Value" : "${productId}" },
                            { "Key" : "cot:segment", "Value" : "${segmentId}" },
                            { "Key" : "cot:environment", "Value" : "${environmentId}" },
                            { "Key" : "cot:category", "Value" : "${categoryId}" },
                            { "Key" : "cot:tier", "Value" : "${tier.Id}"},
                            { "Key" : "cot:component", "Value" : "nat"},
                            { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-nat" }
                        ],
                        "SecurityGroupIngress" : [
                            [#if (segmentObject.IPAddressBlocks)??]
                                [#list segmentObject.IPAddressBlocks?values as groupValue]
                                    [#if groupValue?is_hash]
                                        [#list groupValue?values as entryValue]
                                            [#if entryValue?is_hash && (entryValue.CIDR)?has_content ]
                                                [#if (!entryValue.Usage??) || entryValue.Usage?seq_contains("nat") ]
                                                    [#if (entryValue.CIDR)?is_sequence]
                                                        [#list entryValue.CIDR as CIDRBlock]
                                                            { "IpProtocol": "tcp", "FromPort": "22", "ToPort": "22", "CidrIp": "${CIDRBlock}" },
                                                        [/#list]
                                                    [#else]
                                                        { "IpProtocol": "tcp", "FromPort": "22", "ToPort": "22", "CidrIp": "${entryValue.CIDR}" },
                                                    [/#if]
                                                [/#if]
                                            [/#if]
                                        [/#list]
                                    [/#if]
                                [/#list]
                            [#else]
                                { "IpProtocol": "tcp", "FromPort": "22", "ToPort": "22", "CidrIp": "0.0.0.0/0" },
                            [/#if]
                            { "IpProtocol": "-1", "FromPort": "1", "ToPort": "65535", "CidrIp": "${segmentObject.CIDR.Address}/${segmentObject.CIDR.Mask}" }
                        ]
                    }
                },
                "securityGroupX${tier.Id}XallXnat" : {
                    "Type" : "AWS::EC2::SecurityGroup",
                    "Properties" : {
                        "GroupDescription": "Security Group for access from NAT",
                        "VpcId": { "Ref": "vpc" },
                        "Tags" : [
                            { "Key" : "cot:request", "Value" : "${requestReference}" },
                            { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                            { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                            { "Key" : "cot:account", "Value" : "${accountId}" },
                            { "Key" : "cot:product", "Value" : "${productId}" },
                            { "Key" : "cot:segment", "Value" : "${segmentId}" },
                            { "Key" : "cot:environment", "Value" : "${environmentId}" },
                            { "Key" : "cot:category", "Value" : "${categoryId}" },
                            { "Key" : "cot:tier", "Value" : "all"},
                            { "Key" : "cot:component", "Value" : "nat"},
                            { "Key" : "Name", "Value" : "${productName}-${segmentName}-all-nat" }
                        ],
                        "SecurityGroupIngress" : [
                            { "IpProtocol": "tcp", "FromPort": "22", "ToPort": "22", "SourceSecurityGroupId": { "Ref" : "securityGroupX${tier.Id}Xnat"} }
                        ]
                    }
                }
                        
                [#list zones as zone]
                    [#if jumpServerPerAZ || (zones[0].Id == zone.Id)]
                        ,"asgX${tier.Id}XnatX${zone.Id}": {
                            "DependsOn" : [ "subnetX${tier.Id}X${zone.Id}" ],
                            "Type": "AWS::AutoScaling::AutoScalingGroup",
                            "Metadata": {
                                "AWS::CloudFormation::Init": {
                                    "configSets" : {
                                        "nat" : ["dirs", "bootstrap", "nat"]
                                    },
                                    "dirs": {
                                        "commands": {
                                            "01Directories" : {
                                                "command" : "mkdir --parents --mode=0755 /etc/codeontap && mkdir --parents --mode=0755 /opt/codeontap/bootstrap && mkdir --parents --mode=0755 /var/log/codeontap",
                                                "ignoreErrors" : "false"
                                            }
                                        }
                                    },
                                    "bootstrap": {
                                        "packages" : {
                                            "yum" : {
                                                "aws-cli" : []
                                            }
                                        },  
                                        "files" : {
                                            "/etc/codeontap/facts.sh" : {
                                                "content" : { 
                                                    "Fn::Join" : [
                                                        "", 
                                                        [
                                                            "#!/bin/bash\n",
                                                            "echo \"cot:request=${requestReference}\"\n",
                                                            "echo \"cot:configuration=${configurationReference}\"\n",
                                                            "echo \"cot:accountRegion=${accountRegionId}\"\n",
                                                            "echo \"cot:tenant=${tenantId}\"\n",
                                                            "echo \"cot:account=${accountId}\"\n",
                                                            "echo \"cot:product=${productId}\"\n",
                                                            "echo \"cot:region=${regionId}\"\n",
                                                            "echo \"cot:segment=${segmentId}\"\n",
                                                            "echo \"cot:environment=${environmentId}\"\n",
                                                            "echo \"cot:tier=${tier.Id}\"\n",
                                                            "echo \"cot:component=nat\"\n",
                                                            "echo \"cot:zone=${zone.Id}\"\n",
                                                            "echo \"cot:role=nat\"\n",
                                                            "echo \"cot:credentials=${credentialsBucket}\"\n",
                                                            "echo \"cot:code=${codeBucket}\"\n",
                                                            "echo \"cot:logs=${operationsBucket}\"\n",
                                                            "echo \"cot:backups=${dataBucket}\"\n"
                                                        ]
                                                    ]
                                                },
                                                "mode" : "000755"
                                            },
                                            "/opt/codeontap/bootstrap/fetch.sh" : {
                                                "content" : { 
                                                    "Fn::Join" : [
                                                        "", 
                                                        [
                                                            "#!/bin/bash -ex\n",
                                                            "exec > >(tee /var/log/codeontap/fetch.log|logger -t codeontap-fetch -s 2>/dev/console) 2>&1\n",
                                                            "REGION=$(/etc/codeontap/facts.sh | grep cot:accountRegion | cut -d '=' -f 2)\n",
                                                            "CODE=$(/etc/codeontap/facts.sh | grep cot:code | cut -d '=' -f 2)\n",
                                                            "aws --region ${r"${REGION}"} s3 sync s3://${r"${CODE}"}/bootstrap/centos/ /opt/codeontap/bootstrap && chmod 0500 /opt/codeontap/bootstrap/*.sh\n"
                                                        ]
                                                    ]
                                                },
                                                "mode" : "000755"
                                            }
                                        },
                                        "commands": {
                                            "01Fetch" : {
                                                "command" : "/opt/codeontap/bootstrap/fetch.sh",
                                                "ignoreErrors" : "false"
                                            },
                                            "02Initialise" : {
                                                "command" : "/opt/codeontap/bootstrap/init.sh",
                                                "ignoreErrors" : "false"
                                            }
                                        }
                                    },
                                    "nat": {
                                        "commands": {
                                            "01ExecuteRouteUpdateScript" : {
                                                "command" : "/opt/codeontap/bootstrap/nat.sh",
                                                "ignoreErrors" : "false"
                                            }
                                            [#if slice?contains("eip")]
                                                ,"02ExecuteAllocateEIPScript" : {
                                                    "command" : "/opt/codeontap/bootstrap/eip.sh",
                                                    "env" : { 
                                                        [#-- Legacy code to support definition of eip and vpc in one template (slice = "eipvpc" or "eips3vpc" depending on how S3 to be defined)  --]
                                                        "EIP_ALLOCID" : { "Fn::GetAtt" : ["eipX${tier.Id}XnatX${zone.Id}", "AllocationId"] }
                                                    },
                                                    "ignoreErrors" : "false"
                                                }
                                            [#else]
                                                [#if getKey("eipX" + tier.Id + "XnatX" + zone.Id + "Xid")??]
                                                    ,"02ExecuteAllocateEIPScript" : {
                                                        "command" : "/opt/codeontap/bootstrap/eip.sh",
                                                        "env" : { 
                                                            [#-- Normally assume eip defined in a separate template to the vpc --]
                                                            "EIP_ALLOCID" : "${getKey("eipX" + tier.Id + "XnatX" + zone.Id + "Xid")}"
                                                        },
                                                        "ignoreErrors" : "false"
                                                    }
                                                [/#if]
                                            [/#if]
                                        }
                                    }
                                }
                            },
                            "Properties": {
                                "Cooldown" : "30",
                                "LaunchConfigurationName": {"Ref": "launchConfigX${tier.Id}XnatX${zone.Id}"},
                                "MinSize": "1",
                                "MaxSize": "1",
                                "VPCZoneIdentifier": [ 
                                    { "Ref" : "subnetX${tier.Id}X${zone.Id}"} 
                                ],
                                "Tags" : [
                                    { "Key" : "cot:request", "Value" : "${requestReference}", "PropagateAtLaunch" : "True" },
                                    { "Key" : "cot:configuration", "Value" : "${configurationReference}", "PropagateAtLaunch" : "True" },
                                    { "Key" : "cot:tenant", "Value" : "${tenantId}", "PropagateAtLaunch" : "True" },
                                    { "Key" : "cot:account", "Value" : "${accountId}", "PropagateAtLaunch" : "True" },
                                    { "Key" : "cot:product", "Value" : "${productId}", "PropagateAtLaunch" : "True" },
                                    { "Key" : "cot:segment", "Value" : "${segmentId}", "PropagateAtLaunch" : "True" },
                                    { "Key" : "cot:environment", "Value" : "${environmentId}", "PropagateAtLaunch" : "True" },
                                    { "Key" : "cot:category", "Value" : "${categoryId}", "PropagateAtLaunch" : "True" },
                                    { "Key" : "cot:tier", "Value" : "${tier.Id}", "PropagateAtLaunch" : "True" },
                                    { "Key" : "cot:component", "Value" : "nat", "PropagateAtLaunch" : "True"},
                                    { "Key" : "cot:zone", "Value" : "${zone.Id}", "PropagateAtLaunch" : "True" },
                                    { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-nat-${zone.Name}", "PropagateAtLaunch" : "True" }
                                ]
                            }
                        },
                    
                        [#assign component = { "Id" : ""}]
                        [#assign processorProfile = getProcessor(tier, component, "NAT")]
                        "launchConfigX${tier.Id}XnatX${zone.Id}": {
                            "Type": "AWS::AutoScaling::LaunchConfiguration",
                            "Properties": {
                                "KeyName": "${productName + sshPerSegment?string("-" + segmentName,"")}",
                                "ImageId": "${regionObject.AMIs.Centos.NAT}",
                                "InstanceType": "${processorProfile.Processor}",
                                "SecurityGroups" : [ { "Ref": "securityGroupX${tier.Id}Xnat" } ],
                                "IamInstanceProfile" : { "Ref" : "instanceProfileX${tier.Id}Xnat" },
                                "AssociatePublicIpAddress": true,
                                "UserData": {
                                    "Fn::Base64": { 
                                        "Fn::Join": [ 
                                            "", 
                                            [
                                                "#!/bin/bash -ex\n",
                                                "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\n",
                                                "yum install -y aws-cfn-bootstrap\n",
                                                "# Remainder of configuration via metadata\n",
                                                "/opt/aws/bin/cfn-init -v",
                                                "         --stack ", { "Ref" : "AWS::StackName" },
                                                "         --resource asgX${tier.Id}XnatX${zone.Id}",
                                                "         --region ${regionId} --configsets nat\n"
                                            ]
                                        ]
                                    }
                                }
                            }
                        }
                    [/#if]
                [/#list]
            [/#if]
            [#assign sliceCount += 1]
        [/#if]
        
        [#if slice?contains("s3")]
            [#-- Create operations bucket --]
            [#if sliceCount > 0],[/#if]
            "s3Xoperations" : {
                "Type" : "AWS::S3::Bucket",
                "Properties" : {
                    "BucketName" : "${operationsBucket}",
                    "Tags" : [ 
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" }
                    ],
                    "LifecycleConfiguration" : {
                        "Rules" : [
                            {
                                "Id" : "default",
                                "ExpirationInDays" : ${operationsExpiration},
                                "Status" : "Enabled"
                            }
                        ]
                    }
                }
            },
            [#-- Ensure ELBs can write to the operations bucket for logs --]
            "s3XoperationsXpolicy" : {
                "Type" : "AWS::S3::BucketPolicy",
                "Properties" : {
                    "Bucket" : "${operationsBucket}",
                    "PolicyDocument" : {
                        "Statement": [
                            {
                                "Effect": "Allow",
                                "Principal": {
                                    "AWS": "arn:aws:iam::${regionObject.Accounts["ELB"]}:root"
                                },
                                "Action": "s3:PutObject",
                                "Resource": "arn:aws:s3:::${operationsBucket}/AWSLogs/*"
                            }
                        ]
                    }
                }
            },
            [#-- Create data bucket --]
            "s3Xdata" : {
                "Type" : "AWS::S3::Bucket",
                "Properties" : {
                    "BucketName" : "${dataBucket}",
                    "Tags" : [ 
                        { "Key" : "cot:request", "Value" : "${requestReference}" },
                        { "Key" : "cot:configuration", "Value" : "${configurationReference}" },
                        { "Key" : "cot:tenant", "Value" : "${tenantId}" },
                        { "Key" : "cot:account", "Value" : "${accountId}" },
                        { "Key" : "cot:product", "Value" : "${productId}" },
                        { "Key" : "cot:segment", "Value" : "${segmentId}" },
                        { "Key" : "cot:environment", "Value" : "${environmentId}" },
                        { "Key" : "cot:category", "Value" : "${categoryId}" }
                    ],
                    "LifecycleConfiguration" : {
                        "Rules" : [
                            {
                                "Id" : "default",
                                "ExpirationInDays" : ${dataExpiration},
                                "Status" : "Enabled"
                            }
                        ]
                    }
                }
            }
            [#assign sliceCount += 1]
        [/#if]
    },
    "Outputs" : 
    {
        [#assign sliceCount = 0]
        [#if slice?contains("eip")]
            [#if sliceCount > 0],[/#if]
            [#assign eipCount = 0]
            [#if jumpServer]
                [#assign tier = getTier("mgmt")]
                [#list zones as zone]
                    [#if jumpServerPerAZ || (zones[0].Id == zone.Id)]
                        [#if eipCount > 0],[/#if]
                            "eipX${tier.Id}XnatX${zone.Id}Xip": {
                                "Value" : { "Ref" : "eipX${tier.Id}XnatX${zone.Id}" }
                            },
                            "eipX${tier.Id}XnatX${zone.Id}Xid": {
                                "Value" : { "Fn::GetAtt" : ["eipX${tier.Id}XnatX${zone.Id}", "AllocationId"] }
                            }
                            [#assign eipCount += 1]
                    [/#if]
                [/#list]
                [#assign sliceCount += 1]
            [/#if]
        [/#if]
        
        [#if slice?contains("cmk")]
            [#if sliceCount > 0],[/#if]
            "cmkXsegmentXcmk" : {
                "Value" : { "Ref" : "cmk" }
            }
            [#assign sliceCount += 1]
        [/#if]
        
        [#if slice?contains("cert")]
            [#if sliceCount > 0],[/#if]
            "certificateX${segmentDomainCertificateId}" : {
                "Value" : { "Ref" : "certificate" }
            }
            [#assign sliceCount += 1]
        [/#if]
        
        [#if slice?contains("dns")]
            [#if sliceCount > 0],[/#if]
            "dnsXsegmentXdns" : {
                "Value" : { "Ref" : "dns" }
            }
            [#assign sliceCount += 1]
        [/#if]
        
        [#if slice?contains("vpc")]
            [#if sliceCount > 0],[/#if]
            "domainXsegmentXdomain" : {
                "Value" : "${segmentDomain}"
            },
            "domainXsegmentXqualifier" : {
                "Value" : "${segmentDomainQualifier}"
            },
            "domainXsegmentXcertificate" : {
                "Value" : "${segmentDomainCertificateId}"
            },
            "vpcXsegmentXvpc" : {
                "Value" : { "Ref" : "vpc" }
            },
            "igwXsegmentXigw" : 
            {
                "Value" : { "Ref" : "igw" }
            }
            [#if jumpServer]
                [#assign tier = getTier("mgmt")]
                ,"securityGroupXmgmtXnat" : {
                    "Value" : { "Ref" : "securityGroupX${tier.Id}XallXnat" }
                }
            [/#if]
            [#list tiers as tier]
                [#list zones as zone]
                    ,"subnetX${tier.Id}X${zone.Id}" : {
                        "Value" : { "Ref" : "subnetX${tier.Id}X${zone.Id}" }
                    }
                [/#list]
            [/#list]
            [#assign sliceCount += 1]
        [/#if]
        
        [#if slice?contains("s3")]
            [#if sliceCount > 0],[/#if]
            "s3XsegmentXoperations" : {
                "Value" : { "Ref" : "s3Xoperations" }
            },
            "s3XsegmentXdata" : {
                "Value" : { "Ref" : "s3Xdata" }
            }
            [#assign sliceCount += 1]
        [/#if]
    }
}






