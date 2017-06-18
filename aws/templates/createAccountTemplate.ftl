[#ftl]
[#include "setContext.ftl" ]

[#-- Initialisation --]

[#-- Domains --]
[#if accountDomain??]
    [#assign accountDomainObject = domains[accountDomain]]
    [#assign accountDomainStem = accountDomainObject.Stem]
    [#assign accountDomainBehaviour = (accountDomainObject.AccountBehaviour)!""]
    [#assign accountDomainCertificateId = accountDomainObject.Certificate.Id]
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

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    "Resources" : {
        [@noResourcesCreated /]
        [#assign accountListMode="definition"]
        [#include accountList]
    },
    "Outputs" : 
    {
        [@noResourcesCreated /]
        [#assign accountListMode="outputs"]
        [#include accountList]
    }
}
