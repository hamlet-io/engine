[#ftl]

[@addComponentDeployment
    type=CONTAINERSERVICE_COMPONENT_TYPE
    defaultGroup="application"
/]

[@addComponent
    type=CONTAINERSERVICE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "An orchestrated container with always on scheduling"
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
    attributes=containerServiceAttributes
/]