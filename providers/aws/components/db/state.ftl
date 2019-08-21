[#ftl]

[#macro aws_db_cf_state occurrence parent={} baseState={}  ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatResourceId(AWS_RDS_RESOURCE_TYPE, core.Id) ]

    [#local engine = occurrence.Configuration.Solution.Engine]
    [#local engineVersion = occurrence.Configuration.Solution.EngineVersion]

    [#switch engine]
        [#case "mysql"]
            [#local family = "mysql" + engineVersion]
            [#break]
        [#case "postgres" ]
            [#local family = "postgres" + engineVersion]
            [#break]
        [#default]
            [#local family = engine + engineVersion]
    [/#switch]

    [#local fqdn = getExistingReference(id, DNS_ATTRIBUTE_TYPE)]
    [#local port = getExistingReference(id, PORT_ATTRIBUTE_TYPE)]
    [#local name = getExistingReference(id, DATABASENAME_ATTRIBUTE_TYPE)]
    [#local region = getExistingReference(id, REGION_ATTRIBUTE_TYPE)]
    [#local encryptionScheme = (solution.GenerateCredentials.EncryptionScheme)?has_content?then(
                        solution.GenerateCredentials.EncryptionScheme?ensure_ends_with(":"),
                        "" )]

    [#if solution.GenerateCredentials.Enabled ]
        [#local masterUsername = solution.GenerateCredentials.MasterUserName ]
        [#local masterPassword = getExistingReference(id, GENERATEDPASSWORD_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme) ]
        [#local url = getExistingReference(id, URL_ATTRIBUTE_TYPE)?ensure_starts_with(encryptionScheme) ]
    [#else]
        [#-- don't flag an error if credentials missing but component is not enabled --]
        [#local masterUsername = getOccurrenceSettingValue(occurrence, "MASTER_USERNAME", !solution.Enabled) ]
        [#local masterPassword = getOccurrenceSettingValue(occurrence, "MASTER_PASSWORD", !solution.Enabled) ]
        [#local url = engine + "://" + masterUsername + ":" + masterPassword + "@" + fqdn + ":" + port + "/" + name]
    [/#if]

    [#assign componentState =
        {
            "Resources" : {
                "db" : {
                    "Id" : id,
                    "Name" : core.FullName,
                    "Type" : AWS_RDS_RESOURCE_TYPE,
                    "Monitored" : true
                },
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
            },
            "Attributes" : {
                "ENGINE" : engine,
                "FQDN" : fqdn,
                "PORT" : port,
                "NAME" : name,
                "URL" : url,
                "USERNAME" : masterUsername,
                "PASSWORD" : masterPassword,
                "INSTANCEID" : core.FullName,
                "REGION" : region
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#macro]