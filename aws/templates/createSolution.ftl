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
[#assign segmentDomain = getKey("domainXsegmentXdomain")]
[#assign segmentDomainQualifier = getKey("domainXsegmentXqualifier")]
[#assign certificateId = getKey("domainXsegmentXcertificate")]

[#-- Buckets --]
[#assign credentialsBucket = getKey("s3XaccountXcredentials")!"unknown"]
[#assign codeBucket = getKey("s3XaccountXcode")!"unknown"]
[#assign operationsBucket = getKey("s3XsegmentXoperations")!getKey("s3XsegmentXlogs")]
[#assign dataBucket = getKey("s3XsegmentXdata")!getKey("s3XsegmentXbackups")]

[#-- Get stack output --]
[#function getKey key]
    [#list stackOutputsObject as pair]
        [#if pair.OutputKey==key]
            [#return pair.OutputValue]
        [/#if]
    [/#list]
[/#function]

[#-- Solution --]
[#assign sshPerSegment = segmentObject.SSHPerSegment]
[#assign solnMultiAZ = solutionObject.MultiAZ!environmentObject.MultiAZ!false]
[#assign vpc = getKey("vpcXsegmentXvpc")]
[#assign securityGroupNAT = getKey("securityGroupXmgmtXnat")!"none"]

[#-- Required tiers --]
[#assign tiers = []]
[#list segmentObject.Tiers.Order as tierId]
    [#if blueprintObject.Tiers[tierId]??]
        [#assign tier = blueprintObject.Tiers[tierId]]
        [#if tier.Components??]
            [#assign tiers += [tier]]
        [/#if]
    [/#if]
[/#list]

[#-- Required zones --]
[#assign zones = []]
[#list segmentObject.Zones.Order as zoneId]
    [#if regions[region].Zones[zoneId]??]
        [#assign zone = regions[region].Zones[zoneId]]
        [#assign zones += [zone]]
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

[#-- Get storage settings --]
[#function getStorage tier component type]
    [#assign tc = tier.Id + "-" + component.Id]
    [#assign defaultProfile = "default"]
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

[#macro createBlockDevices storageProfile]
    [#if (storageProfile.Volumes)?? ]
        "BlockDeviceMappings" : [
            [#list storageProfile.Volumes?values as volume]
                [#if volume?is_hash]
                    {
                        "DeviceName" : "${volume.Device}",
                        "Ebs" : {
                            "DeleteOnTermination" : true,
                            "Encrypted" : false,
                            "VolumeSize" : "${volume.Size}",
                            "VolumeType" : "gp2"
                        }
                    },
                [/#if]
            [/#list]
            {
                "DeviceName" : "/dev/sdc",
                "VirtualName" : "ephemeral0"
            },
            {
                "DeviceName" : "/dev/sdt",
                "VirtualName" : "ephemeral1"
            }
        ],
    [/#if]
[/#macro]

[#macro createTargetGroup tier component source destination name]
    "tgX${tier.Id}X${component.Id}X${source.Port?c}X${name}" : {
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
                { "Key" : "cot:tier", "Value" : "${tier.Id}" },
                { "Key" : "cot:component", "Value" : "${component.Id}" },
                { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}-${source.Port?c}-${name}" }
            ],
            "VpcId": "${vpc}"
        }
    }
[/#macro]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    "Resources" : {
        [#assign count = 0]
        [#list tiers as tier]
            [#if tier.Components??]
                [#list tier.Components?values as component]
                    [#if component?is_hash && component.Slices?seq_contains(slice)]
                        [#if count > 0],[/#if]
                        [#if component.MultiAZ??] 
                            [#assign multiAZ =  component.MultiAZ]
                        [#else]
                            [#assign multiAZ =  solnMultiAZ]
                        [/#if]
    
                        [#-- Security Group --]
                        [#if ! (component.S3?? || component.SQS?? || component.ElasticSearch??) ]
                            "securityGroupX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::EC2::SecurityGroup",
                                "Properties" : {
                                    "GroupDescription": "Security Group for ${tier.Name}-${component.Name}",
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
                                        { "Key" : "cot:tier", "Value" : "${tier.Id}" },
                                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}" }
                                    ]
                                }
                            },
                        [/#if]

                        [#-- S3 --]
                        [#if component.S3??]
                            [#assign s3 = component.S3]
                            [#-- Current bucket naming --]
                            [#if s3.Name != "S3"]
                                [#assign bucketName = s3.Name + segmentDomainQualifier + "." + segmentDomain]
                            [#else]
                                [#assign bucketName = component.Name + segmentDomainQualifier + "." + segmentDomain]
                            [/#if]
                            [#-- Support presence of existing s3 buckets (naming has changed over time) --]
                            [#assign bucketName = getKey("s3XsegmentX" + component.Id)!bucketName]
                            "s3X${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::S3::Bucket",
                                "Properties" : {
                                    "BucketName" : "${bucketName}",
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
                                        { "Key" : "cot:component", "Value" : "${component.Id}" }
                                    ]
                                    [#if s3.Lifecycle??]
                                        ,"LifecycleConfiguration" : {
                                            "Rules" : [
                                                {
                                                    "Id" : "default",
                                                    [#if s3.Lifecycle.Expiration??]
                                                        "ExpirationInDays" : ${s3.Lifecycle.Expiration},
                                                    [/#if]
                                                    "Status" : "Enabled"
                                                }
                                            ]
                                        }
                                    [/#if]
                                    [#if s3.Notifications??]
                                        ,"NotificationConfiguration" : {
                                        [#if s3.Notifications.SQS??]
                                            "QueueConfigurations" : [
                                                [#assign queueCount = 0]
                                                [#list s3.Notifications.SQS?values as queue]
                                                    [#if queue?is_hash]
                                                        [#if queueCount > 0],[/#if]
                                                        {
                                                            "Event" : "s3:ObjectCreated:*",
                                                            "Queue" : "${getKey("sqsX"+tier.Id+"X"+queue.Id+"Xarn")}"
                                                        },
                                                        {
                                                            "Event" : "s3:ObjectRemoved:*",
                                                            "Queue" : "${getKey("sqsX"+tier.Id+"X"+queue.Id+"Xarn")}"
                                                        },
                                                        {
                                                            "Event" : "s3:ReducedRedundancyLostObject",
                                                            "Queue" : "${getKey("sqsX"+tier.Id+"X"+queue.Id+"Xarn")}"
                                                        }
                                                        [#assign queueCount += 1]
                                                    [/#if]
                                                [/#list]
                                            ]
                                        [/#if]
                                        }
                                    [/#if]
                                }
                                [#if s3.Notifications??]
                                    ,"DependsOn" : [
                                        [#if (s3.Notifications.SQS)??]
                                            [#assign queueCount = 0]
                                            [#list s3.Notifications.SQS?values as queue]
                                                 [#if queue?is_hash]
                                                    [#if queueCount > 0],[/#if]
                                                    "s3X${tier.Id}X${component.Id}X${queue.Id}Xpolicy"
                                                    [#assign queueCount += 1]
                                                 [/#if]
                                            [/#list]
                                        [/#if]
                                    ]
                                [/#if]
                            }
                            [#if (s3.Notifications.SQS)??]
                                [#assign queueCount = 0]
                                [#list s3.Notifications.SQS?values as queue]
                                    [#if queue?is_hash]
                                        ,"s3X${tier.Id}X${component.Id}X${queue.Id}Xpolicy" : {
                                            "Type" : "AWS::SQS::QueuePolicy",
                                            "Properties" : {
                                                "PolicyDocument" : {
                                                    "Version" : "2012-10-17",
                                                    "Id" : "s3X${tier.Id}X${component.Id}X${queue.Id}Xpolicy",
                                                    "Statement" : [
                                                        {
                                                            "Effect" : "Allow",
                                                            "Principal" : "*",
                                                            "Action" : "sqs:SendMessage",
                                                            "Resource" : "*",
                                                            "Condition" : {
                                                                "ArnLike" : {
                                                                    "aws:sourceArn" : "arn:aws:s3:::*"
                                                                }
                                                            }
                                                        }
                                                    ]
                                                },
                                                "Queues" : [ "${getKey("sqsX"+tier.Id+"X"+queue.Id+"Xurl")}" ]
                                            }
                                        }
                                    [/#if]
                                [/#list]
                            [/#if]
                            [#assign count += 1]
                        [/#if]

                        [#-- SQS --]
                        [#if component.SQS??]
                            [#assign sqs = component.SQS]
                            "sqsX${tier.Id}X${component.Id}":{
                                "Type" : "AWS::SQS::Queue",
                                "Properties" : {
                                    [#if sqs.Name != "SQS"]
                                        "QueueName" : "${sqs.Name}"
                                    [#else]
                                        "QueueName" : "${productName}-${environmentName}-${component.Name}"
                                    [/#if]
                                    [#if sqs.DelaySeconds??],"DelaySeconds" : ${sqs.DelaySeconds?c}[/#if]
                                    [#if sqs.MaximumMessageSize??],"MaximumMessageSize" : ${sqs.MaximumMessageSize?c}[/#if]
                                    [#if sqs.MessageRetentionPeriod??],"MessageRetentionPeriod" : ${sqs.MessageRetentionPeriod?c}[/#if]
                                    [#if sqs.ReceiveMessageWaitTimeSeconds??],"ReceiveMessageWaitTimeSeconds" : ${sqs.ReceiveMessageWaitTimeSeconds?c}[/#if]
                                    [#if sqs.VisibilityTimeout??],"VisibilityTimeout" : ${sqs.VisibilityTimeout?c}[/#if]
                                }
                            }
                            [#assign count += 1]
                        [/#if]
                        
                        [#-- ELB --]
                        [#if component.ELB??]
                            [#assign elb = component.ELB]
                            [#list elb.PortMappings as mapping]
                                [#assign source = ports[portMappings[mapping].Source]]
                                "securityGroupIngressX${tier.Id}X${component.Id}X${source.Port?c}" : {
                                    "Type" : "AWS::EC2::SecurityGroupIngress",
                                    "Properties" : {
                                        "GroupId": {"Ref" : "securityGroupX${tier.Id}X${component.Id}"},
                                        "IpProtocol": "${source.IPProtocol}",
                                        "FromPort": "${source.Port?c}",
                                        "ToPort": "${source.Port?c}",
                                        "CidrIp": "0.0.0.0/0"
                                    }
                                },
                            [/#list]
                            "elbX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::ElasticLoadBalancing::LoadBalancer",
                                "Properties" : {
                                    [#if multiAZ]
                                        "Subnets" : [
                                            [#list zones as zone]
                                                "${getKey("subnetX"+tier.Id+"X"+zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                                            [/#list]
                                        ],
                                        "CrossZone" : true,
                                    [#else]
                                        "Subnets" : [
                                            "${getKey("subnetX"+tier.Id+"X"+zones[0].Id)}"
                                        ],
                                    [/#if]
                                    "Listeners" : [
                                        [#list elb.PortMappings as mapping]
                                            [#assign source = ports[portMappings[mapping].Source]]
                                            [#assign destination = ports[portMappings[mapping].Destination]]
                                            {
                                                "LoadBalancerPort" : "${source.Port?c}",
                                                "Protocol" : "${source.Protocol}",
                                                "InstancePort" : "${destination.Port?c}",
                                                "InstanceProtocol" : "${destination.Protocol}"
                                                [#if (source.Certificate)?? && source.Certificate]
                                                    ,"SSLCertificateId" :
                                                        [#if getKey("certificateX" + certificateId)??]
                                                            "${getKey("certificateX" + certificateId)}"
                                                        [#else]
                                                            {
                                                                "Fn::Join" : [
                                                                    "",
                                                                    [
                                                                        "arn:aws:iam::",
                                                                        {"Ref" : "AWS::AccountId"},
                                                                        ":server-certificate/ssl/${certificateId}/${certificateId}-ssl"
                                                                    ]
                                                                ]
                                                            }
                                                        [/#if]
                                                [/#if]
                                            }
                                            [#if !(mapping == elb.PortMappings?last)],[/#if]
                                        [/#list]
                                    ],
                                    "HealthCheck" : {
                                        [#assign destination = ports[portMappings[elb.PortMappings[0]].Destination]]
                                        "Target" : "${(destination.HealthCheck.Protocol)!destination.Protocol}:${destination.Port?c}${(elb.HealthCheck.Path)!destination.HealthCheck.Path}",
                                        "HealthyThreshold" : "${(elb.HealthCheck.HealthyThreshold)!destination.HealthCheck.HealthyThreshold}",
                                        "UnhealthyThreshold" : "${(elb.HealthCheck.UnhealthyThreshold)!destination.HealthCheck.UnhealthyThreshold}",
                                        "Interval" : "${(elb.HealthCheck.Interval)!destination.HealthCheck.Interval}",
                                        "Timeout" : "${(elb.HealthCheck.Timeout)!destination.HealthCheck.Timeout}"
                                    },
                                    [#if (elb.Logs)?? && (elb.Logs == true)]
                                        "AccessLoggingPolicy" : {
                                            "EmitInterval" : 5,
                                            "Enabled" : true,
                                            "S3BucketName" : "${operationsBucket}"
                                        },
                                    [/#if]
                                    "Scheme" : "${(tier.RouteTable == "external")?string("internet-facing","internal")}",
                                    "SecurityGroups":[ {"Ref" : "securityGroupX${tier.Id}X${component.Id}"} ],
                                    "LoadBalancerName" : "${productId}-${segmentId}-${tier.Id}-${component.Id}",
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
                                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}" }
                                    ]
                                }
                            }
                            [#assign count += 1]
                        [/#if]
        
                        [#-- ALB --]
                        [#if component.ALB??]
                            [#assign alb = component.ALB]
                            [#list alb.PortMappings as mapping]
                                [#assign source = ports[portMappings[mapping].Source]]
                                [#assign destination = ports[portMappings[mapping].Destination]]
                                "securityGroupIngressX${tier.Id}X${component.Id}X${source.Port?c}" : {
                                    "Type" : "AWS::EC2::SecurityGroupIngress",
                                    "Properties" : {
                                        "GroupId": {"Ref" : "securityGroupX${tier.Id}X${component.Id}"},
                                        "IpProtocol": "${source.IPProtocol}",
                                        "FromPort": "${source.Port?c}",
                                        "ToPort": "${source.Port?c}",
                                        "CidrIp": "0.0.0.0/0"
                                    }
                                },
                                "listenerX${tier.Id}X${component.Id}X${source.Port?c}" : {
                                    "Type" : "AWS::ElasticLoadBalancingV2::Listener",
                                    "Properties" : {
                                        [#if (source.Certificate)?? && source.Certificate]
                                            "Certificates" : [ 
                                                {
                                                    "CertificateArn" :
                                                        [#if getKey("certificateX" + certificateId)??]
                                                            "${getKey("certificateX" + certificateId)}"
                                                        [#else]
                                                            {
                                                                "Fn::Join" : [
                                                                    "",
                                                                    [
                                                                        "arn:aws:iam::",
                                                                        {"Ref" : "AWS::AccountId"},
                                                                        ":server-certificate/ssl/${certificateId}/${certificateId}-ssl"
                                                                    ]
                                                                ]
                                                            }
                                                        [/#if]
                                                }
                                            ],
                                        [/#if]
                                        "DefaultActions" : [ 
                                            {
                                              "TargetGroupArn" : { "Ref" : "tgX${tier.Id}X${component.Id}X${source.Port?c}Xdefault" },
                                              "Type" : "forward"
                                            }
                                        ],
                                        "LoadBalancerArn" : { "Ref" : "albX${tier.Id}X${component.Id}" },
                                        "Port" : ${source.Port?c},
                                        "Protocol" : "${source.Protocol}"
                                    }   
                                },
                                [@createTargetGroup tier=tier component=component source=source destination=destination name="default" /],
                            [/#list]
                            "albX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::ElasticLoadBalancingV2::LoadBalancer",
                                "Properties" : {
                                    "Subnets" : [
                                        [#list zones as zone]
                                            "${getKey("subnetX"+tier.Id+"X"+zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                                        [/#list]
                                    ],
                                    "Scheme" : "${(tier.RouteTable == "external")?string("internet-facing","internal")}",
                                    "SecurityGroups":[ {"Ref" : "securityGroupX${tier.Id}X${component.Id}"} ],
                                    "Name" : "${productId}-${segmentId}-${tier.Id}-${component.Id}",
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
                                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}" }
                                    ]
                                }
                            }
                            [#assign count += 1]
                        [/#if]

                        [#-- EC2 --]
                        [#if component.EC2??]
                            [#assign ec2 = component.EC2]
                            [#assign fixedIP = ec2.FixedIP?? && ec2.FixedIP]
                            [#list ec2.Ports as port]
                                "securityGroupIngressX${tier.Id}X${component.Id}X${ports[port].Port?c}" : {
                                    "Type" : "AWS::EC2::SecurityGroupIngress",
                                    "Properties" : {
                                        "GroupId": {"Ref" : "securityGroupX${tier.Id}X${component.Id}"},
                                        "IpProtocol": "${ports[port].IPProtocol}", 
                                        "FromPort": "${ports[port].Port?c}", 
                                        "ToPort": "${ports[port].Port?c}", 
                                        "CidrIp": "0.0.0.0/0"
                                    }
                                },
                            [/#list]
                                    
                            "roleX${tier.Id}X${component.Id}": {
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
                                            "PolicyName": "${tier.Id}-${component.Id}-basic",
                                            "PolicyDocument" : {
                                                "Version": "2012-10-17",
                                                "Statement": [
                                                    {
                                                        "Resource": [
                                                            "arn:aws:s3:::${codeBucket}",
                                                            "arn:aws:s3:::${operationsBucket}"
                                                        ],
                                                        "Action": [
                                                            "s3:List*"
                                                        ],
                                                        "Effect": "Allow"
                                                    },
                                                    {
                                                        "Resource": [
                                                            "arn:aws:s3:::${codeBucket}/*"
                                                        ],
                                                        "Action": [
                                                            "s3:GetObject"
                                                        ],
                                                        "Effect": "Allow"
                                                    },
                                                    {
                                                        "Resource": [
                                                            "arn:aws:s3:::${operationsBucket}/DOCKERLogs/*"
                                                        ],
                                                        "Action": [
                                                            "s3:PutObject"
                                                        ],
                                                        "Effect": "Allow"
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                }
                            },
            
                            "instanceProfileX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::IAM::InstanceProfile",
                                "Properties" : {
                                    "Path" : "/",
                                    "Roles" : [ 
                                        { "Ref" : "roleX${tier.Id}X${component.Id}" } 
                                    ]
                                }
                            },
            
                            [#assign ec2Count = 0]
                            [#list zones as zone]
                                [#if multiAZ || (zones[0].Id = zone.Id)]
                                    [#if ec2Count > 0],[/#if]
                                    "ec2InstanceX${tier.Id}X${component.Id}X${zone.Id}": {
                                        "Type": "AWS::EC2::Instance",
                                        "Metadata": {
                                            "AWS::CloudFormation::Init": {
                                                "configSets" : {
                                                    "ec2" : ["dirs", "bootstrap", "puppet"]
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
                                                                        "echo \"cot:component=${component.Id}\"\n",
                                                                        "echo \"cot:zone=${zone.Id}\"\n",
                                                                        "echo \"cot:name=${productName}-${segmentName}-${tier.Name}-${component.Name}-${zone.Name}\"\n",
                                                                        "echo \"cot:role=${component.Role}\"\n",
                                                                        "echo \"cot:credentials=${credentialsBucket}\"\n",
                                                                        "echo \"cot:code=${codeBucket}\"\n",
                                                                        "echo \"cot:logs=${operationsBucket}\"\n",
                                                                        "echo \"cot:backup=${dataBucket}\"\n"
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
                                                                        "REGION=$(/etc/codeontap/facts.sh | grep cot:accountRegion= | cut -d '=' -f 2)\n",
                                                                        "CODE=$(/etc/codeontap/facts.sh | grep cot:code= | cut -d '=' -f 2)\n",
                                                                        "aws --region ${r"${REGION}"} s3 sync s3://${r"${CODE}"}/bootstrap/centos/ /opt/codeontap/bootstrap && chmod 0755 /opt/codeontap/bootstrap/*.sh\n"
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
                                                        [#if ec2.LoadBalanced]
                                                            ,"03RegisterWithLB" : {
                                                                "command" : "/opt/codeontap/bootstrap/register.sh",
                                                                "env" : { 
                                                                    "LOAD_BALANCER" : { "Ref" : "elbXelbX${component.Id}" } 
                                                                },
                                                                "ignoreErrors" : "false"
                                                            }
                                                        [/#if]
                                                    }
                                                },
                                                "puppet": {
                                                    "commands": {
                                                        "01SetupPuppet" : {
                                                            "command" : "/opt/codeontap/bootstrap/puppet.sh",
                                                            "ignoreErrors" : "false"
                                                        }
                                                    }
                                                }
                                            }
                                        },
                                        [#assign processorProfile = getProcessor(tier, component, "EC2")]
                                        [#assign storageProfile = getStorage(tier, component, "EC2")]
                                        "Properties": {
                                            [@createBlockDevices storageProfile=storageProfile /]
                                            "DisableApiTermination" : false,
                                            "EbsOptimized" : false,
                                            "IamInstanceProfile" : { "Ref" : "instanceProfileX${tier.Id}X${component.Id}" },
                                            "ImageId": "${regionObject.AMIs.Centos.EC2}",
                                            "InstanceInitiatedShutdownBehavior" : "stop",
                                            "InstanceType": "${processorProfile.Processor}",
                                            "KeyName": "${productName + sshPerSegment?string("-" + segmentName,"")}",
                                            "Monitoring" : false,
                                            "NetworkInterfaces" : [
                                                {
                                                    "AssociatePublicIpAddress" : ${(((tier.RouteTable) == "external") && !fixedIP)?string("true","false")},
                                                    "DeleteOnTermination" : true,
                                                    "DeviceIndex" : "0",
                                                    "SubnetId" : "${getKey("subnetX"+tier.Id+"X"+zone.Id)}",
                                                    "GroupSet" : [ 
                                                        {"Ref" : "securityGroupX${tier.Id}X${component.Id}"} 
                                                        [#if securityGroupNAT != "none"]
                                                            , "${securityGroupNAT}"
                                                        [/#if] 
                                                    ] 
                                                }
                                            ],
                                            "SourceDestCheck" : true,
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
                                                { "Key" : "cot:component", "Value" : "${component.Id}" },
                                                { "Key" : "cot:zone", "Value" : "${zone.Id}" },
                                                { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}-${zone.Name}" }
                                            ],
                                            "UserData" : { 
                                                "Fn::Base64" : { 
                                                    "Fn::Join" : [
                                                        "", 
                                                        [
                                                            "#!/bin/bash -ex\n",
                                                            "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\n",
                                                            "yum install -y aws-cfn-bootstrap\n",
                                                            "# Remainder of configuration via metadata\n",
                                                            "/opt/aws/bin/cfn-init -v",
                                                            "         --stack ", { "Ref" : "AWS::StackName" },
                                                            "         --resource ec2InstanceX${tier.Id}X${component.Id}X${zone.Id}",
                                                            "         --region ${regionId} --configsets ec2\n"
                                                        ]
                                                    ]
                                                }
                                            }
                                        }
                                        [#if ec2.LoadBalanced]
                                            ,"DependsOn" : "elbXelbX${component.Id}"
                                        [/#if]
                                    }
                                    [#if fixedIP]
                                        ,"eipX${tier.Id}X${component.Id}X${zone.Id}": {
                                            "Type" : "AWS::EC2::EIP",
                                            "Properties" : {
                                                "InstanceId" : { "Ref" : "ec2InstanceX${tier.Id}X${component.Id}X${zone.Id}" },
                                                "Domain" : "vpc"
                                            }
                                        }
                                    [/#if]
                                    [#assign ec2Count += 1]
                                [/#if]
                            [/#list]
                            [#assign count += 1]
                        [/#if]

                        [#-- ECS --]
                        [#if component.ECS??]
                            [#assign ecs = component.ECS]
                            [#assign processorProfile = getProcessor(tier, component, "ECS")]
                            [#assign maxSize = processorProfile.MaxPerZone]
                            [#if multiAZ]
                                [#assign maxSize = maxSize * zones?size]
                            [/#if]
                            [#assign storageProfile = getStorage(tier, component, "ECS")]
                            [#assign fixedIP = ecs.FixedIP?? && ecs.FixedIP]
                
                            "ecsX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::ECS::Cluster"
                            },
                            
                            "roleX${tier.Id}X${component.Id}": {
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
                                    "ManagedPolicyArns" : ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"],
                                    "Policies": [
                                        {
                                            "PolicyName": "${tier.Id}-${component.Id}-docker",
                                            "PolicyDocument" : {
                                                "Version": "2012-10-17",
                                                "Statement": [
                                                    {
                                                        "Effect": "Allow",
                                                        "Action": ["s3:GetObject"],
                                                        "Resource": [
                                                            "arn:aws:s3:::${credentialsBucket}/${accountId}/alm/docker/*"
                                                        ]
                                                    },
                                                    [#if fixedIP]
                                                        {
                                                            "Effect" : "Allow",
                                                            "Action" : [
                                                                "ec2:DescribeAddresses",
                                                                "ec2:AssociateAddress"
                                                            ],
                                                            "Resource": "*"
                                                        },
                                                    [/#if]
                                                    {
                                                        "Resource": [
                                                            "arn:aws:s3:::${codeBucket}",
                                                            "arn:aws:s3:::${operationsBucket}"
                                                        ],
                                                        "Action": [
                                                            "s3:List*"
                                                        ],
                                                        "Effect": "Allow"
                                                    },
                                                    {
                                                        "Resource": [
                                                            "arn:aws:s3:::${codeBucket}/*"
                                                        ],
                                                        "Action": [
                                                            "s3:GetObject"
                                                        ],
                                                        "Effect": "Allow"
                                                    },
                                                    {
                                                        "Resource": [
                                                            "arn:aws:s3:::${operationsBucket}/DOCKERLogs/*"
                                                        ],
                                                        "Action": [
                                                            "s3:PutObject"
                                                        ],
                                                        "Effect": "Allow"
                                                    }
                                                ]
                                            }
                                        }
                                    ]
                                }
                            },
                
                            "instanceProfileX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::IAM::InstanceProfile",
                                "Properties" : {
                                    "Path" : "/",
                                    "Roles" : [ { "Ref" : "roleX${tier.Id}X${component.Id}" } ]
                                }
                            },
                    
                            "roleX${tier.Id}X${component.Id}Xservice": {
                                "Type" : "AWS::IAM::Role",
                                "Properties" : {
                                    "AssumeRolePolicyDocument" : {
                                        "Version": "2012-10-17",
                                        "Statement": [ 
                                            {
                                                "Effect": "Allow",
                                                "Principal": { "Service": [ "ecs.amazonaws.com" ] },
                                                "Action": [ "sts:AssumeRole" ]
                                            }
                                        ]
                                    },
                                    "Path": "/",
                                    "ManagedPolicyArns" : ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"]
                                }
                            },
                    
                            [#if fixedIP]
                                [#list 1..maxSize as index]
                                    "eipX${tier.Id}X${component.Id}X${index}": {
                                        "Type" : "AWS::EC2::EIP",
                                        "Properties" : {
                                            "Domain" : "vpc"
                                        }
                                    },
                                [/#list]
                            [/#if]
                
                            "asgX${tier.Id}X${component.Id}": {
                                "Type": "AWS::AutoScaling::AutoScalingGroup",
                                "Metadata": {
                                    "AWS::CloudFormation::Init": {
                                        "configSets" : {
                                            "ecs" : ["dirs", "bootstrap", "ecs"]
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
                                                                "echo \"cot:component=${component.Id}\"\n",
                                                                "echo \"cot:role=${component.Role}\"\n",
                                                                "echo \"cot:credentials=${credentialsBucket}\"\n",
                                                                "echo \"cot:code=${codeBucket}\"\n",
                                                                "echo \"cot:logs=${operationsBucket}\"\n",
                                                                "echo \"cot:backup=${dataBucket}\"\n"
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
                                                                "REGION=$(/etc/codeontap/facts.sh | grep cot:accountRegion= | cut -d '=' -f 2)\n",
                                                                "CODE=$(/etc/codeontap/facts.sh | grep cot:code= | cut -d '=' -f 2)\n",
                                                                "aws --region ${r"${REGION}"} s3 sync s3://${r"${CODE}"}/bootstrap/centos/ /opt/codeontap/bootstrap && chmod 0755 /opt/codeontap/bootstrap/*.sh\n"
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
                                                [#if fixedIP]
                                                    ,"03AssignIP" : {
                                                        "command" : "/opt/codeontap/bootstrap/eip.sh",
                                                        "env" : { 
                                                            "EIP_ALLOCID" : { 
                                                                "Fn::Join" : [
                                                                    " ", 
                                                                    [
                                                                        [#list 1..maxSize as index]
                                                                            { "Fn::GetAtt" : ["eipX${tier.Id}X${component.Id}X${index}", "AllocationId"] }
                                                                            [#if index != maxSize],[/#if]
                                                                        [/#list]
                                                                    ]
                                                                ]
                                                            }
                                                        },
                                                        "ignoreErrors" : "false"
                                                    }
                                                [/#if]
                                                }
                                            },
                                            "ecs": {
                                                "commands": {
                                                    "01Fluentd" : {
                                                        "command" : "/opt/codeontap/bootstrap/fluentd.sh",
                                                        "ignoreErrors" : "false"
                                                    },
                                                    "02ConfigureCluster" : {
                                                        "command" : "/opt/codeontap/bootstrap/ecs.sh",
                                                        "env" : { 
                                                        "ECS_CLUSTER" : { "Ref" : "ecsX${tier.Id}X${component.Id}" },
                                                        "ECS_LOG_DRIVER" : "fluentd"
                                                    },
                                                    "ignoreErrors" : "false"
                                                }
                                            }
                                        }
                                    }
                                },
                                "Properties": {
                                    "Cooldown" : "30",
                                    "LaunchConfigurationName": {"Ref": "launchConfigX${tier.Id}X${component.Id}"},
                                    [#if multiAZ]
                                        "MinSize": "${processorProfile.MinPerZone * zones?size}",
                                        "MaxSize": "${maxSize}",
                                        "DesiredCapacity": "${processorProfile.DesiredPerZone * zones?size}",
                                        "VPCZoneIdentifier": [ 
                                            [#list zones as zone]
                                                "${getKey("subnetX"+tier.Id+"X"+zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                                            [/#list]
                                        ],
                                    [#else]
                                        "MinSize": "${processorProfile.MinPerZone}",
                                        "MaxSize": "${maxSize}",
                                        "DesiredCapacity": "${processorProfile.DesiredPerZone}",
                                        "VPCZoneIdentifier" : ["${getKey("subnetX"+tier.Id+"X"+zones[0].Id)}"],
                                    [/#if]
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
                                        { "Key" : "cot:component", "Value" : "${component.Id}", "PropagateAtLaunch" : "True"},
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}", "PropagateAtLaunch" : "True" }
                                    ]
                                }
                            },
                    
                            "launchConfigX${tier.Id}X${component.Id}": {
                                "Type": "AWS::AutoScaling::LaunchConfiguration",
                                "Properties": {
                                    "KeyName": "${productName + sshPerSegment?string("-" + segmentName,"")}",
                                    "ImageId": "${regionObject.AMIs.Centos.ECS}",
                                    "InstanceType": "${processorProfile.Processor}",
                                    [@createBlockDevices storageProfile=storageProfile /]
                                    "SecurityGroups" : [ {"Ref" : "securityGroupX${tier.Id}X${component.Id}"} [#if securityGroupNAT != "none"], "${securityGroupNAT}"[/#if] ], 
                                    "IamInstanceProfile" : { "Ref" : "instanceProfileX${tier.Id}X${component.Id}" },
                                    "AssociatePublicIpAddress" : ${(tier.RouteTable == "external")?string("true","false")},
                                    [#if (processorProfile.ConfigSet)??]
                                        [#assign configSet = processorProfile.ConfigSet]
                                    [#else]
                                        [#assign configSet = "ecs"]
                                    [/#if]
                                    "UserData" : { 
                                        "Fn::Base64" : { 
                                            "Fn::Join" : [
                                                "", 
                                                [
                                                    "#!/bin/bash -ex\n",
                                                    "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\n",
                                                    "yum install -y aws-cfn-bootstrap\n",
                                                    "# Remainder of configuration via metadata\n",
                                                    "/opt/aws/bin/cfn-init -v",
                                                    "         --stack ", { "Ref" : "AWS::StackName" },
                                                    "         --resource asgX${tier.Id}X${component.Id}",
                                                    "         --region ${regionId} --configsets ${configSet}\n"
                                                ]
                                            ]
                                        }
                                    }
                                }
                            }
                            [#assign count += 1]
                        [/#if]

                        [#-- ElastiCache --]
                        [#if component.ElastiCache??]
                            [#assign cache = component.ElastiCache]
                            [#assign engine = cache.Engine]
                            [#switch engine]
                                [#case "memcached"]
                                    [#if cache.EngineVersion??]
                                        [#assign engineVersion = cache.EngineVersion]
                                    [#else]
                                        [#assign engineVersion = "1.4.24"]
                                    [/#if]
                                    [#assign familyVersionIndex = engineVersion?last_index_of(".") - 1]
                                    [#assign family = "memcached" + engineVersion[0..familyVersionIndex]]
                                    [#break]
            
                                [#case "redis"]
                                    [#if cache.EngineVersion??]
                                        [#assign engineVersion = cache.EngineVersion]
                                    [#else]
                                        [#assign engineVersion = "2.8.24"]
                                    [/#if]
                                    [#assign familyVersionIndex = engineVersion?last_index_of(".") - 1]
                                    [#assign family = "redis" + engineVersion[0..familyVersionIndex]]
                                    [#break]
                            [/#switch]
                            "securityGroupIngressX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::EC2::SecurityGroupIngress",
                                "Properties" : {
                                    "GroupId": {"Ref" : "securityGroupX${tier.Id}X${component.Id}"},
                                    "IpProtocol": "${ports[cache.Port].IPProtocol}", 
                                    "FromPort": "${ports[cache.Port].Port?c}", 
                                    "ToPort": "${ports[cache.Port].Port?c}", 
                                    "CidrIp": "0.0.0.0/0"
                                }
                            },
                            "cacheSubnetGroupX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::ElastiCache::SubnetGroup",
                                "Properties" : {
                                    "Description" : "${productName}-${segmentName}-${tier.Name}-${component.Name}",
                                    "SubnetIds" : [ 
                                        [#list zones as zone]
                                            "${getKey("subnetX"+tier.Id+"X"+zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                                        [/#list]
                                    ]
                                }
                            },
                            "cacheParameterGroupX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::ElastiCache::ParameterGroup",
                                "Properties" : {
                                    "CacheParameterGroupFamily" : "${family}",
                                    "Description" : "Parameter group for ${tier.Id}-${component.Id}",
                                    "Properties" : {
                                    }
                                }
                            },
                            [#assign processorProfile = getProcessor(tier, component, "ElastiCache")]
                            "cacheX${tier.Id}X${component.Id}":{
                                "Type":"AWS::ElastiCache::CacheCluster",
                                "Properties":{
                                    "Engine": "${cache.Engine}",
                                    "EngineVersion": "${engineVersion}",
                                    "CacheNodeType" : "${processorProfile.Processor}",
                                    "Port" : ${ports[cache.Port].Port?c},
                                    "CacheParameterGroupName": { "Ref" : "cacheParameterGroupX${tier.Id}X${component.Id}" },
                                    "CacheSubnetGroupName": { "Ref" : "cacheSubnetGroupX${tier.Id}X${component.Id}" },
                                    [#if multiAZ]
                                        "AZMode": "cross-az",
                                        "PreferredAvailabilityZones" : [
                                            [#assign countPerZone = processorProfile.CountPerZone]
                                            [#assign cacheZoneCount = 0]
                                            [#list zones as zone]
                                                [#list 1..countPerZone as i]
                                                    [#if cacheZoneCount > 0],[/#if]
                                                    "${zone.AWSZone}"
                                                    [#assign cacheZoneCount += 1]
                                                [/#list]
                                        [/#list]
                                        ],
                                        "NumCacheNodes" : "${processorProfile.CountPerZone * zones?size}",
                                    [#else]
                                        "AZMode": "single-az",
                                        "PreferredAvailabilityZone" : "${zones[0].AWSZone}",
                                        "NumCacheNodes" : "${processorProfile.CountPerZone}",
                                    [/#if]
                                    [#if (cache.SnapshotRetentionLimit)??]
                                        "SnapshotRetentionLimit" : ${cache.SnapshotRetentionLimit}
                                    [/#if]
                                    "VpcSecurityGroupIds":[
                                        { "Ref" : "securityGroupX${tier.Id}X${component.Id}" }
                                    ],
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
                                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}" } 
                                    ]
                                }
                            }
                            [#assign count += 1]
                        [/#if]
                        
                        [#-- RDS --]
                        [#if component.RDS??]
                            [#assign db = component.RDS]
                            [#assign engine = db.Engine]
                            [#switch engine]
                                [#case "mysql"]
                                    [#if db.EngineVersion??]
                                        [#assign engineVersion = db.EngineVersion]
                                    [#else]
                                        [#assign engineVersion = "5.6"]
                                    [/#if]
                                    [#assign family = "mysql" + engineVersion]
                                [#break]
                            
                                [#case "postgres"]
                                    [#if db.EngineVersion??]
                                        [#assign engineVersion = db.EngineVersion]
                                    [#else]
                                        [#assign engineVersion = "9.4"]
                                    [/#if]
                                    [#assign family = "postgres" + engineVersion]
                                    [#break]
                            [/#switch]
                            "securityGroupIngressX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::EC2::SecurityGroupIngress",
                                "Properties" : {
                                    "GroupId": {"Ref" : "securityGroupX${tier.Id}X${component.Id}"},
                                    "IpProtocol": "${ports[db.Port].IPProtocol}", 
                                    "FromPort": "${ports[db.Port].Port?c}", 
                                    "ToPort": "${ports[db.Port].Port?c}", 
                                    "CidrIp": "0.0.0.0/0"
                                }
                            },
                            "rdsSubnetGroupX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::RDS::DBSubnetGroup",
                                "Properties" : {
                                    "DBSubnetGroupDescription" : "${productName}-${segmentName}-${tier.Name}-${component.Name}",
                                    "SubnetIds" : [ 
                                        [#list zones as zone]
                                            "${getKey("subnetX"+tier.Id+"X"+zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
                                        [/#list]
                                    ],
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
                                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}" } 
                                    ]
                                }
                            },
                            "rdsParameterGroupX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::RDS::DBParameterGroup",
                                "Properties" : {
                                    "Family" : "${family}",
                                    "Description" : "Parameter group for ${tier.Id}-${component.Id}",
                                    "Parameters" : {
                                    },
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
                                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}" } 
                                    ]
                                }
                            },
                            "rdsOptionGroupX${tier.Id}X${component.Id}" : {
                                "Type" : "AWS::RDS::OptionGroup",
                                "Properties" : {
                                    "EngineName": "${engine}",
                                    "MajorEngineVersion": "${engineVersion}",
                                    "OptionGroupDescription" : "Option group for ${tier.Id}/${component.Id}",
                                    "OptionConfigurations" : [
                                    ],
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
                                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}" } 
                                    ]
                                }
                            },
                            [#assign processorProfile = getProcessor(tier, component, "RDS")]
                            "rdsX${tier.Id}X${component.Id}":{
                                "Type":"AWS::RDS::DBInstance",
                                "Properties":{
                                    "Engine": "${engine}",
                                    "EngineVersion": "${engineVersion}",
                                    "DBInstanceClass" : "${processorProfile.Processor}",
                                    "AllocatedStorage": "${db.Size}",
                                    "StorageType" : "gp2",
                                    "Port" : "${ports[db.Port].Port?c}",
                                    "MasterUsername": "${credentialsObject[tier.Id + "-" + component.Id].Login.Username}",
                                    "MasterUserPassword": "${credentialsObject[tier.Id + "-" + component.Id].Login.Password}",
                                    "BackupRetentionPeriod" : "${db.Backup.RetentionPeriod}",
                                    "DBInstanceIdentifier": "${productName}-${segmentName}-${tier.Name}-${component.Name}",
                                    "DBName": "${productName}",
                                    "DBSubnetGroupName": { "Ref" : "rdsSubnetGroupX${tier.Id}X${component.Id}" },
                                    "DBParameterGroupName": { "Ref" : "rdsParameterGroupX${tier.Id}X${component.Id}" },
                                    "OptionGroupName": { "Ref" : "rdsOptionGroupX${tier.Id}X${component.Id}" },
                                    [#if multiAZ]
                                        "MultiAZ": true,
                                    [#else]
                                        "AvailabilityZone" : "${zone[0].AWSZone}",
                                    [/#if]
                                    "VPCSecurityGroups":[
                                        { "Ref" : "securityGroupX${tier.Id}X${component.Id}" }
                                    ],
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
                                        { "Key" : "cot:component", "Value" : "${component.Id}" },
                                        { "Key" : "Name", "Value" : "${productName}-${segmentName}-${tier.Name}-${component.Name}" } 
                                    ]
                                }
                            }
                            [#assign count += 1]
                        [/#if]
                        [#-- ElasticSearch --]
                        [#if component.ElasticSearch??]
                            [#assign es = component.ElasticSearch]
                            [#assign processorProfile = getProcessor(tier, component, "ElasticSearch")]
                            [#assign storageProfile = getStorage(tier, component, "ElasticSearch")]
                            "esX${tier.Id}X${component.Id}":{
                                "Type" : "AWS::Elasticsearch::Domain",
                                "Properties" : {
                                    "AccessPolicies" : {
                                        "Version": "2012-10-17",
                                        "Statement": [
                                            {
                                                "Sid": "",
                                                "Effect": "Allow",
                                                "Principal": {
                                                    "AWS": "*"
                                                },
                                                "Action": "es:*",
                                                "Resource": "*",
                                                "Condition": {
                                                    "IpAddress": {
                                                        [#assign ipCount = 0]
                                                        "aws:SourceIp": [
                                                            [#list zones as zone]
                                                                [#if (getKey("eipXmgmtXnatX" + zone.Id + "Xip")??)]
                                                                    [#if ipCount > 0],[/#if]
                                                                    "${getKey("eipXmgmtXnatX" + zone.Id + "Xip")}"
                                                                    [#assign ipCount += 1]
                                                                [/#if]
                                                            [/#list]
                                                            [#list 1..20 as i]
                                                                [#if (getKey("eipXmgmtXnatXexternalX" + i)??)]
                                                                    [#if ipCount > 0],[/#if]
                                                                    "${getKey("eipXmgmtXnatXexternalX" + i)}"
                                                                    [#assign ipCount += 1]
                                                                [/#if]
                                                            [/#list]
                                                            [#if (segmentObject.IPAddressBlocks)??]
                                                                [#list segmentObject.IPAddressBlocks?values as groupValue]
                                                                    [#if groupValue?is_hash]
                                                                        [#list groupValue?values as entryValue]
                                                                            [#if entryValue?is_hash && (entryValue.CIDR)?has_content ]
                                                                                [#if (!entryValue.Usage??) || entryValue.Usage?seq_contains("es") ]
                                                                                    [#if (entryValue.CIDR)?is_sequence]
                                                                                        [#list entryValue.CIDR as CIDRBlock]
                                                                                            [#if ipCount > 0],[/#if]
                                                                                            "${CIDRBlock}"
                                                                                            [#assign ipCount += 1]
                                                                                        [/#list]
                                                                                    [#else]
                                                                                        [#if ipCount > 0],[/#if]
                                                                                        "${entryValue.CIDR}"
                                                                                        [#assign ipCount += 1]
                                                                                    [/#if]
                                                                                [/#if]
                                                                            [/#if]
                                                                        [/#list]
                                                                    [/#if]
                                                                [/#list]
                                                            [/#if]
                                                        ]
                                                    }
                                                }
                                            }
                                        ]
                                    },
                                    [#if es.AdvancedOptions??]
                                        "AdvancedOptions" : {
                                            [#list es.AdvancedOptions as option]
                                                "${option.Id}" : "${option.Value}"
                                                [#if option.Id != es.AdvancedOptions?last.Id],[/#if]
                                            [/#list]
                                        },
                                    [/#if]
                                    [#-- In order to permit updates to the security policy, don't name the domain. --]
                                    [#-- Use tags in the console to find the right one --]
                                    [#-- "DomainName" : "${productName}-${segmentId}-${tier.Id}-${component.Id}", --]
                                    [#if es.Version??]
                                        "ElasticsearchVersion" : "${es.Version}",
                                    [#else]
                                        "ElasticsearchVersion" : "2.3",
                                    [/#if]
                                    [#if (storageProfile.Volumes["codeontap"])??]
                                        [#assign volume = storageProfile.Volumes["codeontap"]]
                                        "EBSOptions" : {
                                            "EBSEnabled" : true,
                                            [#if volume.Iops??]"Iops" : ${volume.Iops},[/#if]
                                            "VolumeSize" : ${volume.Size},
                                            [#if volume.Type??]
                                                "VolumeType" : "${volume.Type}"
                                            [#else]
                                                "VolumeType" : "gp2"
                                            [/#if]
                                        },
                                    [/#if]
                                    "ElasticsearchClusterConfig" : {
                                        [#if processorProfile.Master??]
                                            [#assign master = processorProfile.Master]
                                            "DedicatedMasterEnabled" : true,
                                            "DedicatedMasterCount" : ${master.Count},
                                            "DedicatedMasterType" : "${master.Processor}",
                                        [#else]
                                            "DedicatedMasterEnabled" : false,
                                        [/#if]
                                        "InstanceType" : "${processorProfile.Processor}",
                                        "ZoneAwarenessEnabled" : ${multiAZ?string("true","false")},
                                        [#if multiAZ]
                                            "InstanceCount" : ${processorProfile.CountPerZone * zones?size}
                                        [#else]
                                            "InstanceCount" : ${processorProfile.CountPerZone}
                                        [/#if]
                                    },
                                    [#if (es.Snapshot.Hour)??]
                                        "SnapshotOptions" : {
                                            "AutomatedSnapshotStartHour" : ${es.Snapshot.Hour}
                                        },
                                    [/#if]
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
                                        { "Key" : "cot:component", "Value" : "${component.Id}" }
                                    ]
                                }
                            }
                            [#assign count = count + 1]
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]
        [/#list]
    },
    
    "Outputs" : {
        [#assign count = 0]
        [#list tiers as tier]
             [#if tier.Components??]
                [#list tier.Components?values as component]
                    [#if component?is_hash && component.Slices?seq_contains(slice)]
                        [#if component.MultiAZ??] 
                            [#assign multiAZ =  component.MultiAZ]
                        [#else]
                            [#assign multiAZ =  solnMultiAZ]
                        [/#if]
                        
                        [#-- Security Group --]
                        [#if ! (component.S3?? || component.SQS?? || component.ElasticSearch??) ]
                            [#if count > 0],[/#if]
                            "securityGroupX${tier.Id}X${component.Id}" : {
                                "Value" : { "Ref" : "securityGroupX${tier.Id}X${component.Id}" }
                            }
                            [#assign count += 1]
                        [/#if]
                        
                        [#-- S3 --]
                        [#if component.S3??]
                            [#if count > 0],[/#if]
                            "s3X${tier.Id}X${component.Id}" : {
                                "Value" : { "Ref" : "s3X${tier.Id}X${component.Id}" }
                            },
                            "s3X${tier.Id}X${component.Id}Xurl" : {
                                "Value" : { "Fn::GetAtt" : ["s3X${tier.Id}X${component.Id}", "WebsiteURL"] }
                            }
                            [#assign count += 1]
                        [/#if]
                        
                        [#-- SQS --]
                        [#if component.SQS??]
                            [#assign sqs = component.SQS]
                            [#if count > 0],[/#if]
                            "sqsX${tier.Id}X${component.Id}" : {
                                "Value" : { "Fn::GetAtt" : ["sqsX${tier.Id}X${component.Id}", "QueueName"] }
                            },
                            "sqsX${tier.Id}X${component.Id}Xurl" : {
                                "Value" : { "Ref" : "sqsX${tier.Id}X${component.Id}" }
                            },
                            "sqsX${tier.Id}X${component.Id}Xarn" : {
                                "Value" : { "Fn::GetAtt" : ["sqsX${tier.Id}X${component.Id}", "Arn"] }
                            }
                            [#assign count +=  1]
                        [/#if]
                        
                        [#-- ELB --]
                        [#if component.ELB??]
                            [#if count > 0],[/#if]
                            "elbX${tier.Id}X${component.Id}" : {
                                "Value" : { "Ref" : "elbX${tier.Id}X${component.Id}" }
                            },
                            "elbX${tier.Id}X${component.Id}Xdns" : {
                                "Value" : { "Fn::GetAtt" : ["elbX${tier.Id}X${component.Id}", "DNSName"] }
                            }
                            [#assign count += 1]
                        [/#if]

                        [#-- ALB --]
                        [#if component.ALB??]
                            [#if count > 0],[/#if]
                            [#assign alb = component.ALB]
                            [#list alb.PortMappings as mapping]
                                [#assign source = ports[portMappings[mapping].Source]]
                                "listenerX${tier.Id}X${component.Id}X${source.Port?c}" : {
                                    "Value" : { "Ref" : "listenerX${tier.Id}X${component.Id}X${source.Port?c}" }
                                },
                                "tgX${tier.Id}X${component.Id}X${source.Port?c}Xdefault" : {
                                    "Value" : { "Ref" : "tgX${tier.Id}X${component.Id}X${source.Port?c}Xdefault" }
                                },
                            [/#list]
                            "albX${tier.Id}X${component.Id}" : {
                                "Value" : { "Ref" : "albX${tier.Id}X${component.Id}" }
                            },
                            "albX${tier.Id}X${component.Id}Xdns" : {
                                "Value" : { "Fn::GetAtt" : ["albX${tier.Id}X${component.Id}", "DNSName"] }
                            }
                            [#assign count += 1]
                        [/#if]

                        [#-- EC2 --]
                        [#if component.EC2??]
                            [#if count > 0],[/#if]
                            "roleX${tier.Id}X${component.Id}" : {
                                "Value" : { "Ref" : "roleX${tier.Id}X${component.Id}" }
                            },
                            "roleX${tier.Id}X${component.Id}Xarn" : {
                                "Value" : { "Fn::GetAtt" : ["roleX${tier.Id}X${component.Id}", "Arn"] }
                            }
                            [#assign count += 1]
                        [/#if]
                        
                        [#-- ECS --]
                        [#if component.ECS??]
                            [#assign ecs = component.ECS]
                            [#if count > 0],[/#if]
                            "ecsX${tier.Id}X${component.Id}" : {
                                "Value" : { "Ref" : "ecsX${tier.Id}X${component.Id}" }
                            },
                            "roleX${tier.Id}X${component.Id}" : {
                                "Value" : { "Ref" : "roleX${tier.Id}X${component.Id}" }
                            },
                            "roleX${tier.Id}X${component.Id}Xarn" : {
                                "Value" : { "Fn::GetAtt" : ["roleX${tier.Id}X${component.Id}", "Arn"] }
                            },
                            "roleX${tier.Id}X${component.Id}Xservice" : {
                                "Value" : { "Ref" : "roleX${tier.Id}X${component.Id}Xservice" }
                            },
                            "roleX${tier.Id}X${component.Id}XserviceXarn" : {
                                "Value" : { "Fn::GetAtt" : ["roleX${tier.Id}X${component.Id}Xservice", "Arn"] }
                            }
                            [#if ecs.FixedIP?? && ecs.FixedIP]
                                [#assign processorProfile = getProcessor(tier, component, "ECS")]
                                [#assign maxSize = processorProfile.MaxPerZone]
                                [#if multiAZ]
                                    [#assign maxSize *= zones?size]
                                [/#if]
                                [#list 1..maxSize as index]
                                    ,"eipX${tier.Id}X${component.Id}X${index}Xip": {
                                        "Value" : { "Ref" : "eipX${tier.Id}X${component.Id}X${index}" }
                                    }
                                    ,"eipX${tier.Id}X${component.Id}X${index}Xid": {
                                        "Value" : { "Fn::GetAtt" : ["eipX${tier.Id}X${component.Id}X${index}", "AllocationId"] }
                                    }
                                [/#list]
                            [/#if]
                            [#assign count += 1]
                        [/#if]
                        
                        [#-- ElastiCache --]
                        [#if component.ElastiCache??]
                            [#assign cache = component.ElastiCache]
                            [#if cache.Engine == "memcached"]
                                [#if count > 0],[/#if]
                                "cacheX${tier.Id}X${component.Id}Xdns" : {
                                   "Value" : { "Fn::GetAtt" : ["cacheX${tier.Id}X${component.Id}", "ConfigurationEndpoint.Address"] }
                                },
                                "cacheX${tier.Id}X${component.Id}Xport" : {
                                    "Value" : { "Fn::GetAtt" : ["cacheX${tier.Id}X${component.Id}", "ConfigurationEndpoint.Port"] }
                                }
                                [#assign count += 1]
                            [/#if]
                        [/#if]
                        
                        [#-- RDS --]
                        [#if component.RDS??]
                            [#if count > 0],[/#if]
                            "rdsX${tier.Id}X${component.Id}Xdns" : {
                                "Value" : { "Fn::GetAtt" : ["rdsX${tier.Id}X${component.Id}", "Endpoint.Address"] }
                            },
                            "rdsX${tier.Id}X${component.Id}Xport" : {
                                "Value" : { "Fn::GetAtt" : ["rdsX${tier.Id}X${component.Id}", "Endpoint.Port"] }
                            },
                            "rdsX${tier.Id}X${component.Id}Xdatabasename" : {
                                "Value" : "${productName}"
                            },
                            "rdsX${tier.Id}X${component.Id}Xusername" : {
                                "Value" : "${credentialsObject[tier.Id + "-" + component.Id].Login.Username}"
                            },
                            "rdsX${tier.Id}X${component.Id}Xpassword" : {
                                "Value" : "${credentialsObject[tier.Id + "-" + component.Id].Login.Password}"
                            }
                            [#assign count += 1]
                        [/#if]

                        [#-- ElasticSearch --]
                        [#if component.ElasticSearch??]
                            [#assign es = component.ElasticSearch]
                            [#if count > 0],[/#if]
                            "esX${tier.Id}X${component.Id}" : {
                                "Value" : { "Ref" : "esX${tier.Id}X${component.Id}" }
                            },
                            "esX${tier.Id}X${component.Id}Xdns" : {
                                "Value" : { "Fn::GetAtt" : ["esX${tier.Id}X${component.Id}", "DomainEndpoint"] }
                            },
                            "esX${tier.Id}X${component.Id}Xarn" : {
                                "Value" : { "Fn::GetAtt" : ["esX${tier.Id}X${component.Id}", "DomainArn"] }
                            }
                            [#assign count += 1]
                        [/#if]
                    [/#if]
                [/#list]
            [/#if]
        [/#list]
    }
}
