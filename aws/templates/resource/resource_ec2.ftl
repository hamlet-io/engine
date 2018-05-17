[#function getInitConfig configSetName configKeys=[] ]

    [#local configSet = [] ] 
    [#list configKeys as key,value ]
        [#local configSet += [ key ] ]            
    [/#list]

    [#return {
        "AWS::CloudFormation::Init" : {
            "configSets" : {
                configSetName : configSet
            }
            + configKeys
        }
    } ]
[/#function]

[#function getInitConfigDirectories ignoreErrors=false ]
    [#return 
        {
            "Directories" : {
                "commands": {
                    "01Directories" : {
                        "command" : "mkdir --parents --mode=0755 /etc/codeontap && mkdir --parents --mode=0755 /opt/codeontap/bootstrap && mkdir --parents --mode=0755 /var/log/codeontap",
                        "ignoreErrors" : ignoreErrors
                    }
                }
            }
        }
    ]
[/#function]


[#function getInitConfigBootstrap role ]
    [#return 
        {
            "Bootstrap": {
                "packages" : {
                    "yum" : {
                        "aws-cli" : [],
                        "amazon-efs-utils" : []
                    }
                },
                "files" : {
                    "/etc/codeontap/facts.sh" : {
                        "content" : {
                            "Fn::Join" : [
                                "",
                                [
                                    "#!/bin/bash\n",
                                    "echo \"cot:request="       + requestReference       + "\"\n",
                                    "echo \"cot:configuration=" + configurationReference + "\"\n",
                                    "echo \"cot:accountRegion=" + accountRegionId        + "\"\n",
                                    "echo \"cot:tenant="        + tenantId               + "\"\n",
                                    "echo \"cot:account="       + accountId              + "\"\n",
                                    "echo \"cot:product="       + productId              + "\"\n",
                                    "echo \"cot:region="        + regionId               + "\"\n",
                                    "echo \"cot:segment="       + segmentId              + "\"\n",
                                    "echo \"cot:environment="   + environmentId          + "\"\n",
                                    "echo \"cot:tier="          + tierId                 + "\"\n",
                                    "echo \"cot:component="     + componentId            + "\"\n",
                                    "echo \"cot:role="          + role                  + "\"\n",
                                    "echo \"cot:credentials="   + credentialsBucket      + "\"\n",
                                    "echo \"cot:code="          + codeBucket             + "\"\n",
                                    "echo \"cot:logs="          + operationsBucket       + "\"\n",
                                    "echo \"cot:backups="       + dataBucket             + "\"\n"
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
                                    "aws --region " + r"${REGION}" + " s3 sync s3://" + r"${CODE}" + "/bootstrap/centos/ /opt/codeontap/bootstrap && chmod 0500 /opt/codeontap/bootstrap/*.sh\n"
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
            }
        }
    ]
[/#function]

[#function getInitConfigEFSMount mountId efsId directory osMount ignoreErrors=false ]
    [#return 
        {
            "EFSMount_" + mountId : {
                "commands" :  {
                    "MountEFS" : {
                        "command" : "/opt/codeontap/bootstrap/efs.sh",
                        "env" : {
                            "EFS_FILE_SYSTEM_ID" : efsId,
                            "EFS_MOUNT_PATH" : directory,
                            "EFS_OS_MOUNT_PATH" : "/mnt/clusterstorage/" + osMount
                        },
                        "ignoreErrors" : ignoreErrors
                    }
                }
            }
        }
    ]
[/#function]

[#function getInitConfigLBTargetRegistration targetGroupId ignoreErrors=false]
    [#return
        {
            "RegisterWithTG_" + targetGroupId  : {
                "commands" : {
                        "RegsiterWithTG" : {
                        "command" : "/opt/codeontap/bootstrap/register_targetgroup.sh",
                        "env" : {
                            "TARGET_GROUP_ARN" : getReference(targetGroupId)
                        },
                        "ignoreErrors" : ignoreErrors
                    }
                }
            }
        }
    ]
[/#function]

[#function getInitConfigLBClassicRegistration lbId ignoreErrors=false]
    [#return 
        {
            "RegisterWithLB_" + lbId : {
                "commands" : { 
                    "RegisterWithLB" : {
                        "command" : "/opt/codeontap/bootstrap/register.sh",
                        "env" : {
                            "LOAD_BALANCER" : getReference(lbId)
                        },
                        "ignoreErrors" : ignoreErrors
                    }
                }
            }
        }
    ]
[/#function]

[#function getInitConfigScriptsDeployment scriptsFile ignoreErrors=false ]
    [#return 
        
        {
            "scripts" : {
                            
                "sources" : {
                    "/opt/codeontap/scripts" : scriptsFile
                },
                "files" :{
                    "/opt/codeontap/run_scripts.sh" : {
                        "content" : {
                            "Fn::Join" : [
                                "",
                                [
                                    "#!/bin/bash -ex\n",
                                    "exec > >(tee /var/log/codeontap/fetch.log|logger -t codeontap-scripts-init -s 2>/dev/console) 2>&1\n",
                                    "[ -f /opt/codeontap/scripts/init.sh ] &&  /opt/codeontap/scripts/init.sh\n"
                                ]
                            ]
                        },
                        "mode" : "000755"
                    }
                },
                "commands" : {
                    "02RunInitScript" : {
                        "command" : "/opt/codeontap/run_scripts.sh",
                        "ignoreErrors" : ignoreErrors
                    }
                }
            }
        }
    ]
[/#function]

[#macro createEC2LaunchConfig mode id 
    processorProfile
    storageProfile
    securityGroupId
    instanceProfileId
    resourceId
    imageId
    routeTable
    configSet
    environmentId
    dependencies="" 
    outputId=""
]

    [#assign updateCommand = "yum clean all && yum -y update"]
    [#assign dailyUpdateCron = 'echo \"59 13 * * * ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
    [#if environmentId == "prod"]
        [#-- for production update only security packages --]
        [#assign updateCommand += " --security"]
        [#assign dailyUpdateCron = 'echo \"29 13 * * 6 ${updateCommand} >> /var/log/update.log 2>&1\" >crontab.txt && crontab crontab.txt']
    [/#if]

    [@cfResource
        mode=mode
        id=id
        type="AWS::AutoScaling::LaunchConfiguration"
        properties=
            getBlockDevices(storageProfile) +
            {
                "KeyName":
                    valueIfTrue(
                        formatEnvironmentFullName(),
                        sshPerEnvironment,
                        productName
                    ),
                "InstanceType": processorProfile.Processor,
                "ImageId" : imageId,
                "SecurityGroups" : 
                    [
                        getReference(securityGroupId)
                    ] +
                    sshFromProxySecurityGroup?has_content?then(
                        [
                            sshFromProxySecurityGroup
                        ],
                        []
                    ),
                "IamInstanceProfile" : getReference(instanceProfileId),
                "AssociatePublicIpAddress" : (routeTable == "external"),
                "UserData" : {
                    "Fn::Base64" : {
                        "Fn::Join" : [
                            "",
                            [
                                "#!/bin/bash -ex\n",
                                "exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1\n",
                                "# Install updates\n",
                                updateCommand, "\n",
                                dailyUpdateCron, "\n",
                                "yum install -y aws-cfn-bootstrap\n",
                                "# Remainder of configuration via metadata\n",
                                "/opt/aws/bin/cfn-init -v",
                                "         --stack ", { "Ref" : "AWS::StackName" },
                                "         --resource ", resourceId,
                                "         --region ", regionId, " --configsets ", configSet, "\n"
                            ]
                        ]
                    }
                }
            }
        outputs={}
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]