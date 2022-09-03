[#ftl]

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
            "Names" : "Engine",
            "Description" : "The type of healthcheck to perform",
            "Type" : STRING_TYPE,
            "Values" : [ "Simple", "Complex" ],
            "Mandatory" : true
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
            "Names" : "Engine:Complex",
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
                            "Values" : [ "link", "registry", "url", "none" ],
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
                        },
                        {
                            "Names": "Link",
                            "AttributeSet": LINK_ATTRIBUTESET_TYPE
                        },
                        {
                            "Names" : "ScriptFileName",
                            "Description" : "The name of the healthcheck script if the image is a zip",
                            "Types" : STRING_TYPE,
                            "Default" : "healthcheck.py"
                        }
                    ]
                },
                {
                    "Names" : "Tracing",
                    "AttributeSet" : TRACING_ATTRIBUTESET_TYPE
                },
                {
                    "Names" : "Schedule",
                    "Description" : "The schedule to run the healthcheck",
                    "Type" : STRING_TYPE,
                    "Default" : "rate(5 minutes)"
                }
            ]
        },
        {
            "Names" : "Engine:Simple",
            "Description" : "Simple healthcheck configuration",
            "Children" : [
                {
                    "Names" : "Destination",
                    "Description" : "The desitination to perform the healthcheck on",
                    "Children" : [
                        {
                            "Names" : "AddressType",
                            "Description" : "The type of address to monitor",
                            "Values" : [ "Hostname", "IP" ],
                            "Default" : "Hostname"
                        },
                        {
                            "Names" : "Link",
                            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                        },
                        {
                            "Names" : "LinkAttribute",
                            "Description" : "The attribute of the linked occurrence to use for the address",
                            "Type" : STRING_TYPE,
                            "Default" : "FQDN"
                        },
                        {
                            "Names" : "Address",
                            "Description" : "An explicit address to monitor",
                            "Type" : STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Port",
                    "Description" : "The name of a port which sets the healthcheck protocol details",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "HTTPSearchString",
                    "Description" : "When using HTTP checks a string that must be present in the response body",
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "HTTPSearchSetting",
                    "Description" : "The name of a setting that contains the HTTP Search string to use",
                    "Type" : STRING_TYPE
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
                }
            ]
        },
        {
            "Names" : "NetworkAccess",
            "Description" : "Run the healthcheck within the private network",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Regions",
            "Description" : "A list of regions to run the health check from - _product: is the product region - _all: is all available regions",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : [ "_all" ]
        }
    ]
/]

[@addComponentDeployment
    type=HEALTHCHECK_COMPONENT_TYPE
    defaultGroup="application"
/]
