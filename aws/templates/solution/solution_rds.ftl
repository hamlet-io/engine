[#-- RDS --]
[#if componentType == "rds"]
    [#assign db = component.RDS]
    [#assign engine = db.Engine]
    
    [#assign rdsId = formatRDSId(tier, component)]
    [#assign rdsFullName = componentFullName]
    [#assign rdsSubnetGroupId = formatRDSSubnetGroupId(tier, component)]
    [#assign rdsParameterGroupId = formatRDSParameterGroupId(tier, component)]
    [#assign rdsOptionGroupId = formatRDSOptionGroupId(tier, component)]
    [#assign rdsCredentials = credentialsObject[componentShortNameWithType]!
                                credentialsObject[componentShortName]]
    [#assign rdsUsername = rdsCredentials.Login.Username]
    [#assign rdsPassword = rdsCredentials.Login.Password]

    [#assign rdsSecurityGroupId = formatDependentComponentSecurityGroupId(
                                    tier, 
                                    component,
                                    rdsId)]
    [#assign rdsSecurityGroupIngressId = formatDependentSecurityGroupIngressId(
                                            rdsSecurityGroupId, 
                                            ports[db.Port].Port?c)]

    [@createDependentComponentSecurityGroup
        solutionListMode
        tier
        component
        rdsId
        rdsFullName/]
    
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
            "${rdsSecurityGroupIngressId}" : {
                "Type" : "AWS::EC2::SecurityGroupIngress",
                "Properties" : {
                    "GroupId": {"Ref" : "${rdsSecurityGroupId}"},
                    "IpProtocol": "${ports[db.Port].IPProtocol}",
                    "FromPort": "${ports[db.Port].Port?c}",
                    "ToPort": "${ports[db.Port].Port?c}",
                    "CidrIp": "0.0.0.0/0"
                }
            },
            "${rdsSubnetGroupId}" : {
                "Type" : "AWS::RDS::DBSubnetGroup",
                "Properties" : {
                    "DBSubnetGroupDescription" : "${rdsFullName}",
                    "SubnetIds" : [
                        [#list zones as zone]
                            "${getKey(formatSubnetId(tier, zone))}"[#if !(zones?last.Id == zone.Id)],[/#if]
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
                        { "Key" : "Name", "Value" : "${rdsFullName}" }
                    ]
                }
            },
            "${rdsParameterGroupId}" : {
                "Type" : "AWS::RDS::DBParameterGroup",
                "Properties" : {
                    "Family" : "${family}",
                    "Description" : "${rdsFullName}",
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
                        { "Key" : "Name", "Value" : "${rdsFullName}" }
                    ]
                }
            },
            "${rdsOptionGroupId}" : {
                "Type" : "AWS::RDS::OptionGroup",
                "Properties" : {
                    "EngineName": "${engine}",
                    "MajorEngineVersion": "${engineVersion}",
                    "OptionGroupDescription" : "${rdsFullName}",
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
                        { "Key" : "Name", "Value" : "${rdsFullName}" }
                    ]
                }
            },
            [#assign processorProfile = getProcessor(tier, component, "RDS")]
            "${rdsId}":{
                "Type":"AWS::RDS::DBInstance",
                "Properties":{
                    "Engine": "${engine}",
                    "EngineVersion": "${engineVersion}",
                    "DBInstanceClass" : "${processorProfile.Processor}",
                    "AllocatedStorage": "${db.Size}",
                    "StorageType" : "gp2",
                    "Port" : "${ports[db.Port].Port?c}",
                    "MasterUsername": "${rdsUsername}",
                    "MasterUserPassword": "${rdsPassword}",
                    "BackupRetentionPeriod" : "${db.Backup.RetentionPeriod}",
                    "DBInstanceIdentifier": "${rdsFullName}",
                    "DBName": "${productName}",
                    "DBSubnetGroupName": { "Ref" : "${rdsSubnetGroupId}" },
                    "DBParameterGroupName": { "Ref" : "${rdsParameterGroupId}" },
                    "OptionGroupName": { "Ref" : "${rdsOptionGroupId}" },
                    [#if multiAZ]
                        "MultiAZ": true,
                    [#else]
                        "AvailabilityZone" : "${zones[0].AWSZone}",
                    [/#if]
                    "VPCSecurityGroups":[
                        { "Ref" : "${rdsSecurityGroupId}" }
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
                        { "Key" : "Name", "Value" : "${rdsFullName}" }
                    ]
                }
            }
            [#break]

        [#case "outputs"]
            [@outputRDSDns rdsId /],
            [@outputRDSPort rdsId /],
            [@outputRDSDatabaseName rdsId productName /]
            [#break]

    [/#switch]
    [#assign resourceCount += 1]
[/#if]