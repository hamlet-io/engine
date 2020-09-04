[#ftl]

[@addComponent
    type=CONTAINERTASK_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A container defintion which is invoked on demand"
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
    attributes=containerTaskAttributes
/]