[#case "couchdb"]
    [#switch containerListMode]
        [#case "definition"]
            [@containerBasicAttributes
                containerName
                "couchdb" + dockerTag
            /]
            [#break]

        [#case "environmentCount"]
        [#case "environment"]
            [@standardEnvironmentVariables
                containerListTarget containerListMode/]

            [#assign adminCredentials = 
                        (credentialsObject[formatComponentShortName(
                                            tier,
                                            component,
                                            containerId)])!""]
            [#if adminCredentials?has_content]
                [@environmentVariable
                    "COUCHDB_USER" adminCredentials.Login.Username
                    containerListTarget containerListMode /]
                [@environmentVariable
                    "COUCHDB_PASSWORD" adminCredentials.Login.Password
                    containerListTarget containerListMode /]
            [#else]
                [@environmentVariable
                    "COUCHDB_USER" "admin"
                    containerListTarget containerListMode /]
                [@environmentVariable
                    "COUCHDB_PASSWORD" "changeme"
                    containerListTarget containerListMode /]
            [/#if]

        [#case "volumeCount"]
        [#case "volumes"]
        [#case "mountPointCount"]
        [#case "mountPoints"]
            [@containerVolume
                "couchdb"
                "/usr/local/var/lib/couchdb"
                "/codeontap/couchdb" /]
            [#break]

        [#case "policyCount"]
        [#case "policy"]
            [@policyHeader
                containerListPolicyName
                containerListPolicyId
                containerListRole/]
            [@cmkDecryptStatement formatSegmentCMKArnId() /]
            [@policyFooter /]
            [#break]

    [/#switch]
    [#break]

