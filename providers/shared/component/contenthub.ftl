[#ftl]

[@addComponent
    type=CONTENTHUB_HUB_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Hub for decentralised content hosting with centralised publishing"
            },
            {
                "Type" : "Providers",
                "Value" : [ "github" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "application"
            }
        ]
/]

[@addComponentResourceGroup
    type=CONTENTHUB_HUB_COMPONENT_TYPE
    attributes=
        [
            {
                "Names" : "Prefix",
                "Type" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Engine",
                "Type" : STRING_TYPE,
                "Default" : "github"
            },
            {
                "Names" : "Branch",
                "Type" : STRING_TYPE,
                "Default" : "master"
            },
            {
                "Names" : "Repository",
                "Type" : STRING_TYPE,
                "Default" : ""
            }
        ]
/]
