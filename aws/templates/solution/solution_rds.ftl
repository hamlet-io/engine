[#-- RDS --]
[#if componentType == "rds"]
    [@createSecurityGroup solutionListMode tier component /]
    [#assign db = component.RDS]
    [#assign engine = db.Engine]
    [#if resourceCount > 0],[/#if]
    [#switch solutionListMode]
        [#case "definition"]
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
            "${formatId("securityGroupIngress", componentIdStem)}" : {
                "Type" : "AWS::EC2::SecurityGroupIngress",
                "Properties" : {
                    "GroupId": {"Ref" : "${formatSecurityGroupPrimaryResourceId(componentIdStem)}"},
                    "IpProtocol": "${ports[db.Port].IPProtocol}",
                    "FromPort": "${ports[db.Port].Port?c}",
                    "ToPort": "${ports[db.Port].Port?c}",
                    "CidrIp": "0.0.0.0/0"
                }
            },
            "${formatId("rdsSubnetGroup", componentIdStem)}" : {
                "Type" : "AWS::RDS::DBSubnetGroup",
                "Properties" : {
                    "DBSubnetGroupDescription" : "${componentFullNameStem}",
                    "SubnetIds" : [
                        [#list zones as zone]
                            "${getKey("subnet", componentIdStem)}"[#if !(zones?last.Id == zone.Id)],[/#if]
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
                        { "Key" : "cot:tier", "Value" : "${tierId}" },
                        { "Key" : "cot:component", "Value" : "${componentId}" },
                        { "Key" : "Name", "Value" : "${componentFullNameStem}" }
                    ]
                }
            },
            "${formatId("rdsParameterGroup", componentIdStem)}" : {
                "Type" : "AWS::RDS::DBParameterGroup",
                "Properties" : {
                    "Family" : "${family}",
                    "Description" : "${componentFullNameStem}",
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
                        { "Key" : "cot:tier", "Value" : "${tierId}" },
                        { "Key" : "cot:component", "Value" : "${componentId}" },
                        { "Key" : "Name", "Value" : "${componentFullNameStem}" }
                    ]
                }
            },
            "${formatId("rdsOptionGroup", componentIdStem)}" : {
                "Type" : "AWS::RDS::OptionGroup",
                "Properties" : {
                    "EngineName": "${engine}",
                    "MajorEngineVersion": "${engineVersion}",
                    "OptionGroupDescription" : "${componentFullNameStem}",
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
                        { "Key" : "cot:tier", "Value" : "${tierId}" },
                        { "Key" : "cot:component", "Value" : "${componentId}" },
                        { "Key" : "Name", "Value" : "${componentFullNameStem}" }
                    ]
                }
            },
            [#assign processorProfile = getProcessor(tier, component, "RDS")]
            "${primaryResourceIdStem}":{
                "Type":"AWS::RDS::DBInstance",
                "Properties":{
                    "Engine": "${engine}",
                    "EngineVersion": "${engineVersion}",
                    "DBInstanceClass" : "${processorProfile.Processor}",
                    "AllocatedStorage": "${db.Size}",
                    "StorageType" : "gp2",
                    "Port" : "${ports[db.Port].Port?c}",
                    "MasterUsername": "${credentialsObject[formatName(tierId, componentId)].Login.Username}",
                    "MasterUserPassword": "${credentialsObject[formatName(tierId, componentId)].Login.Password}",
                    "BackupRetentionPeriod" : "${db.Backup.RetentionPeriod}",
                    "DBInstanceIdentifier": "${componentFullNameStem}",
                    "DBName": "${productName}",
                    "DBSubnetGroupName": { "Ref" : "${formatId("rdsSubnetGroup", componentIdStem)}" },
                    "DBParameterGroupName": { "Ref" : "${formatId("rdsParameterGroup", componentIdStemd)}" },
                    "OptionGroupName": { "Ref" : "${formatId("rdsOptionGroup", componentIdStem)}" },
                    [#if multiAZ]
                        "MultiAZ": true,
                    [#else]
                        "AvailabilityZone" : "${zones[0].AWSZone}",
                    [/#if]
                    "VPCSecurityGroups":[
                        { "Ref" : "${formatSecurityGroupPrimaryResourceId(componentIdStem)}" }
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
                        { "Key" : "cot:tier", "Value" : "${tierId}" },
                        { "Key" : "cot:component", "Value" : "${componentId}" },
                        { "Key" : "Name", "Value" : "${componentFullNameStem}" }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            "${formatId(primaryResourceIdStem, "dns")}" : {
                "Value" : { "Fn::GetAtt" : ["${primaryResourceIdStem}", "Endpoint.Address"] }
            },
            "${formatId(primaryResourceIdStem, "port")}" : {
                    "Value" : { "Fn::GetAtt" : ["${primaryResourceIdStem}", "Endpoint.Port"] }
                },
            "${formatId(primaryResourceIdStem, "databasename")}" : {
                    "Value" : "${productName}"
                },
            "${formatId(primaryResourceIdStem, "username")}" : {
                    "Value" : "${credentialsObject[formatName(tierId, componentId)].Login.Username}"
                },
            "${formatId(primaryResourceIdStem, "password")}" : {
                "Value" : "${credentialsObject[formatName(tierId, componentId)].Login.Password}"
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]