[#ftl]

[#-- Shared Component --]
[#-- The Shared component is used to define common component macros which are shared across all components --]
[#-- Each component can replace the shared component macros but defining a macro which is more specific then the shared one --]

[#-- Default build blueprint --]
[#macro shared_buildblueprint_generationcontract occurrence ]
    [@addDefaultGenerationContract subsets=[ "config" ] /]
[/#macro]

[#macro shared_buildblueprint_config occurrence ]
    [@addToDefaultJsonOutput
        content={
            "Occurrence" : occurrence
        }
    /]
[/#macro]

[#-- Default Occurrence State --]
[#macro shared_occurrences_generationcontract occurrence ]
    [@addDefaultGenerationContract subsets=[ "state" ] /]
[/#macro]

[#macro shared_occurrences_state occurrence ]
    [#local allOccurrences = asFlattenedArray( [ occurrence, occurrence.Occurrences![] ], true )]
    [#-- Only include enabled suboccurrences --]
    [#list allOccurrences?filter(x -> x.Configuration.Solution.Enabled) as occurrence ]
        [@stateEntry
            type="Occurrences"
            id=occurrence.Core.TypedFullName
            state=removeObjectAttributes(occurrence, "Occurrences")
        /]
    [/#list]
[/#macro]

[#-- Default management contract --]
[#macro shared_unitlist_generationcontract occurrence ]
    [@addDefaultGenerationContract subsets=[ "managementcontract" ] /]
[/#macro]

[#macro shared_unitlist_managementcontract occurrence ]

    [#local allOccurrences = asFlattenedArray( [ occurrence, occurrence.Occurrences![] ], true )]
    [#list allOccurrences as occurrence ]

        [@createOccurrenceManagementContractStep
            occurrence=occurrence
        /]
    [/#list]
[/#macro]

[#-- Default testcase --]
[#macro shared_deploymenttest_generationcontract occurrence ]
    [@addDefaultGenerationContract subsets=[ "testcase" ] /]
[/#macro]

[#macro shared_deploymenttest_testcase occurrence ]

    [#local allOccurrences = asFlattenedArray( [ occurrence, occurrence.Occurrences![] ], true )]
    [#list allOccurrences as occurrence ]

        [#if getOccurrenceDeploymentUnit(occurrence) == getCLODeploymentUnit() &&
                getOccurrenceDeploymentGroup(occurrence) == getCLODeploymentGroup() ]

            [#local solution = occurrence.Configuration.Solution ]
            [#local componentType = occurrence.Core.Type ]

            [#local testProfileNames = (solution.Profiles.Testing)![] ]

            [#local testCaseNames = []]
            [#list testProfileNames as testProfileName ]
                [#if ! ((testProfiles[testProfileName])!{})?? ]

                    [@fatal
                        message="Test Profile not Found"
                        context={
                            "Component": occurrence.Core.RawFullName,
                            "Profiles" : testProfileNames,
                            "MissingProfile" : testProfileName
                        }
                    /]
                    [#continue]
                [/#if]

                [#local testProfileDetail = testProfiles[testProfileName] ]
                [#if testProfileDetail["*"]?? ]
                    [#local testCaseNames = combineEntities(
                        testCaseNames, testProfileDetail["*"].TestCases, UNIQUE_COMBINE_BEHAVIOUR) ]
                [/#if]

                [#if testProfileDetail[componentType]??]
                    [#local testCaseNames = combineEntities(
                        testCaseNames, testProfileDetail[componentType].TestCases, UNIQUE_COMBINE_BEHAVIOUR) ]
                [/#if]
            [/#list]

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
                [#if ! testCases[testCaseName]?? ]
                    [@fatal
                        message="Test Case not Found"
                        context={
                            "Component": occurrence.Core.RawFullName,
                            "TestCases" : testCaseNames,
                            "MissingTestCase" : testCaseName
                        }
                    /]
                    [#continue]
                [/#if]

                [#local testCase = testCases[testCaseName] ]

                [#local outputProviders = combineEntities(
                                                getLoaderProviders(),
                                                [ SHARED_PROVIDER],
                                                UNIQUE_COMBINE_BEHAVIOUR
                                            )]

                [#local outputMapping = getGenerationContractStepOutputMappingFromSuffix( outputProviders, testCase.OutputSuffix)]
                [#local filePrefix = getOutputFilePrefix(
                                        "deployment"
                                        getCLODeploymentGroup(),
                                        getCLODeploymentUnit(),
                                        outputMapping["Subset"],
                                        getActiveLayer(ACCOUNT_LAYER_TYPE).Name!"",
                                        getCLOSegmentRegion(),
                                        getCLOAccountRegion(),
                                        "primary"
                                )]

                [#local outputFileName = formatName(filePrefix, outputMapping["OutputSuffix"]) ]

                [#if isPresent(testCase.Tools["cfn-lint"])]
                    [#local tests = mergeObjects(
                        tests,
                        {
                            testCaseFullName : {
                                "cfn_lint" : {} +
                                attributeIfContent(
                                    "ignore_checks",
                                    testCase.Tools["cfn-lint"].IgnoreChecks
                                )
                            }
                        }
                    )]
                [/#if]

                [#if isPresent(testCase.Tools["checkov"])]
                    [#local tests = mergeObjects(
                        tests,
                        {
                            testCaseFullName : {
                                "checkov" : {
                                    "framework" : testCase.Tools["checkov"].Framework
                                } +
                                attributeIfContent(
                                    "skip_checks",
                                    testCase.Tools["checkov"].SkipChecks
                                )
                            }
                        }
                    )]
                [/#if]

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

                [#if tests?has_content ]
                    [#local tests = mergeObjects(
                        tests,
                        {
                            testCaseFullName  : {
                                "filename" : outputFileName
                            }
                        }
                    )]
                [#else]
                    [@fatal
                        message="No tests found for test case"
                        context={
                            "TestCaseFullName" : testCaseFullName,
                            "FileName" : outputFileName
                        }
                    /]
                [/#if]

            [/#list]

            [@addToDefaultJsonOutput
                content=tests
            /]
        [/#if]
    [/#list]
[/#macro]

[#-- Build unit details --]
[#macro shared_imagedetails_generationcontract occurrence ]
    [@addDefaultGenerationContract subsets=["config"] /]
[/#macro]

[#macro shared_imagedetails_config occurrence ]
    [#local allOccurrences = asFlattenedArray( [ occurrence, occurrence.Occurrences![] ], true )]
    [#list allOccurrences as occurrence ]

        [#if (occurrence.Configuration.Settings.Build)?has_content &&
                ((occurrence.Configuration.Settings.Build.BUILD_REFERENCE.Value)!"")?has_content]
            [@addToDefaultJsonOutput
                content={
                    "Images" : combineEntities(
                        (getOutputContent(JSON_DEFAULT_OUTPUT_TYPE)["Images"])![],
                        [
                            {
                                "Occurrence" : occurrence.Core.TypedRawName,
                                "BUILD_UNIT": (occurrence.Configuration.Settings.Build.BUILD_UNIT.Value)!"",
                                "BUILD_REFERENCE": (occurrence.Configuration.Settings.Build.BUILD_REFERENCE.Value)!"",
                                "BUILD_FORMATS": (occurrence.Configuration.Settings.Build.BUILD_FORMATS.Value[0])!"",
                                "APP_REFERENCE": (occurrence.Configuration.Settings.Build.APP_REFERENCE.Value)!"",
                                "BUILD_SOURCE": (occurrence.Configuration.Settings.Build.BUILD_SOURCE.Value)!""
                            }
                        ],
                        APPEND_COMBINE_BEHAVIOUR
                    )
                }
            /]
        [/#if]
    [/#list]
[/#macro]

[#-- Stack Output File --]
[#macro shared_stackoutput_generationcontract occurrence]
    [#if getCLODeploymentUnit() == getOccurrenceDeploymentUnit(occurrence)
            && getCLODeploymentGroup() == getOccurrenceDeploymentGroup(occurrence)]
        [@addDefaultGenerationContract subsets=["stack"] alternatives=[occurrence.Core.RawFullName] contractCleanup=false /]
    [/#if]
[/#macro]

[#macro shared_stackoutput occurrence ]

    [#if getCLODeploymentUnitAlternative() == occurrence.Core.RawFullName ]

        [#local resourceIds = combineEntities(
            getOccurrenceResourceIds(
                occurrence.State.Resources),
                ((occurrence.State.Images)![])?has_content?then(
                    getOccurrenceResourceIds(occurrence.State.Images),
                    []
                )
            )]

        [#list getCommandLineOptions()["StackOutputContent"] as key,value ]
            [#local resourceType = getResourceType(key) ]
            [#local mapping = getOutputMappings(AWS_PROVIDER, resourceType, attributeType)]

            [#list resourceIds as resourceId ]
                [#if mapping?keys?map(
                        x -> formatId(
                            resourceId, (x == REFERENCE_ATTRIBUTE_TYPE)?then(
                                "",
                                x
                            )
                        )
                    )?seq_contains(key)]

                    [@stackOutput
                        key=key
                        value=value
                    /]
                [/#if]
            [/#list]
        [/#list]
    [/#if]
[/#macro]
