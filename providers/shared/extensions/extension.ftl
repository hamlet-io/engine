[#ftl]

[#-- extension context management macros --]
[#-- These macros help define sections of context which are used across components --]

[#-- Extension List Macros --]
[#macro Variable name value upperCase=true ]
    [#assign _context = addVariableToContext(_context, name, value, upperCase) ]
[/#macro]

[#function getLinkResourceId link alias]
    [#return (_context.Links[link].State.Resources[alias].Id)!"" ]
[/#function]

[#macro Link name link="" attributes=[] rawName=false ignoreIfNotDefined=false]
    [#assign _context =
        addLinkVariablesToContext(
            _context,
            name,
            contentIfContent(link, name),
            attributes,
            rawName,
            ignoreIfNotDefined) ]

[/#macro]

[#macro DefaultLinkVariables enabled=true ]
    [#assign _context += { "DefaultLinkVariables" : enabled } ]
[/#macro]

[#macro DefaultBaselineVariables enabled=true ]
    [#assign _context += { "DefaultBaselineVariables" : enabled } ]
[/#macro]

[#macro DefaultCoreVariables enabled=true ]
    [#assign _context += { "DefaultCoreVariables" : enabled } ]
[/#macro]

[#macro DefaultEnvironmentVariables enabled=true ]
    [#assign _context += { "DefaultEnvironmentVariables" : enabled } ]
[/#macro]

[#function getExtensionSettingValue key value asBoolean=false]
    [#if value?is_hash]
        [#local name = contentIfContent(value.Setting!"", key) ]

        [#if (value.IgnoreIfMissing!false) &&
            (!((_context.DefaultEnvironment[formatSettingName(true, name)])??)) ]
                [#return valueIfTrue(false, asBoolean, "") ]
        [/#if]
    [#else]
        [#if value?is_string]
            [#local name = value]
        [#else]
            [#return valueIfTrue(true, asBoolean, "HamletFatal: Value for " + key + " must be a string or hash") ]
        [/#if]
    [/#if]
    [#return
        valueIfTrue(
            true,
            asBoolean,
            _context.DefaultEnvironment[formatSettingName(true, name)]!
                "HamletFatal: Variable " + name + " not found"
        ) ]
[/#function]

[#macro AltSettings settings...]
    [#list asFlattenedArray(settings) as setting]
        [#if setting?is_hash]
            [#list setting as key,value]
                [#if getExtensionSettingValue(key, value, true)]
                    [@Variable name=key value=getExtensionSettingValue(key, value) /]
                [/#if]
            [/#list]
        [/#if]
        [#if setting?is_string]
            [@Variable name=setting value=getExtensionSettingValue(setting, setting) /]
        [/#if]
    [/#list]
[/#macro]

[#macro Settings settings...]
    [#list asFlattenedArray(settings) as setting]
        [#if setting?is_hash]
            [#list setting as key,value]
                [@Variable name=key value=value /]
            [/#list]
        [/#if]
        [#if setting?is_string]
            [@Variable name=setting value=getExtensionSettingValue(setting, setting) /]
        [/#if]
    [/#list]
[/#macro]

[#macro Variables variables...]
    [@Settings  variables /]
[/#macro]

[#macro ContextSetting name value ]
    [#assign _context =
                mergeObjects(
                    _context,
                    {
                        "ContextSettings" : {
                            name : value
                        }
                    }
                )]
[/#macro]

[#-- API Specific Macros --]
[#macro OpenAPIDefinition content={} ]
    [#assign _context += {
        "OpenAPIDefinition" : mergeObjects((_context.OpenAPIDefinition)!{}, content )
    }]
[/#macro]

[#-- Lambda Specific Macros --]
[#macro lambdaAttributes
        imageBucket=""
        imagePrefix=""
        zipFile=""
        codeHash=""
        versionDependencies=[]
        createVersionInExtension=false ]

    [#assign _context += {
        "CreateVersionInExtension" : createVersionInExtension
    } +
        attributeIfContent(
            "S3Bucket",
            imageBucket
        ) +
        attributeIfContent(
            "S3Prefix",
            imagePrefix
        ) +
        attributeIfContent(
            "CodeHash",
            codeHash
        ) +
        attributeIfContent(
            "VersionDependencies",
            combineEntities(
                    _context.VersionDependencies,
                    versionDependencies,
                UNIQUE_COMBINE_BEHAVIOUR
            )
        )
    ]

    [#if zipFile?has_content ]
        [#assign _context += {
            "ZipFile" : {
                "Fn::Join" : [
                    "\n",
                    combineEntities(_context.ZipFile, asArray(zipFile), APPEND_COMBINE_BEHAVIOUR)
                ]
            }
        }]
    [/#if]
[/#macro]


[#-- ECS Specific Macros --]
[#macro Host name value]
    [#assign _context +=
        {
            "Hosts" : (_context.Hosts!{}) + { name : value }
        }
    ]
[/#macro]

[#macro Hosts hosts]
    [#if hosts?is_hash]
        [#assign _context +=
            {
                "Hosts" : (_context.Hosts!{}) + hosts
            }
        ]
    [/#if]
[/#macro]

[#macro Hostname hostname ]
    [#assign _context +=
        {
            "Hostname" : hostname
        }
    ]
[/#macro]

[#macro Attributes name="" image="" version="" essential=true]
    [#assign _context +=
        {
            "Essential" : essential
        } +
        attributeIfContent("Name", name) +
        attributeIfContent("Image", image) +
        attributeIfContent("ImageVersion", version)
    ]
[/#macro]


[#macro taskPlacementConstraint expression ]
    [#assign _context +=
        {
            "PlacementConstraints" : combineEntities( _context.PlacementConstraints![], [ expression ], UNIQUE_COMBINE_BEHAVIOUR)
        }
    ]
[/#macro]

[#macro WorkingDirectory workingDirectory ]
    [#assign _context +=
        {
            "WorkingDirectory" : workingDirectory
        }
    ]
[/#macro]

[#macro Volume name="" containerPath="" hostPath="" readOnly=false persist=false volumeLinkId="" driverOpts={} autoProvision=false scope="" volumeEngine="local" ]

    [#if volumeLinkId?has_content ]
        [#if (_context.DataVolumes[volumeLinkId])?has_content]
            [#local volumeName = _context.DataVolumes[volumeLinkId].Name ]
            [#local volumeEngine = _context.DataVolumes[volumeLinkId].Engine ]
        [#else]
            [#local volumeName = "HamletFatal: VolumeLinkId not resolvable" ]
        [/#if]
    [#else]
        [#local volumeName = name!"HamletFatal: Volume Name or VolumeLinkId not provided" ]
    [/#if]

    [#switch volumeEngine ]
        [#case "ebs" ]
            [#local volumeDriver = "rexray/ebs" ]
            [#break]
        [#case "efs"]
            [#local volumeDriver = "efs"]
            [#break]
        [#default]
            [#local volumeDriver = "local" ]
    [/#switch]

    [#assign _context +=
        {
            "Volumes" :
                (_context.Volumes!{}) +
                {
                    volumeName : {
                        "ContainerPath" : containerPath!"HamletFatal : Container Path Not provided",
                        "HostPath" : hostPath,
                        "ReadOnly" : readOnly,
                        "PersistVolume" : persist?is_string?then(
                                            persist?boolean,
                                            persist),
                        "Driver" : volumeDriver,
                        "DriverOpts" : driverOpts,
                        "AutoProvision" : autoProvision
                    } +
                    attributeIfContent(
                        "Scope",
                        scope
                    ) +
                    (volumeDriver == "efs" )?then(
                        {
                            "EFS" : _context.DataVolumes[volumeLinkId].EFS
                        },
                        {}
                    )
                }
        }
    ]
[/#macro]

[#macro Volumes volumes]
    [#if volumes?is_hash]
        [#assign _context +=
            {
                "Volumes" : (_context.Volumes!{}) + volumes
            }
        ]
    [/#if]
[/#macro]

[#macro EntryPoint entrypoint ]
    [#assign _context +=
        {
            "EntryPoint" : asArray(entrypoint)
        }
    ]
[/#macro]

[#macro Command command ]
    [#assign _context +=
        {
            "Command" : asArray(command)
        }
    ]
[/#macro]

[#macro HealthCheck command useShell=true interval=30 retries=3 startPeriod=0 timeout=5  ]

    [#local command = asArray(command) ]

    [#if  !(command[0] == "CMD") && !(command[0] == "CMD-SHELL") ]
        [#local command = [ useShell?then( "CMD-SHELL", "CMD") ] + command ]
    [/#if]

    [#assign _context +=
        {
            "HealthCheck" : {
                "Command" : command,
                "Interval" : interval,
                "Retries" : retries,
                "Timeout" : timeout
            } +
            attributeIfTrue(
                "StartPeriod",
                ( startPeriod > 0 ),
                startPeriod
            )
        }
    ]

[/#macro]


[#macro SecretEnvironment envName secretLinkId secretJsonKey="" version="" ]

    [#local secretRef = ""]

    [#local secret = (_context.Secrets[secretLinkId])!{}]
    [#if secret?has_content ]

        [#switch secret.Provider]
            [#case "aws:secretsmanager"]
                [#local secretRef = {
                    "Fn::Join" : [
                        ":",
                        [
                            getArn(secret.Ref),
                            secretJsonKey,
                            version,
                            ""
                        ]
                    ]
                }]
                [#break]
        [/#switch]

        [#assign _context = mergeObjects(
            _context,
            {
                "SecretEnv" : {
                    envName : {
                        "EnvName" : envName,
                        "SecretRef" : secretRef
                    }
                }
            }
        )]

    [/#if]
[/#macro]

[#-- IAM Specific configuration --]

[#macro Policy statements...]
    [#assign _context +=
        {
            "Policy" : (_context.Policy![]) + asFlattenedArray(statements)
        }
    ]
[/#macro]

[#macro ManagedPolicy arns...]
    [#assign _context +=
        {
            "ManagedPolicy" : (_context.ManagedPolicy![]) + asFlattenedArray(arns)
        }
    ]
[/#macro]

[#-- Compute instance fragment macros --]
[#macro File path mode="644" owner="root" group="root" content=[] ]
    [#assign _context +=
        {
            "Files" : (_context.Files!{}) + {
                path : {
                    "mode" : mode,
                    "owner" : owner,
                    "group" : group,
                    "content" : content
                }
            }
        }]
[/#macro]

[#macro Directory path mode="755" owner="root" group="root" ]
    [#assign _context +=
        {
            "Directories" : (_context.Directories!{}) + {
                path : {
                    "mode" : mode,
                    "owner" : owner,
                    "group" : group
                }
            }
        }]
[/#macro]

[#macro DataVolumeMount volumeLinkId deviceId mountPath ]
    [#assign _context +=
        {
            "VolumeMounts" :
                (_context.VolumeMounts!{}) +
                {
                    volumeLinkId : {
                        "DeviceId" : deviceId,
                        "MountPath" : mountPath
                    }
                }
        }]
[/#macro]

[#macro computeTaskConfigSection computeTaskTypes id engine priority content ]

    [#assign _context +=
        {
            "ComputeTasks" : combineEntities(
                                    (_context.ComputeTasks)![],
                                    asFlattenedArray(computeTaskTypes),
                                    UNIQUE_COMBINE_BEHAVIOUR
                                )
        }
    ]

    [#assign _context +=
        {
            "ComputeTaskConfig" :
                (_context.ComputeTaskConfig!{}) +
                {
                    id : {
                        engine : {
                            "ComputeResourceId" : _context.ComputeResourceId,
                            "Priorty" : priority,
                            "Content" : content
                        }

                    }
                }
        }
    ]
[/#macro]


[#-- CloudFront Specific Fragment Macros --]
[#macro cfCustomHeader name value ]
    [#assign _context +=
        {
            "CustomOriginHeaders" : (_context.CustomOriginHeaders![]) + [
                getCFHTTPHeader(
                    name,
                    value )
            ]
        }]
[/#macro]

[#macro cfForwardHeaders names... ]
    [#assign _context +=
        {
            "ForwardHeaders" : (_context.ForwardHeaders![]) +
                                    asFlattenedArray(names)
        }]
[/#macro]

[#-- User Specific Fragment Macros --]
[#macro userTransferMount name s3LinkId mountPrefix s3Prefix  ]
    [#list _context.Links as id,linkTarget ]
        [#if id == s3LinkId && linkTarget.Core.Type == S3_COMPONENT_TYPE ]
            [#local s3BucketName = linkTarget.State.Attributes["NAME"] ]
        [/#if]
    [/#list]

    [#if s3BucketName?has_content ]
        [#assign _context +=
            {
                "TransferMounts" :
                    (_context.TransferMounts!{}) +
                    {
                        name : getTransferHomeDirectoryMapping(
                                    mountPrefix,
                                    s3BucketName,
                                    s3Prefix
                                )
                    }
            }
        ]
    [/#if]
[/#macro]

[#-- Healthcheck Specific Macro --]
[#macro HealthCheckScript content ]
    [#assign _context +=
        {
            "Script" : content
        }
    ]
[/#macro]

[#-- Template specific Macro --]
[#macro TemplateParameter name value ]
    [#assign _context +=
        {
            "Parameters" :
                (_context.Parameters!{}) +
                { name, value }
        }
    ]
[/#macro]
