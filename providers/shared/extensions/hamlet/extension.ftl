[#ftl]

[@addExtension
    id="hamlet"
    aliases=[
        "_hamlet"
    ]
    description=[
        "Hamlet agent task for use with CI/CD Pipelines"
    ]
    supportedTypes=[
        ECS_SERVICE_COMPONENT_TYPE,
        ECS_TASK_COMPONENT_TYPE,
        CONTAINERSERVICE_COMPONENT_TYPE,
        CONTAINERTASK_COMPONENT_TYPE
    ]
/]


[#macro shared_extension_hamlet_deployment_setup occurrence ]

    [#local env = _context.DefaultEnvironment]
    [#local awsAgentAutomationRole = env["HAMLET_AWS_AUTH_ROLE"]!"HamletFatal: Missing default assume role for hamlet" ]

    [@DefaultLinkVariables          enabled=false /]
    [@DefaultCoreVariables          enabled=false /]
    [@DefaultEnvironmentVariables   enabled=false /]
    [@DefaultBaselineVariables      enabled=false /]
    [@DefaultComponentVariables     enabled=false /]

    [@Settings {
        "HAMLET_AWS_AUTH_SOURCE" : env["HAMLET_AWS_AUTH_SOURCE"]!"INSTANCE:ECS",
        "HAMLET_AWS_AUTH_ROLE"   : awsAgentAutomationRole,
        "HAMLET_AWS_AUTH_USER"   : env["HAMLET_AWS_AUTH_USER"]!"",

        "HAMLET_AZ_AUTH_METHOD"  : env["HAMLET_AZ_AUTH_METHOD"]!"service",

        "STARTUP_COMMANDS"       : (env["STARTUP_COMMANDS"])!""
    }/]

    [#-- Propeties volumes provide a read only share between the jenkins server and the agents --]
    [#-- The mount can either be an efs share or a host mount which must be available to all containers --]
    [#if ((_context["Links"]["efs_properties"])!{})?has_content ]
        [@Volume
            name="codeontap_properties"
            containerPath="/var/opt/codeontap/"
            volumeLinkId="efs_properties"
        /]

        [@Volume
            name="properties"
            containerPath="/var/opt/properties/"
            volumeLinkId="efs_properties"
        /]

    [#else]

        [#if env["CODEONTAPVOLUME"]?has_content ]
            [@Volume
                name="codeontap"
                containerPath="/var/opt/codeontap/"
                hostPath=env["CODEONTAPVOLUME"]
            /]
        [#elseif env["PROPERTIESVOLUME"]?has_content ]
            [@Volume
                name="codeontap"
                containerPath="/var/opt/codeontap/"
                hostPath=env["PROPERTIESVOLUME"]
            /]
        [/#if]

        [#if env["PROPERTIESVOLUME"]?has_content ]
            [@Volume
                name="properties"
                containerPath=(env["PROPERTIES_DIR"])!"/var/opt/properties/"
                hostPath=env["PROPERTIESVOLUME"]
            /]
        [/#if]

    [/#if]

    [#if env["AWS_AUTOMATION_POLICIES"]?has_content ]
        [@ManagedPolicy env["AWS_AUTOMATION_POLICIES"]?split(",") /]
    [/#if]

    [#if (env["AWS_AUTOMATION_ACCOUNTS"]!"")?has_content ]
        [#local automationAccounts = asArray( (env["AWS_AUTOMATION_ACCOUNTS"]!"")?eval_json ) ]

        [#local automationAccountRoles = []]
        [#list automationAccounts as automationAccount ]
            [#local automationAccountRoles += [
                                                    formatGlobalArn(
                                                        "iam",
                                                        formatRelativePath("role", awsAgentAutomationRole),
                                                        automationAccount
                                                    )
                                                ]]
        [/#list]

        [@Policy
            [
                getPolicyStatement( ["sts:AssumeRole"], automationAccountRoles)
            ]
        /]
    [/#if]

    [#-- DockerInDockerAgent --]
    [#-- In this model a sidercar container running in priviledged mode offers the docker service for the agent to use --]
    [#-- We also use a dockerStage directory to share local bind mounts between the agent and the dind host --]
    [#-- This agent requires the dind side car and enabling privledged mode in a container which is considered a secrity risk --]
    [#-- This requires the ecs host to have the ebs VolumeDriver Enabled --]
    [#local dockerStageDir = env["DOCKER_STAGE_DIR"]!"/home/jenkins"  ]
    [#local dindHost = env["DIND_DOCKER_HOST_URL"]!"tcp://dind:2376"  ]
    [#local dindEnabled = (env["DIND_ENABLED"]!"true")?boolean]

    [#if dindEnabled]

        [@Settings
            {
                "DOCKER_HOST"       : dindHost,
                "DOCKER_TLS_VERIFY" : "true",
                "DOCKER_CERT_PATH"  : "/docker/certs/client",
                "DOCKER_STAGE_DIR"  : dockerStageDir
            }
        /]

        [@Volume
            name="dockerStage"
            containerPath=dockerStageDir
        /]

        [@Volume
            name="dind_certs_client"
            containerPath="/docker/certs/client"
            readOnly=true
        /]
    [/#if]

[/#macro]
