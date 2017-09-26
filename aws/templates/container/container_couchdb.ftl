[#case "couchdb"]

    [@Attributes image="couchdb" /]

    [#assign adminCredentials = 
                (credentialsObject[formatComponentShortName(
                                    tier,
                                    component,
                                    containerId)])!""]
    [#if adminCredentials?has_content]
        [@Variables
            {
                "COUCHDB_USER" : adminCredentials.Login.Username,
                "COUCHDB_PASSWORD" : adminCredentials.Login.Password
            }
        /]
    [#else]
        [@Variables
            {
                "COUCHDB_USER" : "admin",
                "COUCHDB_PASSWORD" : "changeme"
            }
        /]
    [/#if]

    [@Volume "couchdb" "/usr/local/var/lib/couchdb" "/codeontap/couchdb" /]
    
    [@Policy credentialsDecryptPermission() /]

    [#break]

