[#ftl]

[@addComponentDeployment
    type=HEALTHCHECK_COMPONENT_TYPE
    defaultGroup="application"
/]

[@addComponent
    type=HEALTHCHECK_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A external transaction monitor which performs health checks on components"
            }
        ]
    attributes=[
        {
            "Names" : "Type",
            "Description" : "The type of healthcheck to perform",
            "Type" : STRING_TYPE,
            "Values" : [ "simple", "complex" ]
        },
        {
            "Names" : "Schedule",
            "Description" : "The schedule to run the healthcheck",
            "Type" : "STRING_TYPE,
            "Default" : "rate(5 mins)"
        },
        {
            "Names" : "Timeout",
            "Description" : "How long a healthcheck should run without reporting status in seconds",
            "Type" : NUMBER_TYPE,
            "Default" : 30
        },
        {
            "Names" : "Alerts",
            "SubObjects" : true,
            "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "ReportRetention",
            "Description" : "How long to keep status reports for in days",
            "Children" : [
                {
                    "Names" : "Success",
                    "Description" : "Successful runs",
                    "Type" : NUMBER_TYPE,
                    "Default" : 30
                },
                {
                    "Names" : "Failure",
                    "Description" : "Failed runs",
                    "Type" : NUMBER_TYPE,
                    "Default" : 30
                }
            ]
        }
        {
            "Names" : "Type:Complex",
            "Description" : "Complex specific configuration",
            "Children" : [
                {
                    "Names" : "RunTime",
                    "Description" : "The runtime to use for the script execution",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Handler",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                },
                {
                    "Names" : ["Memory", "MemorySize"],
                    "Description" : "The memory to allocate to the script execution",
                    "Types" : NUMBER_TYPE,
                    "Default" : 1024
                },
                {
                    "Names" : "Image",
                    "Description" : "Control the source of the image for the healthcheck script",
                    "Children" : [
                        {
                            "Names" : "Source",
                            "Description" : "The source of the image - registry: the local hamlet registry - url: an external public url - none: no source image",
                            "Types" : STRING_TYPE,
                            "Mandatory" : true,
                            "Values" : [ "registry", "url", "none" ],
                            "Default" : "registry"
                        },
                        {
                            "Names" : "Source:url",
                            "Description" : "Url Source specific Configuration",
                            "Children" : [
                                {
                                    "Names" : "Url",
                                    "Description" : "The Url to the openapi file",
                                    "Types" : STRING_TYPE
                                },
                                {
                                    "Names" : "ImageHash",
                                    "Description" : "The expected sha1 hash of the Url if empty any will be accepted",
                                    "Types" : STRING_TYPE,
                                    "Default" : ""
                                }
                            ]
                        }
                    ]
                },
                {
                    "Names" : "Tracing",
                    "Children" : tracingChildConfiguration
                }
            ]
        },
        {
            "Names" : "Type:Simple",
            "Description" : "Simple healthcheck configuration",
            "Children" : [
                {
                    "Names" : "Destination",
                    "Description" : "The desitination to perform the healthcheck on",
                    "Children" : [
                        {
                            "Names" : "Link",
                            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                        },
                        {
                            "Names" : "Hostname",
                            "Description" : "An explicit Hostname that will be monitored",
                            "Type" : STRING_TYPE
                        },
                        {
                            "Names" : "Port",
                            "Description" : "The name of a port which outlines the healthcheck and protocol details"
                        }
                    ]
                }
            ]
        },
        {
            "Names" : [ "Extensions" ],
            "Description" : "Extensions to invoke as part of component processing",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "Links",
            "SubObjects" : true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Alert",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Network",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
        },
        {
            "Names" : "NetworkAccess",
            "Description" : "Run the healthcheck within the private network",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        }
    ]
/]
