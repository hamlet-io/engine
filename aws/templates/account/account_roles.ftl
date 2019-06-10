[#-- Account level roles --]
[#if deploymentUnit?contains("roles")  || (allDeploymentUnits!false) ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
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
            mode=listMode
            id=automationRoleId
            name="codeontap-automation"
            trustedAccounts=accessAccounts
            managedArns=
                [
                    "arn:aws:iam::aws:policy/AdministratorAccess"
                ]
        /]
        [@createRole
            mode=listMode
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
            mode=listMode
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

