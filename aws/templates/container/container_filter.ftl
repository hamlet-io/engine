[#case "filter"]
    [#assign es = component.Links["es"]]
    [#assign sharedCredential = credentialsObject["shared"]]
    
    [@containerBasicAttributes
        name=containerName
        mode=containerListMode
        image="esfilter" + dockerTag
    /]

    [@standardEnvironmentVariables
        containerListTarget containerListMode /]

    [@environmentVariable
        "CONFIGURATION" appsettings?json_string
        containerListTarget containerListMode /]

    [@environmentVariable
        "ES" getReference(
                formatElasticSearchId(
                    es.Tier,
                    es.Component),
                DNS_ATTRIBUTE_TYPE) + ":443"
        containerListTarget containerListMode /]

    [@environmentVariable
        "DATA_USERNAME" sharedCredential.Data.Username
        containerListTarget containerListMode /]

    [@environmentVariable
        "DATA_PASSWORD" sharedCredential.Data.Password
        containerListTarget containerListMode /]

    [@environmentVariable
        "QUERY_USERNAME" sharedCredential.Query.Username
        containerListTarget containerListMode /]

    [@environmentVariable
        "QUERY_PASSWORD" sharedCredential.Query.Password
        containerListTarget containerListMode /]
            
    [@createPolicy
        mode=containerListMode
        id=containerListPolicyId
        name=containerListPolicyName
        statements=
            getCmkDecryptStatement(formatSegmentCMKArnId())
        roles=containerListRole
    /]

    [#break]

