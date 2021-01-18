[#ftl]

[@addComponentDeployment
    type=PRIVATE_SERVICE_COMPONENT_TYPE
    defaultGroup="solution"
/]


[@addComponent
    type=PRIVATE_SERVICE_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Private service offering to other entities"
            }
        ]
    attributes=
        [
            {
                "Names" : "DomainName",
                "Children" : domainNameChildConfiguration
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Sharing",
                "Children" : [
                    {
                        "Names" : "Principals",
                        "Description" : "A list of external entities to share the service with",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    },
                    {
                        "Names" : "ApprovalRequired",
                        "Description" : "Manual approval required for the service to be consumed",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ]
            },
            {
                "Names" : "ConnectionAlerts",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Events",
                        "Type" : ARRAY_OF_STRING_TYPE,
                        "Values" : [ "Accept", "Connect", "Delete", "Reject" ],
                        "Default" : [ "Accept", "Reject" ]
                    },
                    {
                        "Names" : "Links",
                        "Description" : "Link to send alerts to",
                        "Subobjects" : true,
                        "Children" : linkChildrenConfiguration
                    }
                ]
            }
        ]
/]
