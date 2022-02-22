[#ftl]

[@addAttributeSet
    type=DISTRICT_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Configuration of a district"
        }
    ]
    attributes=[
        {
            "Names" : "InstanceOrder",
            "Description" : "Layers whose configuration data should be included in the solution for an instance of the district",
            "Type" : ARRAY_OF_STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "NamePartOrder",
            "Description" : "Parts to be included in the name of an instance of the district. If not provided, the InstanceOrder is assumed. If not a defined name part, the part is assumed to be a layer.",
            "Type" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "NameParts",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Description" : "Should this part be ignored/omitted?",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Fixed",
                    "Description" : "Include a fixed string",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Ignore",
                    "Description" : "An array of values to not include if encountered",
                    "Type" : ARRAY_OF_STRING_TYPE
                }
            ]
        }
    ]
/]
