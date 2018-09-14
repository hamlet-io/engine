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
        } + configKeys 
    } ]
[/#function]

[#function getInitConfigDirectories ignoreErrors=false ]
    [#return 
        {
            "Directories" : {
                "commands": {
                    "01Directories" : {
                        "command" : "mkdir --parents --mode=0755 /etc/codeontap && mkdir --parents --mode=0755 /opt/codeontap/bootstrap && mkdir --parents --mode=0755 /opt/codeontap/scripts && mkdir --parents --mode=0755 /var/log/codeontap",
                        "ignoreErrors" : ignoreErrors
                    }
                }
            }
        }
    ]
[/#function]

[#function getInitConfigBootstrap role ignoreErrors=false]
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
                                    "echo \"cot:role="          + role                   + "\"\n",
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
                        "ignoreErrors" : ignoreErrors
                    },
                    "02Initialise" : {
                        "command" : "/opt/codeontap/bootstrap/init.sh",
                        "ignoreErrors" : ignoreErrors
                    }
                }
            }
        }
    ]
[/#function]

[#function getInitConfigUserBootstrap bootstrap environment={} ignoreErrors=false ]
    [#local scriptStore = scriptStores[bootstrap.ScriptStore ]]
    [#local scriptStorePrefix = scriptStore.Destination.Prefix ]

    [#local userBootstrapPackages = {}]

    [#list bootstrap.Packages!{} as provider,packages ]
        [#local providerPackages = {}]
        [#if packages?is_sequence ]
            [#list packages as package ]
                [#local providerPackages += 
                    {
                        package.Name : [] +
                            (package.Version)?has_content?then(
                                [ package.Version ],
                                []
                            )
                    }]
            [/#list]
        [/#if]
        [#if providerPackages?has_content ]
            [#local userBootstrapPackages += 
                {
                    provider : providerPackages 
                }]
        [/#if]
    [/#list]

    [#local bootstrapDir = "/opt/codeontap/user/" + bootstrap.Id ]
    [#local bootstrapFetchFile = bootstrapDir + "/fetch.sh" ]
    [#local bootstrapScriptsDir = bootstrapDir + "/scripts/" ]
    [#local bootstrapInitFile = bootstrapScriptsDir + bootstrap.InitScript!"init.sh" ]

    [#return 
        {
            "UserBoot_" + bootstrap.Id : {
                "files" : {
                    bootstrapFetchFile: {
                        "content" : {
                            "Fn::Join" : [
                                "",
                                [
                                    "#!/bin/bash -ex\n",
                                    "exec > >(tee /var/log/codeontap/fetch.log|logger -t codeontap-fetch -s 2>/dev/console) 2>&1\n",
                                    "REGION=$(/etc/codeontap/facts.sh | grep cot:accountRegion | cut -d '=' -f 2)\n",
                                    "CODE=$(/etc/codeontap/facts.sh | grep cot:code | cut -d '=' -f 2)\n",
                                    "aws --region " + r"${REGION}" + " s3 sync s3://" + r"${CODE}/" + scriptStorePrefix + " " + bootstrapScriptsDir + " && chmod 0500 " + bootstrapScriptsDir + "*.sh\n"
                                ]
                            ]
                        },
                        "mode" : "000755"
                    }
                },
                "commands": {
                    "01Fetch" : {
                        "command" : bootstrapFetchFile,
                        "ignoreErrors" : ignoreErrors
                    },
                    "02RunScript" : {
                        "command" : bootstrapInitFile,
                        "ignoreErrors" : ignoreErrors,
                        "cwd" : bootstrapScriptsDir
                    } + 
                    attributeIfContent(
                        "env",
                        environment
                    )
                } + 
                attributeIfContent(
                    "packages",
                    userBootstrapPackages
                )
            }
        }
    ]
[/#function]

[#function getInitConfigEnvFacts envVariables={} ignoreErrors=false ]

    [#local envContent = [
        "#!/bin/bash\n"
    ]]

    [#list envVariables as key,value]
        [#local envContent += 
            [
                "echo \"" + key + "=" + value + "\"\n"
            ]
        ]
    [/#list]

    [#return 
        {
            "EnvFacts" : {
                "files" : {
                    "/etc/codeontap/env.sh" : {
                        "content" : {
                            "Fn::Join" : [
                                "",
                                envContent
                            ]
                        },
                        "mode" : "000755"
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

[#function getInitConfigScriptsDeployment scriptsFile envVariables={} shutDownOnCompletion=false ignoreErrors=false ]
    [#return 
        {
            "scripts" : {
                "packages" : {
                    "yum" : {
                        "aws-cli" : [],
                        "unzip" : []
                    }
                },
                "files" :{
                    "/opt/codeontap/fetch_scripts.sh" : {
                        "content" : {
                            "Fn::Join" : [
                                "",
                                [
                                    "#!/bin/bash -ex\n",
                                    "exec > >(tee /var/log/codeontap/fetch-scripts.log|logger -t codeontap-scripts-fetch -s 2>/dev/console) 2>&1\n",
                                    "REGION=$(/etc/codeontap/facts.sh | grep cot:accountRegion | cut -d '=' -f 2)\n",
                                    "aws --region " + r"${REGION}" + " s3 cp --quiet s3://" + scriptsFile + " /opt/codeontap/scripts\n",
                                    " if [[ -f /opt/codeontap/scripts/scripts.zip ]]; then\n",
                                    "unzip /opt/codeontap/scripts/scripts.zip -d /opt/codeontap/scripts/\n",
                                    "chmod -R 0544 /opt/codeontap/scripts/\n",
                                    "else\n",
                                    "return 1\n",
                                    "fi\n"
                                ]
                            ]
                        },
                        "mode" : "000755"
                    },
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
                    "01RunInitScript" : {
                        "command" : "/opt/codeontap/fetch_scripts.sh",
                        "ignoreErrors" : ignoreErrors
                    },
                    "02RunInitScript" : {
                        "command" : "/opt/codeontap/run_scripts.sh",
                        "cwd" : "/opt/codeontap/scripts/",
                        "ignoreErrors" : ignoreErrors
                    } + 
                    attributeIfContent(
                        "env",
                        envVariables,
                        envVariables
                    )
                } + shutDownOnCompletion?then(
                    {
                        "03ShutDownInstance" : {
                            "command" : "shutdown -P +10",
                            "ignoreErrors" : ignoreErrors
                        }
                    },
                    {}
                )
            }
        }
    ]
[/#function]

[#function getInitConfigECSAgent ecsId defaultLogDriver dockerUsers=[] ignoreErrors=false ]
    [#local dockerUsersEnv = "" ]

    [#if dockerUsers?has_content ] 
        [#list dockerUsers as userName,details ]
            [#local dockerUsersEnv += details.UserName?has_content?then(details.UserName,userName) + ":" + details.UID?c + "," ]
        [/#list] 
    [/#if]
    [#local dockerUsersEnv = dockerUsersEnv?remove_ending(",")]

    [#return 
        {
        "ecs": {
            "commands":
                attributeIfTrue(
                    "01Fluentd",
                    defaultLogDriver == "fluentd",
                    {
                        "command" : "/opt/codeontap/bootstrap/fluentd.sh",
                        "ignoreErrors" : ignoreErrors
                    }) +
                {
                    "03ConfigureCluster" : {
                        "command" : "/opt/codeontap/bootstrap/ecs.sh",
                        "env" : {
                            "ECS_CLUSTER" : getReference(ecsId),
                            "ECS_LOG_DRIVER" : defaultLogDriver
                        } +
                        attributeIfContent(
                            "DOCKER_USERS",
                            dockerUsersEnv
                        ),
                        "ignoreErrors" : ignoreErrors
                    }
                }
            }
        }
    ]
[/#function]

[#function getInitConfigEIPAllocation allocationIds ignoreErrors=false ]
    [#return 
        {
            "AssignEIP" :  {
                "command" : "/opt/codeontap/bootstrap/eip.sh",
                "env" : {
                    "EIP_ALLOCID" : {
                        "Fn::Join" : [
                            " ",
                            allocationIds
                        ]
                    }
                },
                "ignoreErrors" : ignoreErrors
            }
        }
    ]
[/#function]

[#function getInitConfigPuppet ignoreErrors=false]
    [#return 
        {
            "puppet": {
                "commands": {
                    "01SetupPuppet" : {
                        "command" : "/opt/codeontap/bootstrap/puppet.sh",
                        "ignoreErrors" : "false"
                    }
                }
            }
        }
    ]
[/#function]

[#function getInitConfigLogAgent logProfile logGroupName ignoreErrors=false ]
    [#local logContent = [
        "[general]\n",
        "state_file = /var/lib/awslogs/agent-state\n",
        "\n"
    ]]

    [#list logProfile.LogFileGroups as logFileGroup ]
        [#local logGroup = logFileGroups[logFileGroup] ]
        [#list logGroup.LogFiles as logFile ]
            [#local logFileDetails = logFiles[logFile] ]
            [#local logContent +=
                [
                    "[" + logFileDetails.FilePath + "]\n",
                    "file = " + logFileDetails.FilePath + "\n",
                    "log_group_name = " + logGroupName + "\n",
                    "log_stream_name = {instance_id}" + logFileDetails.FilePath + "\n"
                ] + 
                (logFileDetails.TimeFormat!"")?has_content?then(
                    [ "datetime_format = " + logFileDetails.TimeFormat + "\n" ],
                    []
                ) + 
                (logFileDetails.MultiLinePattern!"")?has_content?then(
                    [ "awslogs-multiline-pattern = " + logFileDetails.MultiLinePattern + "\n" ],
                    []
                ) + 
                [ "\n" ]
            ]
        [/#list]
    [/#list]

    [#return 
        {
            "LogConfig" : {
                "packages" : {
                    "yum" : {
                        "awslogs" : [],
                        "jq" : []
                    }
                },
                "files" : {
                    "/etc/awslogs/awscli.conf" : {
                        "content" : {
                            "Fn::Join" : [
                                "",
                                [
                                    "[plugins]\n",
                                    "cwlogs = cwlogs\n",
                                    "[default]\n",
                                    "region = " + regionId + "\n"
                                ]
                            ]
                        }   
                    },
                    "/etc/awslogs/awslogs.conf" : {
                        "content" : {
                            "Fn::Join" : [
                                "",
                                logContent
                            ]
                        },
                        "mode" : "000755"
                    }
                },
                "commands": {
                    "ConfigureLogsAgent" : {
                        "command" : "/opt/codeontap/bootstrap/awslogs.sh",
                        "ignoreErrors" : ignoreErrors
                    }
                }
            }
        }
    ]
[/#function]

[#function getInitConfigDirsFiles files={} directories={} ignoreErrors=false ]
    
    [#local initFiles = {} ]
    [#list files as fileName,file ]

        [#local fileMode = (file.mode?length == 3)?then(
                                    file.mode?left_pad(6, "0"),
                                    file.mode )]

        [#local initFiles += 
            {
                fileName : {
                    "content" : { 
                        "Fn::Join" : [
                            "",
                            file.content
                        ]
                    },
                    "group" : file.group,
                    "owner" : file.owner,
                    "mode"  : fileMode
                }
            }]
    [/#list]

    [#local initDirFile = [
        "#!/bin/bash\n"
        "exec > >(tee /var/log/codeontap/dirsfiles.log|logger -t codeontap-dirsfiles -s 2>/dev/console) 2>&1\n"
    ]]
    [#list directories as directoryName,directory ]
        [#local initDirFile += [
            "if [[ ! -d \"" + directoryName + "\" ]]; then\n",
            "   mkdir --parents --mode=" + directory.mode + " \"" + directoryName + "\"\n",
            "   chown " + directory.owner + ":" + directory.group + " \"" + directoryName + "\"\n",
            "else\n",
            "   chown -R " + directory.owner + ":" + directory.group + " \"" + directoryName + "\"\n",
            "   chmod " + directory.mode + " \"" + directoryName + "\"\n",
            "fi\n" 
        ]]
    [/#list]

    [#return 
        { } +
        attributeIfContent(
            "CreateDirs",
            directories,
            {
                "files" : {
                    "/opt/codeontap/create_dirs.sh" : {
                        "content" : {
                            "Fn::Join" : [
                                "",
                                initDirFile
                            ]
                        },
                        "mode" : "000755"
                    }
                },
                "commands" : {
                    "CreateDirScript" : {
                        "command" : "/opt/codeontap/create_dirs.sh",
                        "ignoreErrors" : ignoreErrors
                    }
                }
            }
        ) +
        attributeIfContent(
            "CreateFiles",
            files,
            {
                "files" : initFiles
            }

        )
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
    enableCfnSignal=false
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
                "KeyName" : getExistingReference(formatEC2KeyPairId(), NAME_ATTRIBUTE_TYPE),
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
                            ] + enableCfnSignal?then(
                                [
                                    "# Signal the status from cfn-init\n",
                                    "/opt/aws/bin/cfn-signal -e $? ",
                                    "         --stack ", { "Ref": "AWS::StackName" },
                                    "         --resource ", resourceId,
                                    "         --region ", { "Ref": "AWS::Region" }, "\n"
                                ],
                                []
                            )
                            
                        ]
                    }
                }
            }
        outputs={}
        outputId=outputId
        dependencies=dependencies
    /]
[/#macro]
