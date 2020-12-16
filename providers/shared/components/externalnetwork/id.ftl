[#ftl]

[@addComponentDeployment
    type=EXTERNALNETWORK_COMPONENT_TYPE
    defaultGroup="segment"
/]

[@addComponent
    type=EXTERNALNETWORK_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "An external private network segment which can integrate with other networks"
            }
        ]
    attributes=
        [
            {
                "Names" : "IPAddressGroups",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Ports",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "any" ]
            },
            {
                "Names" : "BGP",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "ASN",
                        "Description" : "The BGP ASN (Autonomous system) Id of the external network",
                        "Types" : NUMBER_TYPE,
                        "Default" : 64512
                    }
                ]
            }
        ]
/]

[@addChildComponent
    type=EXTERNALNETWORK_CONNECTION_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "An external network connection endpoint"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Types" : STRING_TYPE,
                "Values" : [ "SiteToSite" ],
                "Default" : "SiteToSite"
            },
            {
                "Names" : "SiteToSite",
                "Children" : [
                    {
                        "Names" : "PublicIP",
                        "Description" : "The public IP address of the VPN tunnel",
                        "Types" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Reference" : {
                    "Schema" : "attributeset",
                    "Type" : LINK_ATTRIBUTESET_TYPE
                }
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Security",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Alert",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "Alerts",
                "Subobjects" : true,
                "Children" : alertChildrenConfiguration
            }
        ]
    parent=EXTERNALNETWORK_COMPONENT_TYPE
    childAttribute="Connections"
    linkAttributes="Connection"
/]
