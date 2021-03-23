[#-- Account level roles --]
[#if getCLODeploymentUnit()?contains("roles")  || (groupDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("generationcontract", false)]
        [@addDefaultGenerationContract subsets="template" /]
    [/#if]


    [@includeServicesConfiguration
        provider=AWS_PROVIDER
        services=[AWS_IDENTITY_SERVICE ]
        deploymentFramework=getCLODeploymentFramework()
    /]

    [#if deploymentSubsetRequired("roles", true)]
        [#assign automationRoleId = formatAccountRoleId("automation")]
        [#assign administratorRoleId = formatAccountRoleId("administrator")]
        [#assign viewerRoleId = formatAccountRoleId("viewer")]

        [#assign accessAccounts=[]]
        [#list accountObject.Access?values as accessAccount]
            [#if accessAccount?is_hash]
                [#assign accessAccounts += [accessAccount.ProviderId]]
            [/#if]
        [/#list]

        [@createRole
            id=automationRoleId
            name="codeontap-automation"
            trustedAccounts=accessAccounts
            managedArns=
                [
                    "arn:aws:iam::aws:policy/AdministratorAccess"
                ]
        /]
        [@createRole
            id=administratorRoleId
            name="codeontap-administrator"
            trustedAccounts=accessAccounts
            managedArns=
                [
                    "arn:aws:iam::aws:policy/AdministratorAccess"
                ]
            multiFactor=true
        /]
        [@createRole
            id=viewerRoleId
            name="codeontap-viewer"
            trustedAccounts=accessAccounts
            managedArns=
                [
                    "arn:aws:iam::aws:policy/ReadOnlyAccess"
                ]
            multiFactor=true
        /]
    [/#if]
[/#if]
