[#ftl]

[@addReference
    type=BASELINEPROFILE_REFERENCE_TYPE
    pluralType="BaselineProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "The baseline components to use for a given baseilne function"
            }
        ]
    attributes=[
        {
            "Names" : "OpsData",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "AppData",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Encryption",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "SSHKey",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "CDNOriginKey",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
