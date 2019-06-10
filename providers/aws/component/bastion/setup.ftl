[#ftl]
[#macro aws_bastion_cf_segment occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]

    [#local bastionRoleId = resources["role"].Id ]
    [#local bastionEIPId = resources["eip"].Id ]
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
            [@cfException listMode "Network could not be found" networkLink /]
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

    [#local processorProfile = (getProcessor(occurrence, "SSH")?has_content)?then(
                                    getProcessor(occurrence, "SSH"),
                                    getProcessor(occurrence, BASTION_COMPONENT_TYPE)
                                )]

    [#local processorProfile += {
                "MaxCount" : 2,
                "MinCount" : sshActive?then(1,0),
                "DesiredCount" : sshActive?then(1,0)
    }]

    [#local configSets =
            getInitConfigDirectories() +
            getInitConfigBootstrap(occurrence)]

    [#local fragment = getOccurrenceFragmentBase(occurrence) ]

    [#local contextLinks = getLinkTargets(occurrence, links) ]
    [#assign _context =
        {
            "Id" : fragment,
            "Name" : fragment,
            "Instance" : core.Instance.Id,
            "Version" : core.Version.Id,
            "DefaultEnvironment" : defaultEnvironment(occurrence, contextLinks),
            "Environment" : {},
            "Links" : contextLinks,
            "DefaultCoreVariables" : true,
            "DefaultEnvironmentVariables" : true,
            "DefaultLinkVariables" : true,
            "Policy" : standardPolicies(occurrence),
            "ManagedPolicy" : [],
            "Files" : {},
            "Directories" : {}
        }
    ]

    [#-- Add in fragment specifics including override of defaults --]
    [#assign fragmentListMode = "model"]
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
                mode=listMode
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
                    mode=listMode
                    id=bastionEIPId
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
                mode=listMode
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
                mode=listMode
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
                mode=listMode
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
                mode=listMode
                id=bastionInstanceProfileId
                type="AWS::IAM::InstanceProfile"
                properties=
                    {
                        "Path" : "/",
                        "Roles" : [ getReference(bastionRoleId) ]
                    }
                outputs={}
            /]

            [#local asgTags =
                getOccurrenceCoreTags(
                    occurrence,
                    bastionAutoScaleGroupName
                    "",
                    true)]

            [@createEc2AutoScaleGroup
                mode=listMode
                id=bastionAutoScaleGroupId
                tier=core.Tier
                configSetName=configSetName
                configSets=configSets
                launchConfigId=bastionLaunchConfigId
                processorProfile=processorProfile
                autoScalingConfig=solution.AutoScaling
                multiAZ=multiAZ
                tags=asgTags
                networkResources=networkResources
            /]

            [@createEC2LaunchConfig
                mode=listMode
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
            /]
        [/#if]
    [/#if]
[/#macro]