[#-- Data Pipeline --]

[#if componentType == DATAPIPELINE_COMPONENT_TYPE]
    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign settings = occurrence.Configuration.Settings]
        [#assign resources = occurrence.State.Resources ]
        [#assign attributes = occurrence.State.Attributes ]

        [#assign pipelineId = resources["dataPipeline"].Id]
        [#assign pipelineName = resources["dataPipeline"].Name]
        [#assign pipelineRoleId = resources["pipelineRole"].Id]
        [#assign pipelineRoleName = resources["pipelineRole"].Name]
        [#assign resourceRoleId = resources["resourceRole"].Id]
        [#assign resourceRoleName = resources["resourceRole"].Name]
        [#assign resourceInstanceProfileId = resources["resourceInstanceProfile"].Id]
        [#assign resourceInstanceProfileName = resources["resourceInstanceProfile"].Name]

        [#assign securityGroupId = resources["securityGroup"].Id]
        [#assign securityGroupName = resources["securityGroup"].Name]

        [#assign ec2ProcessorProfile = getProcessor(occurrence, "EC2")]
        [#assign emrProcessorProfile = getProcessor(occurrence, "EMR")]

        [#assign pipelineCreateCommand = "createPipeline"]

        [#assign networkLink = getOccurrenceNetwork(occurrence).Link!{} ]

        [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

        [#if ! networkLinkTarget?has_content ]
            [@cfException listMode "Network could not be found" networkLink /]
            [#break]
        [/#if]

        [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#assign networkResources = networkLinkTarget.State.Resources ]

        [#assign vpcId = networkResources["vpc"].Id ]

        [#assign parameterValues = {
                "_AWS_REGION" : regionId,
                "_AVAILABILITY_ZONE" : zones[0].AWSZone,
                "_VPC_ID" : getExistingReference(vpcId),
                "_SUBNET_ID" : getSubnets(core.Tier, networkResources)[0],
                "_SSH_KEY_PAIR" : getExistingReference(formatEC2KeyPairId(), NAME_ATTRIBUTE_TYPE),
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

        [#assign fragment = getOccurrenceFragmentBase(occurrence) ]

        [#-- Add in container specifics including override of defaults --]
        [#-- Allows for explicit policy or managed ARN's to be assigned to the user --]
        [#assign contextLinks = getLinkTargets(occurrence) ]
        [#assign _context =
            {
                "Id" : fragment,
                "Name" : fragment,
                "Instance" : core.Instance.Id,
                "Version" : core.Version.Id,
                "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks),
                "Environment" : {},
                "Links" : contextLinks,
                "Policy" : standardPolicies(occurrence),
                "DefaultCoreVariables" : true,
                "DefaultEnvironmentVariables" : true,
                "DefaultLinkVariables" : true
            }
        ]

        [#if solution.Fragment?has_content ]
            [#assign fragmentListMode = "model"]
            [#assign fragmentId = formatFragmentId(_context)]
            [#include fragmentList?ensure_starts_with("/")]
        [/#if]

        [#assign _context += getFinalEnvironment(occurrence, _context) ]
        [#assign parameterValues += _context.Environment ]

        [#assign myParameterValues = {}]
        [#list parameterValues as key,value ]
            [#assign myParameterValues +=
                {
                    key?ensure_starts_with("my") : value
                }]
        [/#list]

        [#if deploymentSubsetRequired("config", false)]
            [@cfConfig
                mode=listMode
                content={
                    "values" : myParameterValues
                }
            /]
        [/#if]

        [#if deploymentSubsetRequired("iam", true)  ]

            [#-- Create a role under which the function will run and attach required policies --]
            [#-- The role is mandatory though there may be no policies attached to it --]
            [#if isPartOfCurrentDeploymentUnit(pipelineRoleId) ]
                [@createRole
                    mode=listMode
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
                    mode=listMode
                    id=resourceRoleId
                    name=resourceRoleName
                    trustedServices=[
                        "ec2.amazonaws.com"
                    ]
                    managedArns=["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforDataPipelineRole"]
                /]

                [#if _context.Policy?has_content]
                    [#assign policyId = formatDependentPolicyId(pipelineId)]
                    [@createPolicy
                        mode=listMode
                        id=policyId
                        name=_context.Name
                        statements=_context.Policy
                        roles=resourceRoleId
                    /]
                [/#if]

                [#assign linkPolicies = getLinkTargetsOutboundRoles(_context.Links) ]

                [#if linkPolicies?has_content]
                    [#assign policyId = formatDependentPolicyId(pipelineId, "links")]
                    [@createPolicy
                        mode=listMode
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
                    mode=listMode
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
                mode=listMode
                id=securityGroupId
                name=securityGroupName
                occurrence=occurrence
                vpcId=vpcId
            /]

            [@createSecurityGroupIngress
                mode=listMode
                id=formatDependentSecurityGroupIngressId(
                    securityGroupId,
                    "local")
                port="any"
                cidr=securityGroupId
                groupId=securityGroupId /]

        [/#if]

        [#if deploymentSubsetRequired("cli", false)]

            [#assign coreTags = getCfTemplateCoreTags(
                        pipelineName,
                        core.Tier,
                        core.Component,
                        "",
                        false,
                        false,
                        10) ]

            [#assign cliTags = [] ]
            [#-- datapiplines only allow 10 tags --]
            [#list coreTags as tag ]
                [#assign cliTags += [
                    {
                    "key" : tag.Key,
                    "value" : tag.Value
                } ] ]
            [/#list]

            [#assign pipelineCreateCliConfig = {
                "name" : pipelineName,
                "uniqueId" : pipelineId,
                "tags" : cliTags
            }]

            [@cfCli
                mode=listMode
                id=pipelineId
                command=pipelineCreateCommand
                content=pipelineCreateCliConfig
            /]
        [/#if]

        [#if deploymentSubsetRequired("prologue", false)]
            [#-- Copy any asFiles needed by the task --]
            [#assign asFiles = getAsFileSettings(settings.Product) ]
            [#if asFiles?has_content]
                [@cfDebug listMode asFiles false /]
                [@cfScript
                    mode=listMode
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
            [@cfScript
                mode=listMode
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

    [/#list]
[/#if]
