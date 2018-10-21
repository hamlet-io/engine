[#if deploymentUnit?contains("console") || (allDeploymentUnits!false) ]

    [#assign consoleLgId = formatLogGroupId( "console" )]
    [#assign consoleLgName = formatAbsolutePath("ssm", "session-trace" )]
    [#assign consoleRoleId = formatAccountRoleId( "console" )]

    [#assign consoleSSMDocumentName = "SSM-SessionManagerRunShell"]
    [#assign consoleSSMDocumentVersion = "\\$LATEST"]

    [#assign consoleCliCommand = "setSSMSessionPreferences" ]
    [#assign consoleResourceId = "ssmPreferences" ]
    
    [#if deploymentSubsetRequired("iam", true) &&
            isPartOfCurrentDeploymentUnit(consoleRoleId)]
        [@createRole
            mode=listMode
            id=consoleRoleId
            trustedServices=["ssm.amazonaws.com" ]
            policies=
                [
                    getPolicyDocument(
                        cwLogsProducePermission(consoleLgName),
                        "basic")
                ]
        /]
    [/#if]

    [#if deploymentSubsetRequired("lg", true) && 
            isPartOfCurrentDeploymentUnit(consoleLgId)]
        [@createLogGroup
            mode=listMode
            id=consoleLgId
            name=consoleLgName /]
    [/#if]



    [#-- Need to run the unit twice or use an IAM unit so the role can be included in the CLI --]
    [#if deploymentSubsetRequired("cli", false) ]

        [@cfCli
            mode=listMode
            id=consoleResourceId
            command=consoleCliCommand
            content=
                {
                    "schemaVersion": "1.0",
                    "description": "Document to hold regional settings for Session Manager",
                    "sessionType": "Standard_Stream",
                    "inputs": {
                        "cloudWatchLogGroupName": consoleLgName
                    }
                }
        /]
    [/#if]

    [#if deploymentSubsetRequired("epilogue", false) ]
        [@cfScript
            mode=listMode
            content=
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)",
                    "      # Get cli config file",
                    "      split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?",
                    "      # Apply SSM Session account preferences",
                    "      info \"Applying SSM Session account preferences ...\"",
                    "      #",
                    "      update_ssm_document" +
                    "      \"" + region + "\" " +
                    "      \"" + consoleSSMDocumentName + "\" " +
                    "      \"" + consoleSSMDocumentVersion + "\" " +
                    "      \"$\{tmpdir}/cli-" +
                               consoleResourceId + "-" + consoleCliCommand + ".json\" || return $?"
                    "      ;;",
                    "esac"
                ]
        /]
    [/#if]
[/#if]