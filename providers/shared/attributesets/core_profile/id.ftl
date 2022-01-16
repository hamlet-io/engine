[#ftl]

[@addAttributeSet
    type=CORE_PROFILE_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Internal: desribes the base profiles for all components"
        }]
    attributes=[
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Deployment",
                    "Description" : "A list of deployment profiles to apply to this component",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Policy",
                    "Description" : "A list of enforced deployment profiles which override component configuraiton",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Placement",
                    "Description" : "The resource group assignment placement for resources in the component",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Baseline",
                    "Description" : "The profile used to lookup standard services provided by the segment baseline",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Testing",
                    "Description" : "The testing profiles to apply to the component",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                }
            ]
        }
     ]
/]
