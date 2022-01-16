[#ftl]

[@addAttributeSet
    type=SRVREGATTACH_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Attachs a component port to a service registry"
        }]
    attributes=[
        {
            "Names" : "Tier",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Component",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "SubComponent",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Type",
            "Types" : STRING_TYPE,
            "Values" : [ SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE ],
            "Default" : SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE
        },
        {
            "Names" : "LinkName",
            "Types" : STRING_TYPE,
            "Default" : "srvreg"
        },
        {
            "Names" : "Instance",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Version",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "RegistryService",
            "Types" : STRING_TYPE
        }
     ]
/]
