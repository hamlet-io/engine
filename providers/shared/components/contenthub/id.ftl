[#ftl]

[@addComponent
    type=CONTENTHUB_HUB_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Hub for decentralised content hosting with centralised publishing"
            }
        ]
    attributes=
        [
            {
                "Names" : "Prefix",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Engine",
                "Types" : STRING_TYPE,
                "Default" : "github"
            },
            {
                "Names" : "Branch",
                "Types" : STRING_TYPE,
                "Default" : "master"
            },
            {
                "Names" : "Repository",
                "Types" : STRING_TYPE,
                "Default" : ""
            }
        ]
/]

[@addComponentDeployment
    type=CONTENTHUB_HUB_COMPONENT_TYPE
    defaultGroup="application"
/]
