[#ftl]

[@addAttributeSet
    type=SECRETSOURCE_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Control how a secret is sourced"
        }]
    attributes=[
        {
            "Names" : "Source",
            "Types" : STRING_TYPE,
            "Values" : [ "user", "generated" ],
            "Default" : "user"
        },
        {
            "Names" : "Requirements",
            "Description" : "Format requirements for the Secret",
            "AttributeSet" : SECRETSTRING_ATTRIBUTESET_TYPE
        }
    ]
/]
