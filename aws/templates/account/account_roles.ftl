[#-- Account level roles --]
[#if deploymentUnit?contains("roles")]
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
        mode=accountListMode
        id=automationRoleId
        name="codeontap-automation"
        trustedAccounts=accessAccounts
        managedArns=
            [
                "arn:aws:iam::aws:policy/AdministratorAccess"
            ]
    /]
    [@createRole
        mode=accountListMode
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
        mode=accountListMode
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

