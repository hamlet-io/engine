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
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "AppData",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Encryption",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "SSHKey",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "CDNOriginKey",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]