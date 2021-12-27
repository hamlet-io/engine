[#ftl]

[#function getIANAIPProtocolNumber port ]
    [#switch (port.IPProtocol)?lower_case ]
        [#case "tcp" ]
            [#return 6]
            [#break]
        [#case "udp"]
            [#return 17]
            [#break]
        [#case "icmp"]
            [#return 1]
            [#break]
        [#case "gre"]
            [#return 47]
            [#break]
        [#case "esp"]
            [#return 50]
            [#break]
        [#case "ah"]
            [#return 51]
            [#break]
        [#case "ipv6-icmp"]
            [#return 58]
            [#break]
    [/#switch]
    [#return ""]
[/#function]

[@addReference
    type=PORT_REFERENCE_TYPE
    pluralType="Ports"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "An IP based network port"
            }
        ]
    attributes=[
        {
            "Names" : "IPProtocol",
            "Types" : STRING_TYPE,
            "Values" : [ "tcp", "udp", "icmp", "any", "all" ],
            "Mandatory" : true
        },
        {
            "Names" : "Protocol",
            "Types" : STRING_TYPE,
            "Values" : [ "TCP", "UDP", "HTTP", "HTTPS", "SSL" ]
        },
        {
            "Names" : "Port",
            "Types" : NUMBER_TYPE
        },
        {
            "Names" : "HealthCheck",
            "Children" : [
                {
                    "Names" : "Path",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "HealthyThreshold",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE]
                },
                {
                    "Names" : "UnhealthyThreshold",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE ]
                },
                {
                    "Names" : "Interval",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE ]
                },
                {
                    "Names" : "Timeout",
                    "Types" : [ NUMBER_TYPE, STRING_TYPE ]
                },
                {
                    "Names" : "SuccessCodes",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "PortRange",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "From",
                    "Types" : NUMBER_TYPE
                },
                {
                    "Names" : "To",
                    "Types" : NUMBER_TYPE
                }
            ]
        },
        {
            "Names" : "ICMP",
            "Children" : [
                {
                    "Names" : "Code",
                    "Types" : NUMBER_TYPE
                },
                {
                    "Names" : "Type",
                    "Types" : NUMBER_TYPE
                }
            ]
        },
        {
            "Names" : "Certificate",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        }
    ]
/]
