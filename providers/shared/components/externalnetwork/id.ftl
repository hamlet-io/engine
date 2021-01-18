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
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Ports",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "any" ]
            },
            {
                "Names" : "BGP",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "ASN",
                        "Description" : "The BGP ASN (Autonomous system) Id of the external network",
                        "Type" : NUMBER_TYPE,
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
                "Type" : STRING_TYPE,
                "Values" : [ "SiteToSite" ],
                "Default" : "SiteToSite"
            },
            {
                "Names" : "SiteToSite",
                "Children" : [
                    {
                        "Names" : "PublicIP",
                        "Description" : "The public IP address of the VPN tunnel",
                        "Type" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Security",
                        "Type" : STRING_TYPE,
                        "Default" : "default"
                    },
                    {
                        "Names" : "Alert",
                        "Type" : STRING_TYPE,
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
