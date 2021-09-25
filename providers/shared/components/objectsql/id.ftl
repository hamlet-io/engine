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
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Encrypted",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "ScanLimitSize",
                "Description" : "The upper limit (cutoff) for the amount of bytes a single query is allowed to scan",
                "Types" : NUMBER_TYPE,
                "Default" : -1
            }
        ]
/]

[@addComponentDeployment
    type=OBJECTSQL_COMPONENT_TYPE
    defaultGroup="solution"
/]
