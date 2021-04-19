[#ftl]

[@addAttributeSet
    type=LINK_ATTRIBUTESET_TYPE
    pluralType="Links"
    properties=[
        {
                "Type"  : "Description",
                "Value" : "A relationship between Components."
        }]
    attributes=[
        {
            "Names" : "Any",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Tenant",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Product",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Environment",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Segment",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Tier",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Component",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : ["Function"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["Service"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["Task"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["PortMapping", "Port"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["Mount"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : ["Platform"],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "RouteTable" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "NetworkACL" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "DataBucket" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Key" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Branch" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Client" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Connection" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "AuthProvider" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Resource" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "DataFeed" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "RegistryService" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Assignment" ],
            "Type" : STRING_TYPE
        },
        {
            "Names" : [ "Route" ],
            "Type"  : STRING_TYPE
        },
        {
            "Names" : [ "Endpoint" ],
            "Type"  : STRING_TYPE
        },
        {
            "Names" : [ "Rule" ],
            "Type"  : STRING_TYPE
        },
        {
            "Names" : "Instance",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Version",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Secret",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Role",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Direction",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Type",
            "Type" : STRING_TYPE
        },
        {
            "Names" : "Enabled",
            "Type" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "IncludeInContext",
            "Type" : ARRAY_OF_STRING_TYPE
        }
    ]
/]