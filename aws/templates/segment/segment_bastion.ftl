[#-- BASTION/SSH --]
[#if componentType == BASTION_COMPONENT_TYPE ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core ]
        [#assign solution = occurrence.Configuration.Solution ]
        [#assign resources = occurrence.State.Resources ]

        [#assign bastionRoleId = resources["role"].Id ]
        [#assign bastionEIPId = resources["eip"].Id ]
        [#assign bastionSecurityGroupFromId = resources["securityGroupFrom"].Id]
        [#assign bastionSecurityGroupFromName = resources["securityGroupFrom"].Name]
        [#assign bastionSecurityGroupToId = resources["securityGroupTo"].Id]
        [#assign bastionSecurityGroupToName = resources["securityGroupTo"].Name]
        [#assign bastionInstanceProfileId = resources["instanceProfile"].Id]
        [#assign bastionAutoScaleGroupId = resources["autoScaleGroup"].Id]
        [#assign bastionAutoScaleGroupName = resources["autoScaleGroup"].Name]
        [#assign bastionLaunchConfigId = resources["launchConfig"].Id]
        [#assign bastionLgId = resources["lg"].Id]
        [#assign bastionLgName = resources["lg"].Name]

        [#assign bastionOS = solution.OS ]
        [#assign configSetName = componentType]
        [#assign sshInVpc = getExistingReference(bastionSecurityGroupFromId, "", "", "vpc")?has_content ]

        [#switch bastionOS ]
            [#case "linux" ]
                [#assign imageId = regionObject.AMIs.Centos.EC2]
                [#break]
        [/#switch]
      
        [#assign networkLink = tier.Network.Link!{} ]

        [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]
        [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#assign networkResources = networkLinkTarget.State.Resources ]

        [#assign vpcId = networkResources["vpc"].Id ]

        [#assign routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : tier.Network.RouteTable })]
        [#assign routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
        [#assign publicRouteTable = routeTableConfiguration.Public ]

        [#assign storageProfile = getStorage(tier, component, BASTION_COMPONENT_TYPE)]
        [#assign logFileProfile = getLogFileProfile(tier, component, BASTION_COMPONENT_TYPE)]
        [#assign bootstrapProfile = getBootstrapProfile(tier, component, BASTION_COMPONENT_TYPE)]

        [#assign processorProfile = (getProcessor(tier, component, "SSH")?has_content)?then(
                                        getProcessor(tier, component, "SSH"),
                                        getProcessor(tier, component, BASTION_COMPONENT_TYPE)
                                    )]

        [#assign processorProfile += {
                    "MaxCount" : 2,
                    "MinCount" : sshActive?then(1,0),
                    "DesiredCount" : sshActive?then(1,0)
        }]

        [#assign configSets =
                getInitConfigDirectories() +
                getInitConfigBootstrap(component.Role!"")]
                
        [#assign fragment =
            contentIfContent(solution.Fragment, getComponentId(component)) ]

        [#assign contextLinks = getLinkTargets(occurrence, links) ]
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
        [#assign fragmentId = formatFragmentId(_context)]
        [#assign containerId = fragmentId]
        [#include fragmentList?ensure_starts_with("/")]

        [#assign environmentVariables = getFinalEnvironment(occurrence, _context).Environment ]

        [#assign configSets +=
            getInitConfigEnvFacts(environmentVariables, false) +
            getInitConfigDirsFiles(_context.Files, _context.Directories) ]

        [#if sshEnabled &&
            (
                (componentType == "bastion") ||
                ((componentType == "vpc") && sshInVpc)
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

                [#assign configSets += 
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

            [#assign configSets +=
                getInitConfigLogAgent(
                    logFileProfile,
                    bastionLgName
                )]

            [#if deploymentSubsetRequired("bastion", true)]
                [@createSecurityGroup
                    mode=listMode
                    tier=tier
                    component=component
                    id=bastionSecurityGroupToId
                    name=bastionSecurityGroupToName
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
                    tier="all"
                    component=component
                    id=bastionSecurityGroupFromId
                    name=bastionSecurityGroupFromName
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

                [#assign asgTags =                     
                    getCfTemplateCoreTags(
                        bastionAutoScaleGroupName
                        tier,
                        component,
                        "",
                        true)]

                [@createEc2AutoScaleGroup 
                    mode=listMode
                    id=bastionAutoScaleGroupId
                    tier=tier
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
    [/#list]
[/#if]