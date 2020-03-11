[#ftl]
[#macro aws_datapipeline_cf_generationcontract_application occurrence ]
    [@addDefaultGenerationContract subsets=["prologue", "template", "epilogue", "cli", "config"] /]
[/#macro]

[#macro aws_datapipeline_cf_setup_application occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local settings = occurrence.Configuration.Settings]
    [#local resources = occurrence.State.Resources ]
    [#local attributes = occurrence.State.Attributes ]

    [#local pipelineId = resources["dataPipeline"].Id]
    [#local pipelineName = resources["dataPipeline"].Name]
    [#local pipelineRoleId = resources["pipelineRole"].Id]
    [#local pipelineRoleName = resources["pipelineRole"].Name]
    [#local resourceRoleId = resources["resourceRole"].Id]
    [#local resourceRoleName = resources["resourceRole"].Name]
    [#local resourceInstanceProfileId = resources["resourceInstanceProfile"].Id]
    [#local resourceInstanceProfileName = resources["resourceInstanceProfile"].Name]

    [#local securityGroupId = resources["securityGroup"].Id]
    [#local securityGroupName = resources["securityGroup"].Name]

    [#local ec2ProcessorProfile = getProcessor(occurrence, "EC2")]
    [#local emrProcessorProfile = getProcessor(occurrence, "EMR")]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "OpsData", "AppData", "Encryption", "SSHKey" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]
    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]
    [#local sshKeyPairId = baselineComponentIds["SSHKey"]!"COTFatal: sshKeyPairId not found" ]

    [#local pipelineCreateCommand = "createPipeline"]

    [#local networkLink = getOccurrenceNetwork(occurrence).Link!{} ]

    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@fatal message="Network could not be found" context=networkLink /]
        [#return]
    [/#if]

    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#local networkResources = networkLinkTarget.State.Resources ]

    [#local vpcId = networkResources["vpc"].Id ]

    [#local parameterValues = {
            "_AWS_REGION" : regionId,
            "_AVAILABILITY_ZONE" : zones[0].AWSZone,
            "_VPC_ID" : getExistingReference(vpcId),
            "_SUBNET_ID" : getSubnets(core.Tier, networkResources)[0],
            "_SSH_KEY_PAIR" : getExistingReference(sshKeyPairId, NAME_ATTRIBUTE_TYPE),
            "_INSTANCE_TYPE_EC2" : ec2ProcessorProfile.Processor,
            "_INSTANCE_IMAGE_EC2" : regionObject.AMIs.Centos.EC2,
            "_INSTANCE_TYPE_EMR" : emrProcessorProfile.Processor,
            "_INSTANCE_COUNT_EMR_CORE" : emrProcessorProfile.DesiredCorePerZone?c,
            "_INSTANCE_COUNT_EMR_TASK" : emrProcessorProfile.DesiredCorePerZone?c,
            "_PIPELINE_LOG_URI" : "s3://" + operationsBucket +
                                            formatAbsolutePath(
                                                "datapipeline",
                                                core.FullName,
                                                "logs"),
            "_PIPELINE_CODE_URI" :  "s3://" + operationsBucket +
                                            formatAbsolutePath(
                                                getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                                                "pipeline"
                                            ),
            "_ROLE_PIPELINE_NAME" : pipelineRoleName,
            "_ROLE_RESOURCE_NAME" : resourceRoleName
    }]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#-- Add in container specifics including override of defaults --]
    [#-- Allows for explicit policy or managed ARN's to be assigned to the user --]
    [#local contextLinks = getLinkTargets(occurrence) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks, baselineLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "BaselineLinks" : baselineLinks,
            "Policy" : standardPolicies(occurrence, baselineComponentIds),
            "DefaultCoreVariables" : true,
            "DefaultEnvironmentVariables" : true,
            "DefaultLinkVariables" : true,
            "DefaultBaselineVariables" : true
        }
    ]

    [#if solution.Fragment?has_content ]
        [#local fragmentId = formatFragmentId(_context)]
        [#include fragmentList?ensure_starts_with("/")]
    [/#if]

    [#assign _context += getFinalEnvironment(occurrence, _context ) ]
    [#local parameterValues += _context.Environment ]

    [#local myParameterValues = {}]
    [#list parameterValues as key,value ]
        [#local myParameterValues +=
            {
                key?ensure_starts_with("my") : value
            }]
    [/#list]

    [#if deploymentSubsetRequired("config", false)]
        [@addToDefaultJsonOutput content={ "values" : myParameterValues } /]
    [/#if]

    [#if deploymentSubsetRequired("iam", true)  ]

        [#-- Create a role under which the function will run and attach required policies --]
        [#-- The role is mandatory though there may be no policies attached to it --]
        [#if isPartOfCurrentDeploymentUnit(pipelineRoleId) ]
            [@createRole
                id=pipelineRoleId
                name=pipelineRoleName
                trustedServices=[
                    "elasticmapreduce.amazonaws.com",
                    "datapipeline.amazonaws.com"
                ]
                managedArns=["arn:aws:iam::aws:policy/service-role/AWSDataPipelineRole"]
            /]
        [/#if]

        [#if isPartOfCurrentDeploymentUnit(resourceRoleId) ]
            [@createRole
                id=resourceRoleId
                name=resourceRoleName
                trustedServices=[
                    "ec2.amazonaws.com"
                ]
                managedArns=["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforDataPipelineRole"]
            /]

            [#if _context.Policy?has_content]
                [#local policyId = formatDependentPolicyId(pipelineId)]
                [@createPolicy
                    id=policyId
                    name=_context.Name
                    statements=_context.Policy
                    roles=resourceRoleId
                /]
            [/#if]

            [#local linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

            [#if linkPolicies?has_content]
                [#local policyId = formatDependentPolicyId(pipelineId, "links")]
                [@createPolicy
                    id=policyId
                    name="links"
                    statements=linkPolicies
                    roles=resourceRoleId
                /]
            [/#if]

        [/#if]

    [/#if]

    [#if deploymentSubsetRequired(DATAPIPELINE_COMPONENT_TYPE, true)]


        [@cfResource
                id=resourceInstanceProfileId
                type="AWS::IAM::InstanceProfile"
                properties=
                    {
                        "Path" : "/",
                        "Roles" : [ getReference(resourceRoleId) ],
                        "InstanceProfileName" : resourceInstanceProfileName
                    }
                outputs={}
            /]

        [@createSecurityGroup
            id=securityGroupId
            name=securityGroupName
            occurrence=occurrence
            vpcId=vpcId
        /]

        [@createSecurityGroupIngress
            id=formatDependentSecurityGroupIngressId(
                securityGroupId,
                "local")
            port="any"
            cidr=securityGroupId
            groupId=securityGroupId /]

    [/#if]

    [#if deploymentSubsetRequired("cli", false)]

        [#local coreTags = getOccurrenceCoreTags(
                    occurrence,
                    pipelineName,
                    "",
                    false,
                    false,
                    10) ]

        [#local cliTags = [] ]
        [#-- datapiplines only allow 10 tags --]
        [#list coreTags as tag ]
            [#local cliTags += [
                {
                "key" : tag.Key,
                "value" : tag.Value
            } ] ]
        [/#list]

        [#local pipelineCreateCliConfig = {
            "name" : pipelineName,
            "uniqueId" : pipelineId,
            "tags" : cliTags
        }]

        [@addCliToDefaultJsonOutput
            id=pipelineId
            command=pipelineCreateCommand
            content=pipelineCreateCliConfig
        /]
    [/#if]

    [#if deploymentSubsetRequired("prologue", false)]
        [#-- Copy any asFiles needed by the task --]
        [#local asFiles = getAsFileSettings(settings.Product) ]
        [#if asFiles?has_content]
            [@debug message="Asfiles" context=asFiles enabled=false /]
            [@addToDefaultBashScriptOutput
                content=
                    findAsFilesScript("filesToSync", asFiles) +
                    syncFilesToBucketScript(
                        "filesToSync",
                        regionId,
                        operationsBucket,
                        getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX")
                    ) /]
        [/#if]
    [/#if]

    [#if deploymentSubsetRequired("epilogue", false) ]
        [@addToDefaultBashScriptOutput
            content=
                getBuildScript(
                    "pipelineFiles",
                    regionId,
                    "pipeline",
                    productName,
                    occurrence,
                    "pipeline.zip"
                ) +
                syncFilesToBucketScript(
                    "pipelineFiles",
                    regionId,
                    operationsBucket,
                    formatRelativePath(
                        getOccurrenceSettingValue(occurrence, "SETTINGS_PREFIX"),
                        "pipeline"
                    )
                ) +
                getLocalFileScript(
                    "configFiles",
                    "$\{CONFIG}",
                    "config.json"
                ) +
                [
                    "case $\{STACK_OPERATION} in",
                    "  create|update)",
                    "       mkdir \"$\{tmpdir}/pipeline\" ",
                    "       unzip \"$\{tmpdir}/pipeline.zip\" -d \"$\{tmpdir}/pipeline\" ",
                    "       # Get cli config file",
                    "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?",
                    "       # Create Data pipeline",
                    "       info \"Applying cli level configurtion\""
                    "       pipelineId=\"$(create_data_pipeline" +
                    "       \"" + region + "\" " +
                    "       \"$\{tmpdir}/cli-" +
                                pipelineId + "-" + pipelineCreateCommand + ".json\")\"",
                    "       # Add Pipeline Definition" ,
                    "       info \"Updating pipeline definition\"",
                    "       update_data_pipeline" +
                    "       \"" + region + "\" " +
                    "       \"$\{pipelineId}\" " +
                    "       \"$\{tmpdir}/pipeline/pipeline-definition.json\" " +
                    "       \"$\{tmpdir}/pipeline/pipeline-parameters.json\" " +
                    "       \"$\{tmpdir}/config.json\" " +
                    "       \"$\{STACK_NAME}\" " +
                    "       \"" + securityGroupId + "\" || return $?"
                ] +
                pseudoStackOutputScript(
                    "Data Pipeline",
                    {
                        pipelineId : "$\{pipelineId}"
                    },
                    "creds-system"
                ) +
                [
                    "   ;;",
                    "   esac"
                ]
        /]
    [/#if]
[/#macro]
