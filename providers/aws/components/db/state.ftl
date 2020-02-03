[#ftl]

[#macro aws_db_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local engine = occurrence.Configuration.Solution.Engine]
    [#local engineVersion = occurrence.Configuration.Solution.EngineVersion]

    [#local auroraCluster = false ]

    [#switch engine]
        [#case "mysql"]
            [#local family = "mysql" + engineVersion]
            [#local scheme = "mysql" ]
            [#break]
        [#case "postgres" ]
            [#local family = "postgres" + engineVersion]
            [#local scheme = "postgres" ]
            [#break]
        [#case "aurora-postgresql" ]
            [#local family = "aurora-postgresql" + engineVersion]
            [#local scheme = "postgres" ]
            [#local auroraCluster = true ]
            [#break]
        [#default]
            [#local family = engine + engineVersion]
            [#local scheme = engine ]
    [/#switch]

    [#if auroraCluster ]
        [#local id = formatResourceId(AWS_RDS_CLUSTER_RESOURCE_TYPE, core.Id) ]
    [#else]
        [#local id = formatResourceId(AWS_RDS_RESOURCE_TYPE, core.Id) ]
    [/#if]

    [#local fqdn = getExistingReference(id, DNS_ATTRIBUTE_TYPE)]

    [#local port = getExistingReference(id, PORT_ATTRIBUTE_TYPE)]
    [#local name = getExistingReference(id, DATABASENAME_ATTRIBUTE_TYPE)]
    [#local region = getExistingReference(id, REGION_ATTRIBUTE_TYPE)]
    [#local encryptionScheme = (solution.GenerateCredentials.EncryptionScheme)?has_content?then(
                        solution.GenerateCredentials.EncryptionScheme?ensure_ends_with(":"),
                        "" )]
    [#if auroraCluster ]
        [#local readfqdn = getExistingReference(id, "read" + DNS_ATTRIBUTE_TYPE )]
    [/#if]

    [#if solution.GenerateCredentials.Enabled ]
        [#local masterUsername = solution.GenerateCredentials.MasterUserName ]
        [#local masterPassword = getExistingReference(id, GENERATEDPASSWORD_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme) ]
        [#local url = getExistingReference(id, URL_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme) ]

        [#if auroraCluster ]
            [#local readUrl = getExistingReference(id, "read" + URL_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme) ]
        [/#if]
    [#else]
        [#-- don't flag an error if credentials missing but component is not enabled --]
        [#local masterUsername = getOccurrenceSettingValue(occurrence, "MASTER_USERNAME", !solution.Enabled) ]
        [#local masterPassword = getOccurrenceSettingValue(occurrence, "MASTER_PASSWORD", !solution.Enabled) ]
        [#local url = scheme + "://" + masterUsername + ":" + masterPassword + "@" + fqdn + ":" + port + "/" + name]

        [#if auroraCluster ]
            [#local readUrl = scheme + "://" + masterUsername + ":" + masterPassword + "@" + readfqdn + ":" + port + "/" + name ]
        [/#if]
    [/#if]

    [#local dbResources = {}]

    [#if auroraCluster ]
        [#local dbResources += {
            "dbCluster" : {
                "Id" : id,
                "Name" : core.FullName,
                "Type" : AWS_RDS_CLUSTER_RESOURCE_TYPE,
                "Monitored" : true
            },
            "dbClusterParamGroup" : {
                "Id" : formatResourceId(AWS_RDS_CLUSTER_PARAMETER_GROUP_RESOURCE_TYPE, core.Id, replaceAlphaNumericOnly(family, "X") ),
                "Family" : family,
                "Type" : AWS_RDS_CLUSTER_PARAMETER_GROUP_RESOURCE_TYPE
            }
        }]

        [#-- Calcuate the number of fixed instances required --]
        [#if multiAZ!false ]
            [#local resourceZones = zones ]
        [#else]
            [#local resourceZones = [zones[0]] ]
        [/#if]

        [#local processor = getProcessor(
                                        occurrence,
                                        "db",
                                        solution.ProcessorProfile)]
        [#if processor.DesiredPerZone?has_content ]
                [#local instancesPerZone = processor.DesiredPerZone ]
        [#else]
            [#local processorCounts = getProcessorCounts(processor, multiAZ ) ]
            [#if processorCounts.DesiredCount?has_content ]
                [#local instancesPerZone = ( processorCounts.DesiredCount / resourceZones?size)?round ]
            [#else]
                [@fatal
                    message="Invalid Processor Profile for Cluster"
                    context=processor
                    detail="Add Autoscaling processing profile"
                /]
                [#return]
            [/#if]
        [/#if]

        [#local autoScaling = {}]
        [#if solution.Cluster.ScalingPolicies?has_content ]

            [#-- Autoscaling requires 2 fixed instances at all times so we force it to be set --]
            [#local resourceZones = zones[0..1]]
            [#local instancesPerZone = 1 ]

            [#local autoScaling +=
                {
                    "scalingTarget" : {
                        "Id" : formatResourceId(AWS_AUTOSCALING_APP_TARGET_RESOURCE_TYPE, core.Id),
                        "Type" : AWS_AUTOSCALING_APP_TARGET_RESOURCE_TYPE
                    }
                }
            ]
            [#list solution.Cluster.ScalingPolicies as name, scalingPolicy ]
                [#local autoScaling +=
                    {
                        "scalingPolicy" + name : {
                            "Id" : formatDependentAutoScalingAppPolicyId(id, name),
                            "Name" : formatName(core.FullName, name),
                            "Type" : AWS_AUTOSCALING_APP_POLICY_RESOURCE_TYPE
                        }
                    }
                ]
            [/#list]
        [/#if]
        [#local dbResources = mergeObjects( dbResources, autoScaling )]

        [#-- Define fixed instanaces per zone --]
        [#list resourceZones as resourceZone ]
            [#list 1..instancesPerZone as instanceId ]
                [#local dbResources = mergeObjects(
                    dbResources,
                    {
                        "dbInstances" : {
                            "dbInstance" + resourceZone.Id + instanceId : {
                                "Id" : formatId( AWS_RDS_RESOURCE_TYPE, core.Id, resourceZone.Id, instanceId),
                                "Name" : formatName( core.FullName, resourceZone.Name, instanceId ),
                                "AvailabilityZone" : resourceZone.AWSZone,
                                "Type" : AWS_RDS_RESOURCE_TYPE
                            }
                        }
                    }
                )]
            [/#list]
        [/#list]
    [#else]
        [#local dbResources = mergeObjects(
            dbResources,
            {
                "db" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "Type" : AWS_RDS_RESOURCE_TYPE,
                    "Monitored" : true
                }
            }
        )]
    [/#if]

    [#assign componentState =
        {
            "Resources" : {
                "subnetGroup" : {
                    "Id" : formatResourceId(AWS_RDS_SUBNET_GROUP_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_RDS_SUBNET_GROUP_RESOURCE_TYPE
                },
                "parameterGroup" : {
                    "Id" : formatResourceId(AWS_RDS_PARAMETER_GROUP_RESOURCE_TYPE, core.Id, replaceAlphaNumericOnly(family, "X") ),
                    "Family" : family,
                    "Type" : AWS_RDS_PARAMETER_GROUP_RESOURCE_TYPE
                },
                "optionGroup" : {
                    "Id" : formatResourceId(AWS_RDS_OPTION_GROUP_RESOURCE_TYPE, core.Id, replaceAlphaNumericOnly(family, "X")),
                    "Type" : AWS_RDS_OPTION_GROUP_RESOURCE_TYPE
                },
                "securityGroup" : {
                    "Id" : formatDependentComponentSecurityGroupId(core.Tier, core.Component, id),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                }
            } +
            solution.Monitoring.DetailedMetrics.Enabled?then(
                {
                    "monitoringRole" : {
                        "Id" : formatResourceId(AWS_IAM_ROLE_RESOURCE_TYPE, core.Id, "monitoring" ),
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
                    }
                },
                {}
            ) +
            dbResources,
            "Attributes" : {
                "ENGINE" : engine,
                "TYPE" : auroraCluster?then("cluster", "instance"),
                "SCHEME" : scheme,
                "FQDN" : fqdn,
                "PORT" : port,
                "NAME" : name,
                "URL" : url,
                "USERNAME" : masterUsername,
                "PASSWORD" : masterPassword,
                "INSTANCEID" : core.FullName,
                "REGION" : region
            } +
            valueIfTrue(
                {
                    "READ_FQDN" : readfqdn!"",
                    "READ_URL" : readUrl!""
                },
                auroraCluster
            ),
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]
