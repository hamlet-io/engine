[#ftl]
[#macro aws_bastion_cf_generationcontract_segment occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_bastion_cf_setup_segment occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]

    [#local bastionRoleId = resources["role"].Id ]
    [#local bastionEIPId = resources["eip"].Id ]
    [#local bastionEIPName = resources["eip"].Name ]
    [#local bastionSecurityGroupFromId = resources["securityGroupFrom"].Id]
    [#local bastionSecurityGroupFromName = resources["securityGroupFrom"].Name]
    [#local bastionSecurityGroupToId = resources["securityGroupTo"].Id]
    [#local bastionSecurityGroupToName = resources["securityGroupTo"].Name]
    [#local bastionInstanceProfileId = resources["instanceProfile"].Id]
    [#local bastionAutoScaleGroupId = resources["autoScaleGroup"].Id]
    [#local bastionAutoScaleGroupName = resources["autoScaleGroup"].Name]
    [#local bastionLaunchConfigId = resources["launchConfig"].Id]
    [#local bastionLgId = resources["lg"].Id]
    [#local bastionLgName = resources["lg"].Name]

    [#local bastionOS = solution.OS ]
    [#local bastionType = occurrence.Core.Type]
    [#local configSetName = bastionType]
    [#local sshInVpc = getExistingReference(bastionSecurityGroupFromId, "", "", "vpc")?has_content ]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "OpsData", "AppData", "Encryption", "SSHKey" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]
    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]
    [#local sshKeyPairId = baselineComponentIds["SSHKey"]!"COTFatal: sshKeyPairId not found" ]

    [#switch bastionOS ]
        [#case "linux" ]
            [#local imageId = regionObject.AMIs.Centos.EC2]
            [#break]
    [/#switch]

    [#if deploymentSubsetRequired("bastion", true) ]
        [#local occurrenceNetwork = getOccurrenceNetwork(occurrence) ]
        [#local networkLink = occurrenceNetwork.Link!{} ]
        [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

        [#if ! networkLinkTarget?has_content ]
            [@fatal message="Network could not be found" context=networkLink /]
            [#return]
        [/#if]

        [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#local networkResources = networkLinkTarget.State.Resources ]

        [#local vpcId = networkResources["vpc"].Id ]

        [#local routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : occurrenceNetwork.RouteTable }, false)]
        [#local routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
        [#local publicRouteTable = routeTableConfiguration.Public ]
    [/#if]

    [#local storageProfile = getStorage(occurrence, BASTION_COMPONENT_TYPE)]
    [#local logFileProfile = getLogFileProfile(occurrence, BASTION_COMPONENT_TYPE)]
    [#local bootstrapProfile = getBootstrapProfile(occurrence, BASTION_COMPONENT_TYPE)]

    [#local processorProfile = getProcessor(occurrence, "bastion")]

    [#local processorProfile += {
                "MaxCount" : 2,
                "MinCount" : sshActive?then(1,0),
                "DesiredCount" : sshActive?then(1,0)
    }]

    [#local configSets =
            getInitConfigDirectories() +
            getInitConfigBootstrap(occurrence, operationsBucket, dataBucket)]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#local contextLinks = getLinkTargets(occurrence, links) ]
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
            "DefaultCoreVariables" : true,
            "DefaultEnvironmentVariables" : true,
            "DefaultBaselineVariables" : true,
            "DefaultLinkVariables" : true,
            "Policy" : standardPolicies(occurrence, baselineComponentIds),
            "ManagedPolicy" : [],
            "Files" : {},
            "Directories" : {}
        }
    ]

    [#-- Add in fragment specifics including override of defaults --]
    [#local fragmentId = formatFragmentId(_context)]
    [#include fragmentList?ensure_starts_with("/")]

    [#local environmentVariables = getFinalEnvironment(occurrence, _context).Environment ]

    [#local configSets +=
        getInitConfigEnvFacts(environmentVariables, false) +
        getInitConfigDirsFiles(_context.Files, _context.Directories) ]

    [#if sshEnabled &&
        (
            (bastionType == "bastion") ||
            ((bastionType == "vpc") && sshInVpc)
        )]

        [#if deploymentSubsetRequired("iam", true) &&
                isPartOfCurrentDeploymentUnit(bastionRoleId)]
            [@createRole
                id=bastionRoleId
                trustedServices=["ec2.amazonaws.com" ]
                policies=
                    [
                        getPolicyDocument(
                            ec2IPAddressUpdatePermission() +
                                s3ListPermission(codeBucket) +
                                s3ReadPermission(codeBucket) +
                                cwLogsProducePermission(computeClusterLogGroupName),
                            "basic")
                    ] +
                    arrayIfContent(
                        [getPolicyDocument(_context.Policy, "fragment")],
                        _context.Policy) +
                    consoleOnly?then(
                        [getPolicyDocument(
                            ec2SSMSessionManagerPermission() +
                            ec2SSMAgentUpdatePermission(bastionOS),
                            "ssm")],
                        []
                    )
                managedArns=_context.ManagedPolicy
            /]
        [/#if]

        [#if !consoleOnly ]
            [#if deploymentSubsetRequired("eip", true) &&
                    isPartOfCurrentDeploymentUnit(bastionEIPId)]
                [@createEIP
                    id=bastionEIPId
                    tags=getOccurrenceCoreTags(
                            occurrence,
                            bastionEIPName
                        )
                /]
            [/#if]

            [#local configSets +=
                getInitConfigEIPAllocation(
                    getReference(
                        bastionEIPId,
                        ALLOCATION_ATTRIBUTE_TYPE
                    ))]
        [/#if]

        [#if deploymentSubsetRequired("lg", true) &&
                isPartOfCurrentDeploymentUnit(bastionLgId) ]
            [@createLogGroup
                id=bastionLgId
                name=bastionLgName /]
        [/#if]

        [#local configSets +=
            getInitConfigLogAgent(
                logFileProfile,
                bastionLgName
            )]

        [#if deploymentSubsetRequired("bastion", true)]
            [@createSecurityGroup
                id=bastionSecurityGroupToId
                name=bastionSecurityGroupToName
                occurrence=occurrence
                description="Security Group for inbound SSH to the SSH Proxy"
                ingressRules=
                    [
                        {
                            "Port" : "ssh",
                            "CIDR" :
                                (sshEnabled && !consoleOnly)?then(
                                    getGroupCIDRs(
                                        (segmentObject.SSH.IPAddressGroups)!
                                            (segmentObject.IPAddressGroups)!
                                            (segmentObject.Bastion.IPAddressGroups)![]),
                                    []
                                )
                        }
                    ]
                vpcId=vpcId
            /]

            [@createSecurityGroup
                id=bastionSecurityGroupFromId
                name=bastionSecurityGroupFromName
                tier="all"
                occurrence=occurrence
                description="Security Group for SSH access from the SSH Proxy"
                ingressRules=
                    [
                        {
                            "Port" : "ssh",
                            "CIDR" : [bastionSecurityGroupToId]
                        }
                    ]
                vpcId=vpcId
            /]

            [@cfResource
                id=bastionInstanceProfileId
                type="AWS::IAM::InstanceProfile"
                properties=
                    {
                        "Path" : "/",
                        "Roles" : [ getReference(bastionRoleId) ]
                    }
                outputs={}
            /]

            [@createEc2AutoScaleGroup
                id=bastionAutoScaleGroupId
                tier=core.Tier
                configSetName=configSetName
                configSets=configSets
                launchConfigId=bastionLaunchConfigId
                processorProfile=processorProfile
                autoScalingConfig=solution.AutoScaling
                multiAZ=multiAZ
                tags=getOccurrenceCoreTags(
                        occurrence,
                        bastionAutoScaleGroupName
                        "",
                        true
                    )
                networkResources=networkResources
            /]

            [@createEC2LaunchConfig
                id=bastionLaunchConfigId
                processorProfile=processorProfile
                storageProfile=storageProfile
                securityGroupId=bastionSecurityGroupToId
                instanceProfileId=bastionInstanceProfileId
                resourceId=bastionAutoScaleGroupId
                imageId=imageId
                publicIP=publicRouteTable
                configSet=configSetName
                enableCfnSignal=true
                environmentId=environmentId
                sshFromProxy=[]
                keyPairId=sshKeyPairId
            /]
        [/#if]
    [/#if]
[/#macro]
