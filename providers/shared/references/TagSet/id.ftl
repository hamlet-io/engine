[#ftl]

[@addReference
    type=TAGSET_REFERENCE_TYPE
    pluralType="TagSets"
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Defines tag metadata that will be applied to resources"
        }]
    attributes=[
        {
            "Names" : "Include",
            "Description" : "Tags that will be included based on the context of your deployment",
            "Children"  : [
                {
                    "Names" : "References",
                    "Description" : "Include deployment and configuration references",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
                {
                    "Names" : "Layers",
                    "Description" : "Include the layers that the occurrence belongs to",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Solution",
                    "Description" : "Include details of the solution the occurrence belongs to",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
                {
                    "Names" : "Name",
                    "Description" : "The name of the component",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
            ]
        },
        {
            "Names" : "Additional",
            "Description": "Extra tags that will be included",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Value",
                    "Description" : "The value of the tag to apply",
                    "Types" : STRING_TYPE,
                    "Mandatory" : true
                }
            ]
        }
    ]
/]
