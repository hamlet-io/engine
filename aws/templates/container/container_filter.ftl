[#case "filter"]
    [#assign es = component.Links["es"]]
    [#assign sharedCredential = credentialsObject["shared"]]
    
    [@Attributes image="esfilter" /]
    
    [@Variables
        {
            "CONFIGURATION" : appsettings?json_string,
            "ES" :
                getReference(
                    formatElasticSearchId(
                        es.Tier,
                        es.Component),
                    DNS_ATTRIBUTE_TYPE) + ":443",
            "DATA_USERNAME" : sharedCredential.Data.Username,
            "DATA_PASSWORD" : sharedCredential.Data.Password,
            "QUERY_USERNAME" : sharedCredential.Query.Username,
            "QUERY_PASSWORD" : sharedCredential.Query.Password
        }
    /]
            
    [@Policy credentialsDecryptPermission() /]

    [#break]

