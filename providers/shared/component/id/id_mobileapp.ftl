[#-- Components --]
[#assign MOBILEAPP_COMPONENT_TYPE = "mobileapp"]

[#assign componentConfiguration +=
    {
        MOBILEAPP_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "mobile apps with over the air update hosting"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "application"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Engine",
                    "Type" : STRING_TYPE,
                    "Default" : "expo",
                    "Values" : ["expo"]
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "BuildFormats",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Default" : [ "ios", "android" ],
                    "Values" : [ "ios", "android" ]
                },
                {
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        }
    }]
