[#ftl]

[@addReference 
    type=VIRTUAL_MACHINE_IMAGE_REFERENCE_TYPE
    pluralType="VMImageProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A virtual machine operating system configuration" 
            }
        ]
    attributes=[
        {
            "Names" : "Publisher",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Offering",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "SKU",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "LicenseType",
            "Type" : STRING_TYPE,
            "Mandatory" : false
        }
    ]
/]