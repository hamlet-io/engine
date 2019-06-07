[#-- Components --]
[#assign CONFIGSTORE_COMPONENT_TYPE = "configstore" ]
[#assign CONFIGSTORE_BRANCH_COMPONENT_TYPE = "configbranch"]

[#assign componentConfiguration +=
    {
        CONFIGSTORE_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "A configuration store to provide dynamic attributes"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : ["Fragment", "Container"],
                    "Type" : STRING_TYPE,
                    "Default" : ""
                },
                {
                    "Names" : "Table",
                    "Children" : dynamoDbTableChildConfiguration
                },
                {
                    "Names" : "SecondaryKey",
                    "Description" : "Uses the name of the branch to provide a secondary sort key on branches - id being the primary",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                }
            ],
            "Components" : [
                {
                    "Type" : CONFIGSTORE_BRANCH_COMPONENT_TYPE,
                    "Component" : "Branches",
                    "Link" : [ "Branch" ]
                }
            ]
        },
        CONFIGSTORE_BRANCH_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A branch of configuration which belongs to a config store"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "States",
                    "Descrption" : "A writable attribute in the config branch",
                    "Subobjects" : true,
                    "Children" : [
                        {
                            "Names" : "InitialValue",
                            "Description" : "The initial value that will be applied to the state",
                            "Type" : STRING_TYPE,
                            "Default" : "-"
                        }
                    ]
                }
            ]
        }
    }]
