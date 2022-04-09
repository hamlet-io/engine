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
    [#list allOccurrences as occurrence ]

        [#local occurrencestate = {}]
        [#list occurrence as k, v ]
            [#if k != "Occurrences" ]
                [#local occurrencestate = mergeObjects(occurrencestate, { k : v }) ]
            [/#if]
        [/#list]

        [@stateEntry
            type="Occurrences"
            id=occurrence.Core.TypedFullName
            state=occurrencestate
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
