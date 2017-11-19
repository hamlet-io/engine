[#ftl]
[#include "setContext.ftl" ]

[#-- Initialisation --]

[#-- Domains --]
[#if accountDomain?has_content]
    [#assign accountDomainObject = domains[accountDomain]]
    [#assign accountDomainStem = accountDomainObject.Stem]
    [#assign accountDomainBehaviour =
            (accountDomainObject.Product)!
            (accountDomainObject.ProductBehaviour)!
            ""]
    [#assign accountDomainValidation =
                (productDomainObject.Validation)!
                (domains.Validation)!
                ""]           
    [#assign accountDomainCertificateId = accountDomain]
    [#switch accountDomainBehaviour]
        [#case "accountInDomain"]
            [#assign accountDomain = accountName + "." + accountDomainStem]
            [#assign accountDomainQualifier = ""]
            [#assign accountDomainCertificateId = formatName(accountDomainCertificateId, accountId)]
            [#break]
        [#case "naked"]
            [#assign accountDomain = accountDomainStem]
            [#assign accountDomainQualifier = ""]
            [#break]
        [#case "accountInHost"]
        [#default]
            [#assign accountDomain = accountDomainStem]
            [#assign accountDomainQualifier = accountName]
            [#break]
    [/#switch]
    [#-- TODO: check if this can be deleted or accountDomainCertificateId really may conatins "-" --]
    [#assign accountDomainCertificateId = accountDomainCertificateId?replace("-","X")]
[/#if]
[#assign categoryId = "account"]

[@cfTemplate
    level="account"
    include=accountList /]
