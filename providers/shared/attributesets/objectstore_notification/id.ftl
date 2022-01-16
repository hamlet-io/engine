[#ftl]

[@addAttributeSet
    type=OBJECTSTORE_NOTIFICATION_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Event notification for object changes in an object store"
        }]
    attributes=[
        {
            "Names" : "Enabled",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Links",
            "SubObjects": true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "Prefix",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Suffix",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Events",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : [ "create" ],
            "Values" : [ "create", "delete", "restore", "reducedredundancy" ]
        }
     ]
/]
