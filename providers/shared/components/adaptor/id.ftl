[#ftl]

[@addComponentDeployment
    type=ADAPTOR_COMPONENT_TYPE
    defaultGroup="application"
/]

[@addComponent
    type=ADAPTOR_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A generic deployment process for non standard components"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "application"
            }
        ]
    attributes=
        [
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
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
