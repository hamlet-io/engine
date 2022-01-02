[#ftl]

[@addTask
    type=SET_PROVIDER_CREDENTIALS_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Use the hamlet context to define the credentials for cloud providers"
            }
        ]
    attributes=[
        {
            "Names" : "AccountId",
            "Description" : "The hamlet Account Id for the provider login",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Provider",
            "Description" : "The name of the provider the account is defined for",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "ProviderId",
            "Description" : "The Id that represents the account with the provider",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
