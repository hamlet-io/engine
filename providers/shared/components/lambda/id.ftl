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

[@addComponentDeployment
    type=LAMBDA_FUNCTION_COMPONENT_TYPE
    defaultGroup="application"
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
                "Type" : STRING_TYPE,
                "Values" : ["EDGE", "REGIONAL"],
                "Default" : "REGIONAL"
            },
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Handler",
                "Type" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "LogMetrics",
                "Subobjects" : true,
                "Children" : logMetricChildrenConfiguration
            },
            {
                "Names" : "LogWatchers",
                "Subobjects" : true,
                "Children" : logWatcherChildrenConfiguration
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            },
            {
                "Names" : ["Memory", "MemorySize"],
                "Type" : NUMBER_TYPE,
                "Default" : 0
            },
            {
                "Names" : "RunTime",
                "Type" : STRING_TYPE,
                "Values" : [
                    "dotnetcore1.0",
                    "dotnetcore2.1",
                    "go1.x",
                    "java8",
                    "java11",
                    "nodejs",
                    "nodejs4.3",
                    "nodejs4.3-edge",
                    "nodejs6.10",
                    "nodejs8.10",
                    "nodejs10.x",
                    "nodejs12.x",
                    "python2.7",
                    "python3.6",
                    "python3.7",
                    "python3.8",
                    "ruby2.5"
                ],
                "Mandatory" : true
            },
            {
                "Names" : "Schedules",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Expression",
                        "Type" : STRING_TYPE,
                        "Default" : "rate(6 minutes)"
                    },
                    {
                        "Names" : "InputPath",
                        "Type" : STRING_TYPE,
                        "Default" : "/healthcheck"
                    },
                    {
                        "Names" : "Input",
                        "Type" : OBJECT_TYPE,
                        "Default" : {}
                    }
                ]
            },
            {
                "Names" : "Timeout",
                "Type" : NUMBER_TYPE,
                "Default" : 0
            },
            {
                "Names" : "VPCAccess",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : ["Encrypted", "UseSegmentKey"],
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Permissions",
                "Children" : [
                    {
                        "Names" : "Decrypt",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AsFile",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppData",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "AppPublic",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "PredefineLogGroup",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Environment",
                "Children" : settingsChildConfiguration
            },
            {
                "Names" : "FixedCodeVersion",
                "Children" : [
                    {
                        "Names" : "NewVersionOnDeploy",
                        "Types" : STRING_TYPE,
                        "Description" : "Create a new version on each deployment",
                        "Default" : false
                    },
                    {
                        "Names" : "CodeHash",
                        "Types" : STRING_TYPE,
                        "Description" : "A sha256 hash of the code zip file",
                        "Default" : ""
                    }
                ]
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Alert",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Network",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Logging",
                            "Type" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Tracing",
                "Children" : tracingChildConfiguration
            },
            {
                "Names" : "ReservedExecutions",
                "Type" : NUMBER_TYPE,
                "Default" : -1
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the image that is used for the function",
                "Children" : [
                    {
                        "Names" : "Source",
                        "Description" : "The source of the image - registry is the hamlet registry",
                        "Type" : STRING_TYPE,
                        "Mandatory" : true,
                        "Values" : [ "registry", "url" ],
                        "Default" : "registry"
                    },
                    {
                        "Names" : "UrlSource",
                        "Description" : "Url Source specific Configuration",
                        "Children" : [
                            {
                                "Names" : "Url",
                                "Description" : "The Url to the lambda zip file",
                                "Type" : STRING_TYPE
                            },
                            {
                                "Names" : "ImageHash",
                                "Description" : "The expected sha1 hash of the Url if empty any will be accepted",
                                "Type" : STRING_TYPE,
                                "Default" : ""
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
