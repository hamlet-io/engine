[#-- RDS --]
[#if component.RDS??]
    [@securityGroup tier=tier component=component /]
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
            "${formatId("securityGroupIngress", tier.Id, component.Id)}" : {
                "Type" : "AWS::EC2::SecurityGroupIngress",
                "Properties" : {
                    "GroupId": {"Ref" : "${formatId("securityGroup", tier.Id, component.Id)}"},
                    "IpProtocol": "${ports[db.Port].IPProtocol}",
                    "FromPort": "${ports[db.Port].Port?c}",
                    "ToPort": "${ports[db.Port].Port?c}",
                    "CidrIp": "0.0.0.0/0"
                }
            },
            "${formatId("rdsSubnetGroup", tier.Id, component.Id)}" : {
                "Type" : "AWS::RDS::DBSubnetGroup",
                "Properties" : {
                    "DBSubnetGroupDescription" : "${formatName(productName, segmentName, tier.Name, component.Name)}",
                    "SubnetIds" : [
                        [#list zones as zone]
                            "${getKey("subnet", tier.Id, zone.Id)}"[#if !(zones?last.Id == zone.Id)],[/#if]
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
                        { "Key" : "Name", "Value" : "${formatName(productName, segmentName, tier.Name, component.Name)}" }
                    ]
                }
            },
            "${formatId("rdsParameterGroup", tier.Id, component.Id)}" : {
                "Type" : "AWS::RDS::DBParameterGroup",
                "Properties" : {
                    "Family" : "${family}",
                    "Description" : "Parameter group for ${formatName(tier.Id, component.Id)}",
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
                        { "Key" : "Name", "Value" : "${formatName(productName, segmentName, tier.Name, component.Name)}" }
                    ]
                }
            },
            "${formatId("rdsOptionGroup", tier.Id, component.Id)}" : {
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
                        { "Key" : "Name", "Value" : "${formatName(productName, segmentName, tier.Name, component.Name)}" }
                    ]
                }
            },
            [#assign processorProfile = getProcessor(tier, component, "RDS")]
            "${formatId("rds", tier.Id, component.Id)}":{
                "Type":"AWS::RDS::DBInstance",
                "Properties":{
                    "Engine": "${engine}",
                    "EngineVersion": "${engineVersion}",
                    "DBInstanceClass" : "${processorProfile.Processor}",
                    "AllocatedStorage": "${db.Size}",
                    "StorageType" : "gp2",
                    "Port" : "${ports[db.Port].Port?c}",
                    "MasterUsername": "${credentialsObject[formatName(tier.Id, component.Id)].Login.Username}",
                    "MasterUserPassword": "${credentialsObject[formatName(tier.Id, component.Id)].Login.Password}",
                    "BackupRetentionPeriod" : "${db.Backup.RetentionPeriod}",
                    "DBInstanceIdentifier": "${formatName(productName, segmentName, tier.Name, component.Name)}",
                    "DBName": "${productName}",
                    "DBSubnetGroupName": { "Ref" : "${formatId("rdsSubnetGroup", tier.Id, component.Id)}" },
                    "DBParameterGroupName": { "Ref" : "${formatId("rdsParameterGroup", tier.Id, component.Id)}" },
                    "OptionGroupName": { "Ref" : "${formatId("rdsOptionGroup", tier.Id, component.Id)}" },
                    [#if multiAZ]
                        "MultiAZ": true,
                    [#else]
                        "AvailabilityZone" : "${zones[0].AWSZone}",
                    [/#if]
                    "VPCSecurityGroups":[
                        { "Ref" : "${formatId("securityGroup", tier.Id, component.Id)}" }
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
                        { "Key" : "Name", "Value" : "${formatName(productName, segmentName, tier.Name, component.Name)}" }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            "${formatId("rds", tier.Id, component.Id, "dns")}" : {
                "Value" : { "Fn::GetAtt" : ["${formatId("rds", tier.Id, component.Id)}", "Endpoint.Address"] }
            },
            "${formatId("rds", tier.Id, component.Id, "port")}" : {
                    "Value" : { "Fn::GetAtt" : ["${formatId("rds", tier.Id, component.Id)}", "Endpoint.Port"] }
                },
            "${formatId("rds", tier.Id, component.Id, "databasename")}" : {
                    "Value" : "${productName}"
                },
            "${formatId("rds", tier.Id, component.Id, "username")}" : {
                    "Value" : "${credentialsObject[formatName(tier.Id, component.Id)].Login.Username}"
                },
            "${formatId("rds", tier.Id, component.Id, "password")}" : {
                "Value" : "${credentialsObject[formatName(tier.Id, component.Id)].Login.Password}"
            }
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]