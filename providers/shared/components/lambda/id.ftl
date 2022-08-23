[#ftl]

[@addComponent
    type=LAMBDA_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Container for a Function as a Service deployment"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "application"
            }
        ]
    attributes=
        [
        ]
/]

[@addChildComponent
    type=LAMBDA_FUNCTION_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A specific entry point for the lambda deployment"
            }
        ]
    attributes=
        [
            {
                "Names" : "DeploymentType",
                "Types" : STRING_TYPE,
                "Values" : ["EDGE", "REGIONAL"],
                "Default" : "REGIONAL"
            },
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Handler",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "LogMetrics",
                "SubObjects" : true,
                "AttributeSet" : LOGMETRIC_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "LogWatchers",
                "SubObjects" : true,
                "AttributeSet" : LOGWATCHER_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Alerts",
                "SubObjects" : true,
                "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
            },
            {
                "Names" : ["Memory", "MemorySize"],
                "Types" : NUMBER_TYPE,
                "Default" : 0
            },
            {
                "Names" : "RunTime",
                "Types" : STRING_TYPE,
                "Description" : "Must be a valid runtime engine such as nodejs14.x. Refer https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html or https://docs.microsoft.com/en-us/azure/azure-functions/supported-languages",
                "Values" : [
                    "dotnet6",
                    "dotnetcore3.1",
                    "go1.x",
                    "java8",
                    "java11",
                    "nodejs12.x",
                    "nodejs14.x",
                    "nodejs16.x",
                    "python3.7",
                    "python3.8",
                    "python3.9",
                    "ruby2.7"
                ],
                "AdditionalValues" : true,
                "Mandatory" : true
            },
            {
                "Names" : "Schedules",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Expression",
                        "Types" : STRING_TYPE,
                        "Default" : "rate(6 minutes)"
                    },
                    {
                        "Names" : "InputPath",
                        "Types" : STRING_TYPE,
                        "Default" : "/healthcheck"
                    },
                    {
                        "Names" : "Input",
                        "Types" : OBJECT_TYPE,
                        "Default" : {}
                    }
                ]
            },
            {
                "Names" : "Timeout",
                "Types" : NUMBER_TYPE,
                "Default" : 0
            },
            {
                "Names" : "VPCAccess",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : ["Encrypted", "UseSegmentKey"],
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Permissions",
                "Children" : [
                    {
                        "Names" : "Decrypt",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AsFile",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppData",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppPublic",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "PredefineLogGroup",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Environment",
                "AttributeSet" : ENVIRONMENTFORMAT_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "FixedCodeVersion",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "NewVersionOnDeploy",
                        "Types" : BOOLEAN_TYPE,
                        "Description" : "Create a new version on each deployment",
                        "Default" : false
                    },
                    {
                        "Names" : "CodeHash",
                        "Types" : STRING_TYPE,
                        "Description" : "A sha256 hash of the code zip file",
                        "Default" : ""
                    },
                    {
                        "Names" : "DeletionPolicy",
                        "Types" : STRING_TYPE,
                        "Description" : "What should happen to the superceded version when new version on deploy?",
                        "Values" : [ "Delete", "Retain" ],
                        "Default" : "Retain"
                    },
                    {
                        "Names" : "Alias",
                        "Types" : STRING_TYPE,
                        "Description" : "Provide a logical name pointing to the most recent version"
                    }
                ]
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Alert",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Network",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Logging",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Tracing",
                "AttributeSet" : TRACING_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "ReservedExecutions",
                "Description" : "Number of instances within the overall account limit reserved for this function. This ensure it can scale out to this reservation regardless of what other functions do.",
                "Types" : NUMBER_TYPE,
                "Default" : -1
            },
            {
                "Names" : "ProvisionedExecutions",
                "Description" : "Minimum number of instances that should be available to service requests. It forms part of any configured reserved execution limit.",
                "Types" : NUMBER_TYPE,
                "Default" : -1
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the image that is used for the function",
                "Children" : [
                    {
                        "Names" : "Source",
                        "Description" : "The source of the image - registry is the hamlet registry",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true,
                        "Values" : [ "registry", "url", "extension" ],
                        "Default" : "registry"
                    },
                    {
                        "Names" : ["source:Url", "UrlSource"],
                        "Description" : "Url Source specific Configuration",
                        "Children" : [
                            {
                                "Names" : "Url",
                                "Description" : "The Url to the lambda zip file",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names" : "ImageHash",
                                "Description" : "The expected sha1 hash of the Url if empty any will be accepted",
                                "Types" : STRING_TYPE,
                                "Default" : ""
                            }
                        ]
                    },
                    {
                        "Names" : "source:Extension",
                        "Description" : "Use an inline extension to set the content of the function",
                        "Children" : [
                            {
                                "Names" : "IncludeRunId",
                                "Description" : "Adds the RunId as a comment to ensure that it is unique",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names" : "CommentCharacters",
                                "Description" : "The single line comment sequence for your language",
                                "Types" : STRING_TYPE,
                                "Default" : '//'
                            }
                        ]
                    }
                ]
            }
        ]
    parent=LAMBDA_COMPONENT_TYPE
    childAttribute="Functions"
    linkAttributes="Function"
/]

[@addComponentDeployment
    type=LAMBDA_FUNCTION_COMPONENT_TYPE
    defaultGroup="application"
/]
