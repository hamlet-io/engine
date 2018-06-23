[#case "codeontap"]
    [#assign settings = context.DefaultEnvironment]

    [@Attributes image="gen3-jenkins-slave" /]
    
    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]

    [#-- Validate that the appropriate settings have been provided for the container to work --]
    [#if settings["CODEONTAPVOLUME"]?has_content ]
        [@Volume "codeontap" "/var/opt/codeontap/" settings["CODEONTAPVOLUME"] /]
    [/#if]  

    [@Policy
        globalAdministratorAccess()
    /]

    [#break]