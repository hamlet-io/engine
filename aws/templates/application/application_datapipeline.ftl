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
        [#assign resourceRoleId = resources["resourceRole"].Id]

        [#assign securityGroupId = resources["securityGroup"].Id]
        [#assign securityGroupName = resources["securityGroup"].Name]

        [#assign ec2ProcessorProfile = getProcessor(tier, component, "EC2")]
        [#assign emrProcessorProfile = getProcessor(tier, component, "EMR")]

        [#assign pipelineCreateCommand = "createPipeline"]

        [#assign containerId =
            solution.Container?has_content?then(
                solution.Container,
                getComponentId(component)
            ) ]

        [#assign parameterValues = {
            "_REGION" : regionId,
            "_SUBNET_ID" : getSubnets(tier)[0],
            "_SECURITY_GROUP_ID" : getExistingReference(securityGroupId),
            "_SSH_KEY_PAIR" : getExistingReference(formatEC2KeyPairId(), NAME_ATTRIBUTE_TYPE),
            "_INSTANCE_TYPE_EC2" : ec2ProcessorProfile.Processor,
            "_INSTANCE_TYPE_EMR" : emrProcessorProfile.Processor,
            "_INSTANCE_COUNT_EMR_CORE" : emrProcessorProfile.DesiredCorePerZone,
            "_INSTANCE_COUNT_EMR_TASK" : emrProcessorProfile.DesiredCorePerZone,
            "_PIPELINE_LOG_URI" : "s3://" + operationsBucket + "/datapipeline/" + core.Name,
            "_ROLE_PIPELINE_ARN" : getExistingReference(pipelineRoleId, ARN_ATTRIBUTE_TYPE),
            "_ROLE_RESOURCE_ARN" : getExistingReference(resourceRoleId, ARN_ATTRIBUTE_TYPE),
            "_AVAILABILITY_ZONE" : zones[0].AWSZone
        }]
    
        [#-- Add in container specifics including override of defaults --]
        [#-- Allows for explicit policy or managed ARN's to be assigned to the user --]
        [#assign contextLinks = getLinkTargets(occurrence) ]
        [#assign context =
            {
                "Id" : containerId,
                "Name" : containerId,
                "Instance" : core.Instance.Id,
                "Version" : core.Version.Id,
                "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks),
                "Environment" : {},
                "Links" : contextLinks,
                "DefaultCoreVariables" : false,
                "DefaultEnvironmentVariables" : false,
                "DefaultLinkVariables" : false
            }
        ]
        
        [#if solution.Container?has_content ]
            [#assign containerListMode = "model"]
            [#assign containerId = formatContainerFragmentId(occurrence, context)]
            [#include containerList?ensure_starts_with("/")]
        [/#if]

        [#assign parameterValues += getFinalEnvironment(occurrence, context).Environment ]


        [#if deploymentSubsetRequired("iam", true) 
            && isPartOfCurrentDeploymentUnit(pipelineRoleId) 
            && isPartOfCurrentDeploymentUnit(resourceRoleId) ]

            [#-- Create a role under which the function will run and attach required policies --]
            [#-- The role is mandatory though there may be no policies attached to it --]
            [@createRole
                mode=listMode
                id=pipelineRoleId
                trustedServices=[
                    "elasticmapreduce.amazonaws.com",
                    "datapipeline.amazonaws.com"
                ]
                policies=[ getDataPipelineStatement() ]
            /]

            [@createRole
                mode=listMode
                id=resourceRoleId
                trustedServices=[
                    "ec2.amazonaws.com"  
                ]
                policies=[ getDataPipelineResourceStatement() ]
            /]

            [#if context.Policy?has_content]
                [#assign policyId = formatDependentPolicyId(pipelineId)]
                [@createPolicy
                    mode=listMode
                    id=policyId
                    name=context.Name
                    statements=context.Policy
                    roles=resourceRoleId
                /]
            [/#if]

            [#assign linkPolicies = getLinkTargetsOutboundRoles(context.Links) ]

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

        [#if deploymentSubsetRequired("cli", false)]
            
            [#assign pipelineCreateCliConfig = {
                "name" : pipelineName,
                "uniqueId" : pipelineId,
                "tags" : getCfTemplateCoreTags(
                        pipelineName,
                        tier,
                        component)
            }]

            [@cfCli 
                mode=listMode
                id=pipelineId
                command=pipelineCreateCommand
                content=pipelineCreateCliConfig
            /]
        [/#if]

        [#if deploymentSubsetRequired("config", false)]
            [@cfConfig
                mode=listMode
                content=parameterValues
            /]
        [/#if]

        [#if deploymentSubsetRequired(DATAPIPELINE_COMPONENT_TYPE, true) ]
            [@createSecurityGroup
                mode=listMode
                id=securityGroupId
                name=securityGroupName
                tier=tier
                component=component 
            /]

            [@createSecurityGroupIngress
                mode=listMode
                id=formatDependentSecurityGroupIngressId(
                    securityGroupId,
                    "local")
                port=-1
                cidr=securityGroupId
                groupId=securityGroupId /]
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

                [@cfScript
                    mode=listMode
                    content=
                        getBuildScript(
                            "pipelineFiles",
                            regionId,
                            "scripts",
                            productName,
                            occurrence,
                            "scripts.zip"
                        ) +
                        getBuildScript(
                            "pipelineFiles",
                            regionId,
                            "scripts",
                            productName,
                            occurrence,
                            "parameters.json"
                        ) +
                        getLocalFileScript(
                            "configFiles",
                            "$\{CONFIG}",
                            "config.json"
                        )
                /]
            
            [/#if]

            [#if deploymentSubsetRequired("epilogue", false) ]
                [@cfScript
                    mode=listMode
                    content= 
                        [
                            "case $\{STACK_OPERATION} in",
                            "  create|update)",
                            "       # Get cli config file",
                            "       split_cli_file \"$\{CLI}\" \"$\{tmpdir}\" || return $?", 
                            "       # Apply CLI level updates to ELB listener",
                            "       info \"Applying cli level configurtion\""
                            "       pipelineId=\"$(create_data_pipeline" +
                            "       \"" + region + "\" " + 
                            "       \"$\{tmpdir}/cli-" + 
                                        pipelineId + "-" + pipelineCreateCommand + ".json\")\""
                            "       pseudo_stack_file=\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")-pseudo-stack.json\" ",
                            "       create_pseudo_stack" + " " +
                            "       \"Data Pipeline\"" + " " +
                            "       \"$\{pseudo_stack_file}\"" + " " +
                            "       \"" + pipelineId + "\" \"$\{pipelineId}\" || return $?"
                            "   ;;",
                            "   esac"
                        ]
                    
                /]
            [/#if]
    
    [/#list]
[/#if]