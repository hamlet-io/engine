[#ftl]
[#include "setContext.ftl" ]

[#-- Domains --]
[#assign accountDomainStem = accountObject.Domain.Stem]
[#assign accountDomainBehaviour = (accountObject.Domain.AccountBehaviour)!""]
[#assign accountDomainCertificateId = accountObject.Domain.Certificate.Id]
[#switch accountDomainBehaviour]
    [#case "accountInDomain"]
        [#assign accountDomain = accountName + "." + accountDomainStem]
        [#assign accountDomainQualifier = ""]
        [#assign accountDomainCertificateId = formatId(accountDomainCertificateId, accountId)]
        [#break]
    [#case "naked"]
        [#assign accountDomain = accountDomainStem]
        [#assign accountDomainQualifier = ""]
        [#break]
    [#case "accountInHost"]
    [#default]
        [#assign accountDomain = accountDomainStem]
        [#assign accountDomainQualifier = formatName("", accountName)]
        [#break]
[/#switch]
[#-- TODO: check if this can be deleted or accountDomainCertificateId really may conatins "-"
[#assign accountDomainCertificateId = accountDomainCertificateId?replace("-","X")]
--]

[#assign categoryId = "account"]

{
    "AWSTemplateFormatVersion" : "2010-09-09",
    [#include "templateMetadata.ftl"],
    "Resources" : {
        [#assign resourceCount = 0]
        [#assign accountListMode="definition"]
        [#include accountList]
    },
    "Outputs" : 
    {
        [#assign resourceCount = 0]
        [#assign accountListMode="outputs"]
        [#include accountList]
    }
}
