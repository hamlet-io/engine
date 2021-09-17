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
            }
        ]
/]

[@addComponentDeployment
    type=DNS_ZONE_COMPONENT_TYPE
    defaultGroup="solution"
/]
