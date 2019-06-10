[#ftl]

[#assign componentConfiguration +=
    {
        BASTION_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "An bastion instance to manage vpc only components"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "segment"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Active",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "OS",
                    "Type" : STRING_TYPE,
                    "Values" : ["linux"],
                    "Default" : "linux"
                },
                {
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration +
                                    [
                                        {
                                            "Names" : "Processor",
                                            "Type" : STRING_TYPE,
                                            "Default" : "default"
                                        }
                                    ]
                },
                {
                    "Names" : "AutoScaling",
                    "Children" : autoScalingChildConfiguration
                },
                {
                    "Names" : "Permissions",
                    "Children" : [
                        {
                            "Names" : "Decrypt",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "AsFile",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "AppData",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "AppPublic",
                            "Type" : BOOLEAN_TYPE,
                            "Default" : false
                        }
                    ]
                },
                {
                    "Names" : "Role",
                    "Description" : "Server configuration role",
                    "Default" : ""
                }
            ]
        }
    }]
