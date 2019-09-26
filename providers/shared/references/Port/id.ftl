[#ftl]

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
            "Type" : STRING_TYPE,
            "Values" : [ "tcp", "udp", "icmp", "any", "all" ],
            "Mandatory" : true
        },
        {
            "Names" : "Protocol",
            "Type" : STRING_TYPE,
            "Values" : [ "TCP", "UDP", "HTTP", "HTTPS", "SSL" ]
        },
        {
            "Names" : "Port",
            "Type" : NUMBER_TYPE
        },
        {
            "Names" : "HealthCheck",
            "Children" : [
                {
                    "Names" : "Path",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "HealthyThreshold",
                    "Type" : [ NUMBER_TYPE, STRING_TYPE] 
                },
                {
                    "Names" : "UnhealthyThreshold",
                    "Type" : [ NUMBER_TYPE, STRING_TYPE ]
                },
                {
                    "Names" : "Interval",
                    "Type" : [ NUMBER_TYPE, STRING_TYPE ]
                },
                {
                    "Names" : "Timeout",
                    "Type" : [ NUMBER_TYPE, STRING_TYPE ]
                }
            ]
        },
        {
            "Names" : "PortRange",
            "Children" : [
                {
                    "Names" : "From",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "To",
                    "Type" : NUMBER_TYPE
                }
            ]
        },
        {
            "Names" : "ICMP",
            "Children" : [
                {
                    "Names" : "Code",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "Type",
                    "Type" : NUMBER_TYPE
                }
            ]
        }
    ]
/]