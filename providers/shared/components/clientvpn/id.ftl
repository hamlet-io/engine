[#ftl]

[@addComponent
    type=CLIENTVPN_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A client based VPN service"
            }
        ]
    attributes=
        [
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Profiles",
                "Children" :
                    [
                        {
                            "Names" : "Network",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        },
                        {
                            "Names" : "Logging",
                            "Description" : "profile to define where logs are forwarded to from this component",
                            "Types" : STRING_TYPE,
                            "Default" : "default"
                        }
                    ]
            },
            {
                "Names" : "Logging",
                "Description" : "Enable client connection logging",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Network",
                "Children" : [
                    {
                        "Names" : "ClientCIDR",
                        "Description" : "The CIDR Address Range used for vpn clients",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "ManageDNS",
                        "Description" : "Should the VPN control the DNS resolution of the client",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "SplitTunnel",
                        "Description" : "Only route specific traffic over the tunnel",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "Destinations",
                        "Description" : "Where VPN Clients can route to",
                        "Children" : [
                            {
                                "Names" : "IPAddressGroups",
                                "Description" : "A list of IP address Groups the VPN can access",
                                "Types" : ARRAY_OF_STRING_TYPE,
                                "Default" : [ "_localnet" ]
                            }
                        ]
                    }
                ]
            },
            {
                "Names" : "Authentication",
                "Description" : "Configure authentication for the VPN",
                "Children" : [
                    {
                        "Names" : "Provider",
                        "Description" : "The details of the authentication provider",
                        "Children" : [
                            {
                                "Names" : "Link",
                                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                            }
                        ]
                    },
                    {
                        "Names" : "MutualTLS",
                        "Description" : "Require MutualTLS for VPN client connections",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    }
                ]
            },
            {
                "Names" : "AuthorisationRules",
                "Description" : "Authorisation rules to apply on VPN Connections",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Condition",
                        "Description" : "The condition of the rule",
                        "Values" : [ "allclients", "group" ],
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names" : "condition:Group",
                        "Children" : [
                            {
                                "Names" : "GroupId",
                                "Description" : "The Id of the group from the provider to apply the condition to",
                                "Types" : STRING_TYPE
                            }
                        ]
                    }
                    {
                        "Names" : "Destinations",
                        "Description" : "Where VPN clients that match this rule can access",
                        "Children" : [
                            {
                                "Names" : "IPAddressGroups",
                                "Description" : "A list of IP address Groups the VPN can access",
                                "Types" : ARRAY_OF_STRING_TYPE,
                                "Default" : [ "_localnet" ]
                            }
                        ]
                    }
                ]
            },
            {
                "Names" : "Port",
                "Description" : "The Id of the port reference to use for the public VPN connection",
                "Types" : STRING_TYPE,
                "Default" : "https"
            },
            {
                "Names" : "SelfServicePortal",
                "Description" : "Enable the use of a self service portal for VPN Setup",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Certificate",
                "Description" : "The certificate hostname to use for the clientVPN",
                "AttributeSet" : CERTIFICATE_ATTRIBUTESET_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=CLIENTVPN_COMPONENT_TYPE
    defaultGroup="segment"
/]
