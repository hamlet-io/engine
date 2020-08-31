[#ftl]

[@addComponent
    type=OBJECTSQL_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "SQL based query engine over an object stores"
            },
            {
                "Type" : "Note",
                "Value" : "This componet only deploys the supporting infrastrucure. The table definition will need to be created seperatley",
                "Severity" : "info"
            }
        ]
    attributes=
        [
            {
                "Names" : "DeploymentGroup",
                "Type" : STRING_TYPE,
                "Default" : "solution"
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Encrypted",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "ScanLimitSize",
                "Description" : "The upper limit (cutoff) for the amount of bytes a single query is allowed to scan",
                "Type" : NUMBER_TYPE,
                "Default" : -1
            }
        ]
/]
