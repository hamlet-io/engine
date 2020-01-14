[#ftl]

[#--------------------------------------
-- CMDB layered file system functions --
----------------------------------------]

[#-- CMDB cache management --]
[#assign cmdbCache = {} ]

[#function addToCMDBCache contents... ]
    [#assign cmdbCache = mergeObjects(cmdbCache, contents) ]
    [#return cmdbCache]
[/#function]

[#function clearCMDBCache paths={} ]
    [#assign cmdbCache = internalClearCMDBCache(cmdbCache, paths) ]
    [#return cmdbCache]
[/#function]

[#function clearTenantCMDBCache tenant]
    [#return
        clearCMDBCache(
            {
                "Tenants" : {
                    tenant : {}
                }
            }
        )
    ]
[/#function]

[#function clearAccountCMDBCache tenant account]
    [#return
        clearCMDBCache(
            {
                "Tenants" : {
                    tenant : {
                        "Accounts" : {
                            account : {}
                        }
                    }
                }
            }
        )
    ]
[/#function]

[#function clearProductCMDBCache tenant product]
    [#return
        clearCMDBCache(
            {
                "Tenants" : {
                    tenant : {
                        "Products" : {
                            product : {}
                        }
                    }
                }
            }
        )
    ]
[/#function]

[#function clearEnvironmentCMDBCache tenant product environment]
    [#return
        clearCMDBCache(
            {
                "Tenants" : {
                    tenant : {
                        "Products" : {
                            product : {
                                "Environments" : {
                                    environment : {}
                                }
                            }
                        }
                    }
                }
            }
        )
    ]
[/#function]

[#function clearSegmentCMDBCache tenant product environment segment]
    [#return
        clearCMDBCache(
            {
                "Tenants" : {
                    tenant : {
                        "Products" : {
                            product : {
                                "Environments" : {
                                    environment : {
                                        "Segments" : {
                                            segment : {}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        )
    ]
[/#function]

[#function analyseCMDBTenants tenant="" path="/" ]
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

[#function analyseCMDBAccounts tenant account="" ]
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

[#function analyseCMDBProducts tenant product="" environment="" segment="" ]
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

[#function assembleCMDBTenantBlueprint tenant ]

    [#return
        {
            "Tenants" : {
                tenant :
                    internalAssembleCMDBBlueprint((cmdbCache.Tenants[tenant].Paths.Marker)!"")
            }
        }
    ]

[/#function]

[#function assembleCMDBAccountBlueprint tenant account ]

    [#return
        {
            "Tenants" : {
                tenant : {
                    "Accounts" : {
                        account :
                            internalAssembleCMDBBlueprint((cmdbCache.Tenants[tenant].Accounts[account].Paths.Marker)!"")
                    }
                }
            }
        }
    ]

[/#function]

[#function assembleCMDBAccountSettings tenant account ]

    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]
    [#local accountStructure = (tenantStructure.Accounts[account])!{} ]
    [#local fileOnlyRegex = r"[^/]+" ]

    [#local alternatives =
        [
            ["shared", fileOnlyRegex]
        ]
    ]

    [#return
        {
            "Tenants" : {
                tenant : {
                    "Accounts" : {
                        account :
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
                    }
                }
            }
        }
    ]

[/#function]

[#function assembleCMDBAccountStackOutputs tenant account ]

    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]
    [#local accountStructure = (tenantStructure.Accounts[account])!{} ]
    [#local pathAndFileRegex = r".+-stack.json" ]

    [#local alternatives =
        [
            [r"[^/]+", "shared", pathAndFileRegex]
        ]
    ]

    [#return
        {
            "Tenants" : {
                tenant : {
                    "Accounts" : {
                        account :
                            internalAssembleCMDBStackOutputs(
                                (accountStructure.Paths.State)!"",
                                alternatives
                            )
                    }
                }
            }
        }
    ]

[/#function]


[#function assembleCMDBProductBlueprint tenant product environment segment ]

    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]
    [#local productStructure = (tenantStructure.Products[product])!{} ]

    [#return
        {
            "Tenants" : {
                tenant : {
                    "Products" : {
                        product : {
                            "Environments" : {
                                environment : {
                                    "Segments" : {
                                        segment :
                                            mergeObjects(
                                                internalAssembleCMDBBlueprint((tenantStructure.Paths.Marker)!""),
                                                internalAssembleCMDBBlueprint((productStructure.Paths.Marker)!""),
                                                internalAssembleCMDBBlueprint(
                                                    (productStructure.Paths.Infrastructure.Solutions)!"",
                                                    [
                                                        ["shared"],
                                                        ["shared", segment],
                                                        [environment],
                                                        [environment, segment]
                                                    ]
                                                )
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    ]

[/#function]

[#function assembleCMDBProductSettings tenant product environment segment ]

    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]
    [#local productStructure = (tenantStructure.Products[product])!{} ]
    [#local fileOnlyRegex = r"[^/]+" ]
    [#local pathAndFileRegex = r".+" ]

    [#local alternatives =
        [
            ["shared", fileOnlyRegex],
            ["shared", segment, pathAndFileRegex],
            [environment, fileOnlyRegex],
            [environment, segment, pathAndFileRegex]
        ]
    ]

    [#return
        {
            "Tenants" : {
                tenant : {
                    "Products" : {
                        product : {
                            "Environments" : {
                                environment : {
                                    "Segments" : {
                                        segment :
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
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    ]

[/#function]

[#function assembleCMDBProductStackOutputs tenant product environment segment ]

    [#local tenantStructure = (cmdbCache.Tenants[tenant])!{} ]
    [#local productStructure = (tenantStructure.Products[product])!{} ]
    [#local fileOnlyRegex = r"[^/]+-stack.json" ]
    [#local pathAndFileRegex = r".+-stack.json" ]

    [#return
        {
            "Tenants" : {
                tenant : {
                    "Products" : {
                        product : {
                            "Environments" : {
                                environment : {
                                    "Segments" : {
                                        segment :
                                            internalAssembleCMDBStackOutputs(
                                                (productStructure.Paths.State)!"",
                                                [
                                                    [r"[^/]+", "shared", fileOnlyRegex],
                                                    [r"[^/]+", "shared", segment, pathAndFileRegex],
                                                    [r"[^/]+", environment, fileOnlyRegex],
                                                    [r"[^/]+", environment, segment, pathAndFileRegex]
                                                ]
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    ]

[/#function]

[#function getCMDBAccountBlueprint tenant account ]

    [#if !(cmdbCache.Tenants[tenant].Accounts[account].Blueprint)?has_content]
        [#local cmdb = addToCMDBCache(analyseCMDBTenants(tenant)) ]
        [#local cmdb = addToCMDBCache(analyseCMDBAccounts(tenant, account)) ]
        [#local cmdb = addToCMDBCache(assembleCMDBAccountBlueprint(tenant, account)) ]
    [/#if]

    [#return (cmdbCache.Tenants[tenant].Accounts[account].Blueprint)!{} ]

[/#function]

[#function getCMDBAccountSettings tenant account ]

    [#if !(cmdbCache.Tenants[tenant].Accounts[account].Settings)?has_content]
        [#local cmdb = addToCMDBCache(analyseCMDBTenants(tenant)) ]
        [#local cmdb = addToCMDBCache(analyseCMDBAccounts(tenant, account)) ]
        [#local cmdb = addToCMDBCache(assembleCMDBAccountSettings(tenant, account)) ]
    [/#if]

    [#return (cmdbCache.Tenants[tenant].Accounts[account].Settings)!{} ]

[/#function]

[#function getCMDBAccountStackOutputs tenant account ]

    [#if !(cmdbCache.Tenants[tenant].Accounts[account].StackOutputs)?has_content]
        [#local cmdb = addToCMDBCache(analyseCMDBTenants(tenant)) ]
        [#local cmdb = addToCMDBCache(analyseCMDBAccounts(tenant, account)) ]
        [#local cmdb = addToCMDBCache(assembleCMDBAccountStackOutputs(tenant, account)) ]
    [/#if]

    [#return (cmdbCache.Tenants[tenant].Accounts[account].StackOutputs)![] ]

[/#function]

[#function getCMDBProductBlueprint tenant product environment segment]

    [#if !(cmdbCache.Tenants[tenant].Products[product].Environments[environment].Segments[segment].Blueprint)?has_content]
        [#local cmdb = addToCMDBCache(analyseCMDBTenants(tenant)) ]
        [#local cmdb = addToCMDBCache(analyseCMDBProducts(tenant, product, environment, segment)) ]
        [#local cmdb = addToCMDBCache(assembleCMDBProductBlueprint(tenant, product, environment, segment)) ]
    [/#if]

    [#return (cmdbCache.Tenants[tenant].Products[product].Environments[environment].Segments[segment].Blueprint)!{} ]

[/#function]

[#function getCMDBProductSettings tenant product environment segment]

    [#if !(cmdbCache.Tenants[tenant].Products[product].Environments[environment].Segments[segment].Settings)?has_content]
        [#local cmdb = addToCMDBCache(analyseCMDBTenants(tenant)) ]
        [#local cmdb = addToCMDBCache(analyseCMDBProducts(tenant, product, environment, segment)) ]
        [#local cmdb = addToCMDBCache(assembleCMDBProductSettings(tenant, product, environment, segment)) ]
    [/#if]

    [#return (cmdbCache.Tenants[tenant].Products[product].Environments[environment].Segments[segment].Settings)!{} ]

[/#function]

[#function getCMDBProductStackOutputs tenant product environment segment]

    [#if !(cmdbCache.Tenants[tenant].Products[product].Environments[environment].Segments[segment].StackOutputs)?has_content]
        [#local cmdb = addToCMDBCache(analyseCMDBTenants(tenant)) ]
        [#local cmdb = addToCMDBCache(analyseCMDBProducts(tenant, product, environment, segment)) ]
        [#local cmdb = addToCMDBCache(assembleCMDBProductStackOutputs(tenant, product, environment, segment)) ]
    [/#if]

    [#return (cmdbCache.Tenants[tenant].Products[product].Environments[environment].Segments[segment].StackOutputs)![] ]

[/#function]

[#-------------------------------------------------------
-- Internal support functions for cmdb processing --
---------------------------------------------------------]

[#-- Manage clearing of the cache --]
[#function internalClearCMDBCache cmdbCache paths={} ]
    [#local result = {}]

    [#if paths?keys?size > 0]
        [#-- Specific attributes provided for clearing --]
        [#list cmdbCache as key,value]
            [#if paths[key]??]
                [#if paths[key]?has_content]
                    [#-- Part of the cache to clear --]
                    [#local subContent = internalClearCMDBCache(value, paths[key]) ]
                    [#if subContent?has_content]
                        [#local result += { key : subContent } ]
                    [#else]
                        [#-- No subcontent so remove the key --]
                    [/#if]
                [#else]
                    [#-- The key and its contents are to be cleared --]
                [/#if]
            [#else]
                [#-- Leave cache intact --]
                [#local result += {key, value}]
            [/#if]
        [/#list]
    [#else]
        [#-- Clear the entire cache --]
    [/#if]

    [#assign cmdbCache = result]
[/#function]

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
    [#if path?has_content]
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
    [/#if]

    [#return
        {
            "Blueprint" : result
        }
    ]
[/#function]

[#-- Convert paths to setting namespaces --]
[#-- Also handle asFile processing and   --]
[#-- General/Sensitive/Builds            --]
[#function  internalAssembleCMDBSettings path alternatives=[[]] ]
    [#local result =
        {
            "General" : {},
            "Builds" : {},
            "Sensitive" : {}
        }
    ]

    [#-- Nothing if no path to check --]
    [#if path?has_content]

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
    [/#if]

    [#return
        {
            "Settings" : result
        }
    ]
[/#function]

[#-- Convert paths to setting namespaces --]
[#-- Also handle asFile processing and   --]
[#-- General/Sensitive/Builds            --]
[#function  internalAssembleCMDBStackOutputs path alternatives=[[]] ]
    [#local result = [] ]

    [#-- Nothing if no path to check --]
    [#if path?has_content]

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
                        "FilePath" : file.Path,
                        "FileName" : file.Filename,
                        "Content" : [file.ContentsAsJSON]
                    }
                ]
            ]
        [/#list]
    [/#if]

    [#return
        {
            "StackOutputs" : result
        }
    ]
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

            [#-- TODO(MFL) Remove once accounts/products are logically under tenant --]
            [#-- For now, assume only one tenant                                    --]
            [#if entry.Paths.CMDB?has_content]
                [#local entry = mergeObjects(entry, {"Paths" : {"CMDB" : "/"}})]
            [/#if]

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
