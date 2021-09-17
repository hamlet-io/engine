[#ftl]

[@addComponent
    type=HOSTING_PLATFORM_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A place where resources can physically be deployed"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Description" : "Engine will determine what attributes the platform exposes",
                "Types" : STRING_TYPE,
                "Values" : ["region"],
                "Default" : "region",
                "Mandatory" : true
            },
            {
                "Names" : "Engine:region",
                "Description" : "Placement of resources within a region",
                "Children" : [
                    {
                        "Names" : "Region",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=HOSTING_PLATFORM_COMPONENT_TYPE
    defaultGroup="solution"
/]
