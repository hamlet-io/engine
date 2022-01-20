[#ftl]

[@addAttributeSet
    type=PLACEMENTPROFILE_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Manages where resource groups in a component are placed"
        }]
    attributes=[
    {
        "Names" : "*",
        "Children"  : [
            {
                "Names" : "Provider",
                "Description" : "The provider to use to host the component",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Region",
                "Description" : "The id of the region to host the component",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "DeploymentFramework",
                "Description" : "The deployment framework to use to generate the outputs for deployment",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            }
        ]
    }
     ]
/]
