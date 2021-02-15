[#ftl]

[@addComponentDeployment
    type=INTERNALTEST_COMPONENT_TYPE
    defaultGroup="internal"
/]

[@addComponent
    type=INTERNALTEST_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A hamlet internal testing component"
            }
        ]
    attributes=[
        {
            "Names" : [ "Extensions" ],
            "Description" : "Extensions to invoke as part of component processing",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "Links",
            "Subobjects" : true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        }
    ]
/]
