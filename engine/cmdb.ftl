[#ftl]

[#--------------------------------------
-- CMDB layered file system functions --
----------------------------------------]

[#function analyseCMDBTenants cmdbCache tenant="" path="/" ]
    [#local tenants={} ]

    [#if
        cmdbCache.Tenants?? &&
        (
            (!tenant?has_content) ||
            (cmdbCache.Tenants[tenant]?has_content)
        ) ]
        [#local tenants = cmdbCache.Tenants]
    [#else]
            [#local tenants = internalAnalyseTenantStructure(path, tenant) ]
    [/#if]

    [#return
        {
            "Tenants" : tenants
        }
    ]
[/#function]

[#function analyseCMDBAccounts cmdbCache tenant account="" ]
    [#local accounts = {} ]

    [#-- Assume tenants up to date in cmdbCache --]
    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]

    [#if tenantStructure?has_content ]
        [#if
            tenantStructure.Accounts?? &&
            (
                (!account?has_content) ||
                (tenantStructure.Accounts[account]?has_content)
            ) ]
            [#local accounts = tenantStructure.Accounts ]
        [#else]
            [#local accounts =
                internalAnalyseAccountStructure(
                    (tenantStructure.Paths.CMDB)!"",
                    account
                )
            ]
        [/#if]
    [/#if]

    [#return
        {
            "Tenants" : {
                tenant :
                    tenantStructure +
                    {
                        "Accounts" : accounts
                    }
            }
        }
    ]
[/#function]

[#function analyseCMDBProducts cmdbCache tenant product="" environment="" segment="" ]
    [#local products = {} ]

    [#-- Assume tenants up to date in cmdbCache --]
    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]

    [#if tenantStructure?has_content ]
        [#if
            tenantStructure.Products?? &&
            (
                (!product?has_content) ||
                (tenantStructure.Products[product]?has_content)
            ) ]
            [#local products =
                valueIfContent(
                    getObjectAttributes(
                        tenantStructure.Products,
                        product
                    ),
                    product,
                    tenantStructure.Products
                )
            ]
        [#else]
            [#local products = internalAnalyseProductStructure((tenantStructure.Paths.CMDB)!"", product) ]
        [/#if]

        [#list products as productKey, productStructure ]

            [#if
                productStructure.Environments?? &&
                (
                    (!environment?has_content) ||
                    (productStructure.Environments[environment]?has_content)
                ) ]
                [#local environments =
                    valueIfContent(
                        getObjectAttributes(
                            productStructure.Environments,
                            product
                        ),
                        environment,
                        productStructure.Products
                    )
                ]
            [#else]
                [#local environments = internalAnalyseEnvironmentStructure((productStructure.Paths.Infrastructure.Solutions)!"", environment) ]
            [/#if]

            [#list environments as environmentKey, environmentStructure ]

                [#if
                    environmentStructure.Segments?? &&
                    (
                        (!segment?has_content) ||
                        (environmentStructure.Segments[segment]?has_content)
                    ) ]
                    [#local segments =
                        valueIfContent(
                            getObjectAttributes(
                                environmentStructure.Segments,
                                segment
                            ),
                            segment,
                            environmentStructure.Segments
                        )
                    ]
                [#else]
                    [#local segments =  internalAnalyseSegmentStructure((environmentStructure.Paths.Marker)!"",segment) ]
                [/#if]

                [#local environments +=
                    {
                        environmentKey :
                            environmentStructure +
                            {
                                "Segments" : segments
                            }
                    }
                ]
            [/#list]

            [#local products +=
                {
                    productKey :
                        productStructure +
                        {
                            "Environments" : environments
                        }
                }
            ]
        [/#list]
    [/#if]

    [#return
        {
            "Tenants" : {
                tenant :
                    tenantStructure +
                    {
                        "Products" : products
                    }
            }
        }
    ]
[/#function]

[#function assembleCMDBTenantBlueprint cmdbCache tenant="" ]

    [#return internalAssembleCMDBBlueprint((cmdbCache.Tenants[tenant].Paths.Marker)!"") ]

[/#function]

[#function assembleCMDBAccountBlueprint cmdbCache tenant="" account="" ]

    [#return internalAssembleCMDBBlueprint((cmdbCache.Tenants[tenant].Accounts[account].Paths.Marker)!"") ]

[/#function]

[#function assembleCMDBAccountSettings cmdbCache tenant="" account="" ]

    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]
    [#local accountStructure = (tenantStructure.Accounts[account])!{} ]
    [#local fileOnlyRegex = r"[^/]+" ]

    [#local alternatives =
        [
            ["shared", fileOnlyRegex]
        ]
    ]

    [#return
        mergeObjects(
            internalAssembleCMDBSettings(
                (accountStructure.Paths.Settings.Config)!"",
                alternatives
            ),
            internalAssembleCMDBSettings(
                (accountStructure.Paths.Settings.Operations)!"",
                alternatives
            )
        )
    ]

[/#function]

[#function assembleCMDBAccountStackOutputs cmdbCache tenant="" account="" deploymentFramework="cf" ]

    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]
    [#local accountStructure = (tenantStructure.Accounts[account])!{} ]
    [#local fileOnlyRegex = r"[^/]+-stack.json" ]

    [#local alternatives =
        [
            [deploymentFramework, "shared", fileOnlyRegex]
        ]
    ]

    [#return
        internalAssembleCMDBStackOutputs(
            (accountStructure.Paths.State)!"",
            alternatives
        )
    ]

[/#function]


[#function assembleCMDBProductBlueprint cmdbCache tenant="" product="" environment="" segment="" ]

    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]
    [#local productStructure = (tenantStructure.Products[product])!{} ]
    [#local alternatives =
        [
            ["shared"]
        ]
    ]
    [#if environment?has_content]
        [#if segment?has_content]
            [#local alternatives +=
                [
                    ["shared", segment],
                    [environment],
                    [environment, segment]
                ]
            ]
        [#else]
            [#local alternatives +=
                [
                    [environment]
                ]
            ]
        [/#if]
    [/#if]

    [#return
        mergeObjects(
            internalAssembleCMDBBlueprint((tenantStructure.Paths.Marker)!""),
            internalAssembleCMDBBlueprint((productStructure.Paths.Marker)!""),
            internalAssembleCMDBBlueprint(
                (productStructure.Paths.Infrastructure.Solutions)!"",
                [
                    ["shared"],
                    ["shared", segment],
                    [environment],
                    [segment]
                ]
            )
        )
    ]

[/#function]

[#function assembleCMDBProductSettings cmdbCache tenant="" product="" environment="" segment="" ]

    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]
    [#local productStructure = (tenantStructure.Products[product])!{} ]
    [#local fileOnlyRegex = r"[^/]+" ]
    [#local pathAndFileRegex = r".+" ]


    [#local alternatives =
        [
            ["shared", fileOnlyRegex]
        ]
    ]
    [#if environment?has_content]
        [#if segment?has_content]
            [#local alternatives +=
                [
                    ["shared", segment, pathAndFileRegex],
                    [environment, fileOnlyRegex],
                    [environment, segment, pathAndFileRegex]
                ]
            ]
        [#else]
            [#local alternatives +=
                [
                    [environment, fileOnlyRegex]
                ]
            ]
        [/#if]
    [/#if]

    [#return
        mergeObjects(
            internalAssembleCMDBSettings(
                (productStructure.Paths.Settings.Config)!"",
                alternatives
            ),
            internalAssembleCMDBSettings(
                (productStructure.Paths.Infrastructure.Builds)!"",
                alternatives
            ),
            internalAssembleCMDBSettings(
                (productStructure.Paths.Settings.Operations)!"",
                alternatives
            )
        )
    ]

[/#function]

[#function assembleCMDBProductStackOutputs cmdbCache tenant="" product="" environment="" segment="" deploymentFramework="cf" ]

    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]
    [#local productStructure = (tenantStructure.Products[product])!{} ]
    [#local environmentStructure = (productStructure.Products[environment])!{} ]
    [#local segmentStructure = (environmentStructure.Segments[segment])!{} ]
    [#local fileOnlyRegex = r"[^/]+-stack.json" ]

    [#local alternatives =
        [
            [deploymentFramework, "shared", fileOnlyRegex]
        ]
    ]
    [#if environment?has_content]
        [#if segment?has_content]
            [#local alternatives +=
                [
                    [deploymentFramework, environment, fileOnlyRegex],
                    [deploymentFramework, environment, segment, fileOnlyRegex]
                ]
            ]
        [#else]
            [#local alternatives +=
                [
                    [deploymentFramework, environment, fileOnlyRegex]
                ]
            ]
        [/#if]
    [/#if]

    [#return
        internalAssembleCMDBStackOutputs(
            (productStructure.Paths.State)!"",
            alternatives
        )
    ]

[/#function]

[#-------------------------------------------------------
-- Internal support functions for cmdb processing --
---------------------------------------------------------]

[#-- Base function for looking up files in the cmdb file system --]
[#function internalGetCMDBFiles path alternatives cmdbInformation=false]

    [#-- Ignore empty paths --]
    [#if !path?has_content]
        [#return [] ]
    [/#if]

    [#-- Construct alternate paths and anchor to the end of the string --]
    [#local regex = [] ]
    [#list alternatives as alternative]
        [#local alternativePath = concatenate([alternative],"/")]
        [#if alternativePath?has_content]
            [#local regex += [ alternativePath + "$" ] ]
        [/#if]
    [/#list]

    [#-- Find matches --]
    [#return
        getCMDBTree(
            path,
            attributeIfContent("Regex", regex) +
                attributeIfTrue("IncludeCMDBInformation", cmdbInformation, true)
        )
    ]

[/#function]

[#-- Return the first file match --]
[#function internalGetFirstCMDBFile path alternatives cmdbInformation=false]
    [#list alternatives as alternative]
        [#local result = internalGetCMDBFiles(path, [alternative], cmdbInformation)]
        [#if result?has_content]
            [#return result[0] ]
        [/#if]
    [/#list]
    [#return {} ]
[/#function]

[#-- Convenience method to attach a marker file to a range of alternatives --]
[#function internalGetCMDBMarkerFiles path alternatives marker cmdbInformation=false]
    [#local markers = [] ]
    [#list alternatives as alternative]
        [#local markers += [ asArray(alternative) + [marker] ] ]
    [/#list]
    [#return internalGetCMDBFiles(path, markers, cmdbInformation) ]
[/#function]

[#--  Merge a collection of JSON files --]
[#function  internalAssembleCMDBBlueprint path alternatives=[[]] ]
    [#local result = {}]

    [#-- Nothing if no path to check --]
    [#if !path?has_content]
        [#return result ]
    [/#if]

    [#local regex = [] ]
    [#list alternatives as alternative]
        [#local regex += [["^", path, alternative, r"[^/]+\.json"]] ]
    [/#list]
    [#local files = internalGetCMDBFiles(path, regex) ]

    [#list files as file]
        [#if file.ContentsAsJSON?has_content]
            [#local result =
                mergeObjects(result, file.ContentsAsJSON)]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#-- Convert paths to setting namespaces --]
[#-- Also handle asFile processing and   --]
[#-- General/Sensitive/Builds            --]
[#function  internalAssembleCMDBSettings path alternatives=[[]] ]
    [#local result = {} ]

    [#-- Nothing if no path to check --]
    [#if !path?has_content]
        [#return result ]
    [/#if]

    [#local regex = [] ]
    [#list alternatives as alternative]
        [#local regex += [["^", path, alternative]] ]
    [/#list]

    [#local files = internalGetCMDBFiles(path, regex, true) ]

    [#list files as file]
        [#-- Ignore directories --]
        [#if ! file.Contents?has_content]
            [#continue]
        [/#if]

        [#local base = file.Filename?remove_ending("." + file.Extension)]
        [#local attribute = base?replace("_", "_")?upper_case]
        [#local namespace =
            concatenate(
                file.Path?remove_beginning(path)?lower_case?replace("/", " ")?trim?split(" "),
                "-"
            )
        ]
        [#if file.Path?lower_case?contains("asfile") ]
            [#local content =
                {
                    attribute : {
                        "Value" : file.Filename,
                        "AsFile" : file.File
                    }
                }
            ]
        [#else]

            [#-- Settings format depends on file extension --]
            [#switch file.Extension?lower_case]
                [#case "json"]
                    [#if file.ContentsAsJSON??]
                        [#local content = file.ContentsAsJSON]
                        [#break]
                    [/#if]
                    [#-- Fall through to handle file generically if no JSON content --]
                [#default]
                    [#local content =
                        {
                            attribute : {
                                "Value" : file.Contents,
                                "FromFile" : file.File
                            }
                        }
                    ]
                    [#break]
            [/#switch]
        [/#if]

        [#-- General by default --]
        [#local category = "General" ]

        [#if file.Filename?lower_case?trim?matches(r"^.*build\.json$")]
            [#-- Builds --]
            [#local category = "Builds"]
        [/#if]
        [#if file.Filename?lower_case?trim?matches(r"^.*credentials\.json|.*sensitive\.json$")]
            [#-- Sensitive --]
            [#local category = "Sensitive" ]
        [/#if]

        [#-- Update the settings structure --]
        [#local result =
            mergeObjects(
                result,
                {
                    category : {
                        namespace : content
                    }
                }
            )
        ]
    [/#list]

    [#return result ]
[/#function]

[#-- Convert paths to setting namespaces --]
[#-- Also handle asFile processing and   --]
[#-- General/Sensitive/Builds            --]
[#function  internalAssembleCMDBStackOutputs path alternatives=[[]] ]
    [#local result = [] ]

    [#-- Nothing if no path to check --]
    [#if !path?has_content]
        [#return result ]
    [/#if]

    [#local regex = [] ]
    [#list alternatives as alternative]
        [#local regex += [["^", path, alternative]] ]
    [/#list]

    [#local files = internalGetCMDBFiles(path, regex, true) ]

    [#list files as file]
        [#-- Ignore directories --]
        [#if ! file.ContentsAsJSON?has_content]
            [#continue]
        [/#if]

        [#-- Return a simple list of the outputs - the format is opaque at this point --]
        [#local result +=
            [
                {
                    "Filename" : file.Filename,
                    "Contents" : file.ContentsAsJSON
                }
            ]
        ]
    [/#list]

    [#return result ]
[/#function]

[#-- Determine the  key directories associated with a marker file --]
[#function internalAnalyseCMDBPaths path markerFiles full=true]
    [#local result = {} ]

    [#-- Analyse paths --]
    [#list markerFiles as markerFile]
        [#local name = markerFile.Path?keep_after_last("/") ]
        [#if name == "config"]
            [#local name = markerFile.Path?keep_before_last("/")?keep_after_last("/") ]
        [/#if]
        [#if name?has_content ]
            [#local entry =
                {
                    "Paths" : {
                        "Marker" : markerFile.Path
                    } +
                    attributeIfContent("CMDB", (markerFile.CMDB.BasePath)!"")
                }
            ]

            [#if full]
                [#local config =
                    internalGetFirstCMDBFile(
                        path,
                        [
                            [name, "config", "settings"],
                            ["config", ".*", name, "settings"]
                        ]
                    )
                ]
                [#local operations =
                    internalGetFirstCMDBFile(
                        path,
                        [
                            [name, "operations", "settings"],
                            ["operations", ".*", name, "settings"],
                            [name, "infrastructure", "operations"],
                            ["infrastructure", ".*", name, "operations"]
                        ]
                    )
                ]
                [#local solutions =
                    internalGetFirstCMDBFile(
                        path,
                        [
                            [name, "infrastructure", "solutions"],
                            ["infrastructure", ".*", name, "solutions"],
                            [name, "config", "solutionsv2"],
                            ["config", ".*", name, "solutionsv2"]
                        ]
                    )
                ]
                [#local builds =
                    internalGetFirstCMDBFile(
                        path,
                        [
                            [name, "infrastructure", "builds"],
                            ["infrastructure", ".*", name, "builds"],
                            [name, "config", "settings"],
                            ["config", ".*", name, "settings"]
                        ]
                    )
                ]
                [#local state =
                    internalGetFirstCMDBFile(
                        path,
                        [
                            [name, "state"],
                            ["state", ".*", name],
                            [name, "infrastructure"],
                            ["infrastructure", ".*", name]
                        ]
                    )
                ]

                [#local entry =
                    mergeObjects(
                        entry,
                        {
                            "Paths" : {
                                "Settings" : {
                                    "Config" : config.File!"",
                                    "Operations" : operations.File!""
                                },
                                "Infrastructure" : {
                                    "Builds" : builds.File!"",
                                    "Solutions" : solutions.File!""
                                },
                                "State" : state.File!""
                            }
                        }
                    )
                ]
            [/#if]
            [#local result += { name : entry } ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function internalAnalyseTenantStructure path tenant="" ]
    [#-- Find marker files --]
    [#local markerFiles =
        internalGetCMDBMarkerFiles(
            path,
            arrayIfTrue(
                [
                    [tenant],
                    [tenant, "config"]
                ],
                tenant?has_content,
                [ [] ]
            ),
            r"tenant\.json",
            true
        )
    ]

    [#-- Analyse paths --]
    [#return internalAnalyseCMDBPaths(path, markerFiles) ]
[/#function]

[#function internalAnalyseAccountStructure path account=""]
    [#-- Find marker files --]
    [#local markerFiles =
        internalGetCMDBMarkerFiles(
            path,
            arrayIfTrue(
                [
                    [account],
                    [account, "config"]
                ],
                account?has_content,
                [ [] ]
            ),
            r"account\.json"
        )
    ]

    [#-- Analyse paths --]
    [#return internalAnalyseCMDBPaths(path, markerFiles) ]
[/#function]

[#function internalAnalyseProductStructure path product=""]
    [#-- Find marker files --]
    [#local markerFiles =
        internalGetCMDBMarkerFiles(
            path,
            arrayIfTrue(
                [
                    [product],
                    [product, "config"]
                ],
                product?has_content,
                [ [] ]
            ),
            r"product\.json"
        )
    ]

    [#-- Analyse paths --]
    [#return internalAnalyseCMDBPaths(path, markerFiles) ]

[/#function]

[#function internalAnalyseEnvironmentStructure path environment="" ]

    [#-- Find marker files --]
    [#local markerFiles =
        internalGetCMDBMarkerFiles(
            path,
            arrayIfTrue(
                [
                    [environment]
                ],
                environment?has_content,
                [ [] ]
            ),
            r"environment\.json"
        )
    ]

    [#-- Analyse paths --]
    [#return internalAnalyseCMDBPaths(path, markerFiles, false) ]

[/#function]

[#function internalAnalyseSegmentStructure path segment="" ]
    [#-- Find marker files --]
    [#local markerFiles =
        internalGetCMDBMarkerFiles(
            path,
            arrayIfTrue(
                [
                    [segment]
                ],
                segment?has_content,
                [ [] ]
            ),
            r"segment\.json"
        )
    ]

    [#-- Analyse paths --]
    [#return internalAnalyseCMDBPaths(path, markerFiles, false) ]

[/#function]
