[#ftl]

[#-- Deployment frameworks --]
[#assign DEFAULT_DEPLOYMENT_FRAMEWORK = "default"]


[#-- Default testcase --]
[#macro shared_testcase occurrence ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local componentType = occurrence.Core.Type ]

    [#local testProfileNames = (solution.Profiles.Testing)![] ]

    [#local testCaseNames = []]
    [#list testProfileNames as testProfileName ]
        [#if (testProfiles[testProfileName]!{})?? ]
            [#local testProfileDetail = testProfiles[testProfileName] ]

            [#if testProfileDetail["*"]?? ]
                [#local testCaseNames += testProfileDetail["*"].TestCases ]
            [/#if]

            [#if testProfileDetail[componentType]??]
                [#local testCaseNames += testProfileDetail[componentType].TestCases ]
            [/#if]
        [/#if]
    [/#list]

    [#local testCaseNames = getUniqueArrayElements(testCaseNames) ]

    [#local tests = {} ]
    [#list testCaseNames as testCaseName ]
        [#local testCaseFullName = concatenate(
                                        [
                                            getOccurrenceDeploymentUnit(occurrence),
                                            (occurrence.Core.ShortTypedName),
                                            testCaseName
                                        ],
                                        "_"
                                    )?replace("-", "_")]
        [#if testCases[testCaseName]?? ]
            [#local testCase = testCases[testCaseName] ]

            [#local tests = mergeObjects(
                tests,
                {
                    testCaseFullName  : {
                        "filename" : concatenate(
                                        [
                                            commandLineOptions.Deployment.Output.Prefix,
                                            testCase.OutputSuffix
                                        ],
                                        ""
                                    ),
                        "cfn_lint" : testCase.Tools.CFNLint,
                        "cfn_nag"  : testCase.Tools.CFNNag
                    }
                }
            )]

            [#list (testCase.Structural.JSON.Match)!{} as id,matchTest ]
                [#local tests = combineEntities(tests,
                    {
                        testCaseFullName : {
                            "json_structure" : {
                                "match" : [
                                    {
                                        "path" : matchTest.Path,
                                        "value" : matchTest.Value
                                    }
                                ]
                            }
                        }
                    },
                    APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]

            [#list (testCase.Structural.JSON.Length)!{} as id,legnthTest ]
                [#local tests = combineEntities(tests,
                    {
                        testCaseFullName : {
                            "json_structure"  : {
                                "length" : [
                                        {
                                            "path" : legnthTest.Path,
                                            "value" : legnthTest.Count
                                        }
                                ]
                            }
                        }
                    },
                    APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]

            [#if testCase.Structural.JSON.Exists?has_content ]
                [#local existPaths = []]
                [#list testCase.Structural.JSON.Exists as path ]
                    [#local existPaths += [
                            {
                                "path" : path
                            }
                        ]
                    ]
                [/#list]
                [#local tests = mergeObjects(
                    tests,
                    {
                        testCaseFullName  : {
                            "json_structure" : {
                                "exists" : existPaths
                            }
                        }
                    }
                )]
            [/#if]

            [#if testCase.Structural.JSON.NotEmpty?has_content ]
                [#local notEmtpyPaths = []]
                [#list testCase.Structural.JSON.NotEmpty as path ]
                    [#local notEmtpyPaths += [
                            {
                                "path" : path
                            }
                        ]
                    ]
                [/#list]
                [#local tests = mergeObjects(
                    tests,
                    {
                        testCaseFullName  : {
                            "json_structure" : {
                                "not_empty" : notEmtpyPaths
                            }
                        }
                    }
                )]
            [/#if]

            [#list (testCase.Structural.CFN.Resource)!{} as id,CFNResourceTest ]
                [#local tests = combineEntities(tests,
                    {
                        testCaseFullName : {
                            "cfn_structure"  : {
                                "resource" : [
                                    {
                                        "id" : CFNResourceTest.Name,
                                        "type" : CFNResourceTest.Type
                                    }
                                ]
                            }
                        }
                    },
                    APPEND_COMBINE_BEHAVIOUR
                )]
            [/#list]

            [#if testCase.Structural.CFN.Output?has_content ]
                [#local cfnOutputPaths = []]
                [#list testCase.Structural.CFN.Output as path ]
                    [#local cfnOutputPaths += [
                            {
                                "id" : path
                            }
                        ]
                    ]
                [/#list]
                [#local tests = mergeObjects(
                    tests,
                    {
                        testCaseFullName  : {
                            "cfn_structure" : {
                                "output" : cfnOutputPaths
                            }
                        }
                    }
                )]
            [/#if]
        [/#if]
    [/#list]

    [@addToDefaultJsonOutput
        content=tests
    /]
[/#macro]


[#-- Management Contracts --]
[#macro createManagementContractStage deploymentUnit deploymentPriority deploymentGroup deploymentMode=getDeploymentMode() ]

    [#local deploymentModeDetails = getDeploymentModeDetails(deploymentMode)]
    [#local deploymentGroupDetails = getDeploymentGroupDetails(deploymentGroup) ]

    [#local executionPolicy = deploymentModeDetails.ExecutionPolicy ]

    [#local mandatoryContract = false]
    [#switch executionPolicy ]
        [#case "Required" ]
            [#local mandatoryContract = true ]
            [#break]

        [#case "Optional" ]
            [#local mandatoryContract = false ]
            [#break]
    [/#switch]

    [#if deploymentGroupDetails?has_content ]

        [#local stageId = deploymentGroupDetails.Id ]
        [#local stagePriority = 0 ]
        [#local stageEnabled = false ]

        [#-- Determine the group order --]
        [#switch deploymentModeDetails.Membership ]
            [#case "explicit" ]
                [#local groupList = (deploymentModeDetails.Explicit.Groups)![] ]
                [#if groupList?seq_contains(deploymentGroupDetails.Name) ]
                    [#local stageEnabled = true]
                    [#local stagePriority = groupList?seq_index_of(deploymentGroupDetails.Name) + 1 ]
                [/#if]
                [#break]

            [#case "priority" ]
                [#if deploymentGroupDetails.Name?matches( deploymentModeDetails.Priority.GroupFilter ) ]
                    [#local stageEnabled = true]
                    [#local stagePriority = valueIfTrue(
                                                deploymentGroupDetails.Priority,
                                                (deploymentModeDetails.Priority.Order == "LowestFirst"),
                                                1000 - deploymentGroupDetails.Priority
                                            )]
                [/#if]
                [#break]

        [/#switch]

        [#if stageEnabled ]
            [@contractStage
                id=stageId
                executionMode=CONTRACT_EXECUTION_MODE_PRIORITY
                priority=stagePriority
                mandatory=mandatoryContract
            /]

            [#local stepPriority = valueIfTrue(
                deploymentPriority,
                (deploymentModeDetails.Priority.Order == "LowestFirst"),
                1000 - deploymentPriority
            )]]

            [@contractStep
                id=formatId(stageId, deploymentUnit)
                stageId=stageId
                taskType=MANAGE_DEPLOYMENT_TASK_TYPE
                priority=stepPriority
                mandatory=mandatoryContract
                parameters=
                    {
                        "DeploymentUnit" : deploymentUnit,
                        "DeploymentGroup" : deploymentGroupDetails.Name
                    }
            /]
        [/#if]
    [/#if]
[/#macro]

[#macro createOccurrenceManagementContractStep occurrence ]
    [#local solution = occurrence.Configuration.Solution ]
    [#if ((solution["deployment:Group"])!"")?has_content ]
        [@createManagementContractStage
            deploymentUnit=getOccurrenceDeploymentUnit(occurrence)
            deploymentGroup=solution["deployment:Group"]
            deploymentPriority=solution["deployment:Priority"]
        /]
    [/#if]
[/#macro]

[#macro createResourceSetManagementContractStep deploymentGroupDetails ]
    [#list (deploymentGroupDetails.ResourceSets)?values as resourceSet ]
        [@createManagementContractStage
            deploymentUnit=resourceSet["deployment:Unit"]
            deploymentGroup=deploymentGroupDetails.Name
            deploymentPriority=resourceSet["deployment:Priority"]
        /]
    [/#list]
[/#macro]

[#macro shared_managementcontract occurrence ]

    [@createOccurrenceManagementContractStep
        occurrence=occurrence
    /]

    [#list (occurrence.Occurrences)![] as subOccurrence ]
        [@createOccurrenceManagementContractStep
            occurrence=subOccurrence
        /]
    [/#list]

    [#if getOutputContent("stages")?has_content ]
        [#list getOutputContent("stages")?keys as deploymentGroup ]
            [@createResourceSetManagementContractStep
                deploymentGroupDetails=getDeploymentGroupDetails(deploymentGroup)
            /]
        [/#list]
    [/#if]
[/#macro]
