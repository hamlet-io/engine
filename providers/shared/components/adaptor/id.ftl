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
                "Names" : ["Fragment", "Container"],
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]
