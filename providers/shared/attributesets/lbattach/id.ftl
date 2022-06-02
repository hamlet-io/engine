[#ftl]

[@addAttributeSet
    type=LBATTACH_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Attaches a components port to a load balancer"
        }]
    attributes=[
        {
            "Names" : "LinkRef",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Tier",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Component",
            "Types" : STRING_TYPE
        },
        {
            "Names" : ["SubComponent", "PortMapping", "Port"],
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : "Type",
            "Types" : STRING_TYPE,
            "Values" : [ LB_PORT_COMPONENT_TYPE, LB_BACKEND_COMPONENT_TYPE ],
            "Default" : LB_PORT_COMPONENT_TYPE
        },
        {
            "Names" : "LinkName",
            "Types" : STRING_TYPE,
            "Default" : "lb"
        },
        {
            "Names" : "Instance",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Version",
            "Types" : STRING_TYPE
        }
     ]
/]
