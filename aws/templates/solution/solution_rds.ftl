[#-- RDS --]
[#if component.RDS??]
    [#assign db = component.RDS]
    [#assign engine = db.Engine]
    [#if count > 0],[/#if]
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
                        "AvailabilityZone" : "${zones[0].AWSZone}",
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
            [#break]

        [#case "outputs"]
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
            [#break]

    [/#switch]
    [#assign count += 1]
[/#if]