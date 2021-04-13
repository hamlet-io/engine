[#ftl]

[@addExtendedAttributeSet
    type=ECS_COMPUTEIMAGE_ATTRIBUTESET_TYPE
    baseType=COMPUTEIMAGE_ATTRIBUTESET_TYPE
    pluralType="ECSComputeImages"
    provider=SHARED_PROVIDER
    properties=[
        {
                "Type"  : "Description",
                "Value" : "ECS Specific overrides to source compute images"
        }]
    attributes=[
        {
            "Names" : "Source:Reference",
            "Children" : [
                {
                    "Names" : "OS",
                    "Default" : "Centos"
                },
                {
                    "Names" : "Type",
                    "Default" : "ECS"
                }
            ]
        }
    ]
/]
