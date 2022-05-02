[#ftl]

[@addComponent
    type=DNS_ZONE_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "DNS Zone"
            }
        ]
    attributes=
        [
            {
                "Names" : "external:ProviderId",
                "Description" : "The provider identifier for the DNS zone",
                "Types" : STRING_TYPE
            },
            {
                "Names": "Profiles",
                "Children" : [
                    {
                        "Names" : "Network",
                        "Description" : "Defines the private network profile applied to the zone ( public if empty)",
                        "Types" : STRING_TYPE,
                        "Default" : ""
                    }
                ]
            }
        ] +
        domainNameChildConfiguration
/]

[@addComponentDeployment
    type=DNS_ZONE_COMPONENT_TYPE
    defaultGroup="solution"
/]
