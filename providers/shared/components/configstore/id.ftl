[#ftl]

[@addComponent
    type=CONFIGSTORE_COMPONENT_TYPE
    properties=
        [
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
        ]
    attributes=
        [
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
        ]
/]

[@addChildComponent
    type=CONFIGSTORE_BRANCH_COMPONENT_TYPE
    properties=
        [
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
        ]
    attributes=
        [
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "States",
                "Description" : "A writable attribute in the config branch",
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
    parent=CONFIGSTORE_COMPONENT_TYPE
    childAttribute="Branches"
    linkAttributes="Branch"
/]
