[#ftl]

[@addReference
    type=SERVICEROLE_REFERENCE_TYPE
    pluralType="ServiceRoles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Security Roles assigned to cloud services"
            },
            {
                "Type" : "Note",
                "Value" : "AWS - See https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_aws-services-that-work-with-iam.html for supported services"
            }
        ]
    attributes=[
        {
            "Names" : "Enabled",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "ServiceName",
            "Description" : "The Service domain name for the service you want to create the role for",
            "Types" : STRING_TYPE,
            "Mandatory": false
        },
        {
            "Names" : "Description",
            "Description" : "A description to include as part of the Role",
            "Types" : STRING_TYPE,
            "Default" : ""
        }
    ]
/]
