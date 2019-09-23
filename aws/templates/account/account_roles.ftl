[#-- Account level roles --]
[#if commandLineOptions.Deployment.Unit.Name?contains("roles")  || (allDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets="template" /]
    [/#if]

    [#if deploymentSubsetRequired("roles", true)]
        [#assign automationRoleId = formatAccountRoleId("automation")]
        [#assign administratorRoleId = formatAccountRoleId("administrator")]
        [#assign viewerRoleId = formatAccountRoleId("viewer")]

        [#assign accessAccounts=[]]
        [#list accountObject.Access?values as accessAccount]
            [#if accessAccount?is_hash]
                [#assign accessAccounts += [accessAccount.AWSId]]
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

