[#ftl]

[@addAttributeSet
    type=MODULE_ATTRIBUTESET_TYPE
    pluralType="Modules"
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Defines the CMDB modules to load"
        }]
    attributes=[
        {
            "Names" : "Enabled",
            "Description" : "To enable loading the module in this profile",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Provider",
            "Description" : "The provider name which offers the module",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Name",
            "Description" : "The name of the scneario to load",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Parameters",
            "Description" : "The parameter values to provide to the module",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "Key",
                    "Type" : STRING_TYPE,
                    "Description" : "The key of the parameter",
                    "Mandatory" : true
                },
                {
                    "Names" : "Value",
                    "Type" : ANY_TYPE,
                    "Description" : "The value of the parameter",
                    "Mandatory" : true
                }
            ]
        }
    ]
/]
