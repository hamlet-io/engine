[#ftl]

[#--------------------------------------
-- CMDB layered file system functions --
----------------------------------------]

[#macro initialiseCMDB]
    [#local result = initialiseCMDBFileSystem({}) ]
    [#assign cmdbCache = initialiseCache() ]
[/#macro]

[#-- CMDB cache management --]
[#macro addToCMDBCache contents...]
    [#assign cmdbCache = addToCache(cmdbCache, contents) ]
[/#macro]

[#macro clearCMDBCache paths={} ]
    [#assign cmdbCache = clearCache(cmdbCache, paths) ]
[/#macro]

[#macro clearCMDBCacheSection path=[] ]
    [#assign cmdbCache = clearCacheSection(cmdbCache, path) ]
[/#macro]

[#function getCMDBCacheSection path=[] ]
    [#return getCacheSection(cmdbCache, path) ]
[/#function]

[#function getCMDBCacheTenantSection tenant path=[] ]
    [#return getCMDBCacheSection(["Tenants", tenant] + path) ]
[/#function]

[#function getCMDBCacheAccountSection tenant account path=[] ]
    [#return getCMDBCacheTenantSection(tenant, ["Accounts", account] + path) ]
[/#function]

[#function getCMDBCacheProductSection tenant product path=[] ]
    [#return getCMDBCacheTenantSection(tenant, ["Products", product] + path) ]
[/#function]

[#function getCMDBCacheSegmentSection tenant product environment segment path=[] ]
    [#return getCMDBCacheProductSection(tenant, product, ["Environments", environment, "Segments", segment] + path) ]
[/#function]

[#-- CMDB structure analysis --]
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
        [#local startingPath = path]
        [#local cmdbPath = internalFindCMDBPath("accounts")]
        [#if cmdbPath?has_content]
            [#local startingPath = cmdbPath]
        [/#if]
        [#local tenants = internalAnalyseTenantStructure(startingPath, tenant) ]
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
    [#local tenantStructure = getCMDBCacheTenantSection(tenant) ]

    [#if tenantStructure?has_content ]
        [#if
            tenantStructure.Accounts?? &&
            (
                (!account?has_content) ||
                (tenantStructure.Accounts[account]?has_content)
            ) ]
            [#local accounts = tenantStructure.Accounts ]
        [#else]
            [#local startingPath = (tenantStructure.Paths.CMDB)!""]
            [#local cmdbPath = internalFindCMDBPath("accounts")]
            [#if cmdbPath?has_content]
                [#local startingPath = cmdbPath]
            [/#if]

            [#local accounts = internalAnalyseAccountStructure(startingPath, account) ]
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
    [#local tenantStructure = getCMDBCacheTenantSection(tenant) ]

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
            [#local startingPath = (tenantStructure.Paths.CMDB)!""]
            [#local cmdbPath = internalFindCMDBPath(product)]
            [#if cmdbPath?has_content]
                [#local startingPath = cmdbPath]
            [/#if]

            [#local products = internalAnalyseProductStructure(startingPath, product) ]
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
                            environment
                        ),
                        environment,
                        productStructure.Environments
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
                    [#local segments =  internalAnalyseSegmentStructure((environmentStructure.Paths.Marker)!"", segment) ]
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

[#-- CMDB configuration extraction --]
[#function assembleCMDBTenantBlueprint tenant ]

    [#return
        {
            "Tenants" : {
                tenant :
                    internalAssembleCMDBBlueprint(
                        (getCMDBCacheTenantSection(tenant).Paths.Marker)!"",
                        [ [] ],
                        {
                            "MinDepth" : 1,
                            "MaxDepth" : 1
                        }
                    )
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
                            internalAssembleCMDBBlueprint(
                                (getCMDBCacheAccountSection(tenant, account).Paths.Marker)!"",
                                [ [] ],
                                {
                                    "MinDepth" : 1,
                                    "MaxDepth" : 1
                                }
                            )
                    }
                }
            }
        }
    ]

[/#function]

[#function assembleCMDBAccountSettings tenant account ]

    [#local cache = getCMDBCacheAccountSection(tenant, account) ]
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
                                    (cache.Paths.Settings.Config)!"",
                                    alternatives,
                                    {
                                        "MinDepth" : 2,
                                        "MaxDepth" : 2
                                    }
                                ),
                                internalAssembleCMDBSettings(
                                    (cache.Paths.Settings.Operations)!"",
                                    alternatives,
                                    {
                                        "MinDepth" : 2,
                                        "MaxDepth" : 2
                                    }
                                )
                            )
                    }
                }
            }
        }
    ]

[/#function]

[#function assembleCMDBAccountStackOutputs tenant account ]

    [#local cache = getCMDBCacheAccountSection(tenant, account) ]
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
                                (cache.Paths.State)!"",
                                alternatives
                            )
                    }
                }
            }
        }
    ]

[/#function]


[#function assembleCMDBProductBlueprint tenant product environment segment ]

    [#local cache = getCMDBCacheProductSection(tenant, product) ]

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
                                                internalAssembleCMDBBlueprint(
                                                    (cache.Paths.Marker)!"",
                                                    [ [] ],
                                                    {
                                                        "MinDepth" : 1,
                                                        "MaxDepth" : 1
                                                    }
                                                ),
                                                internalAssembleCMDBBlueprint(
                                                    (cache.Paths.Infrastructure.Solutions)!"",
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

    [#local cache = getCMDBCacheProductSection(tenant, product) ]
    [#local pathAndFileRegex = r".+" ]

    [#local alternatives =
        [
            ["shared", pathAndFileRegex],
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
                                                    (cache.Paths.Settings.Config)!"",
                                                    alternatives
                                                ),
                                                internalAssembleCMDBSettings(
                                                    (cache.Paths.Infrastructure.Builds)!"",
                                                    alternatives
                                                ),
                                                internalAssembleCMDBSettings(
                                                    (cache.Paths.Settings.Operations)!"",
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

    [#local cache = getCMDBCacheProductSection(tenant, product) ]
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
                                                (cache.Paths.State)!"",
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

[#function assembleCMDBProductDefinitions tenant product environment segment account region]

    [#local cache = getCMDBCacheProductSection(tenant, product) ]
    [#local fileOnlyRegex = r"[^/]+-definition.json" ]
    [#local pathAndFileRegex = r".+-definition.json" ]

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
                                            internalAssembleCMDBDefinitions(
                                                (cache.Paths.State)!"",
                                                [
                                                    [r"[^/]+", "shared", fileOnlyRegex],
                                                    [r"[^/]+", "shared", segment, pathAndFileRegex],
                                                    [r"[^/]+", environment, fileOnlyRegex],
                                                    [r"[^/]+", environment, segment, pathAndFileRegex]
                                                ],
                                                account,
                                                region
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

[#-- CMDB access --]

[#function getCMDBTenantBlueprint ]
    [#local tenant = getTenantInputsContext() ]

    [#if tenant?has_content ]
        [#local cache = getCMDBCacheTenantSection(tenant, ["Blueprint"]) ]
        [#if cache?has_content]
            [#return cache]
        [/#if]

        [@addToCMDBCache analyseCMDBTenants(tenant) /]
        [@addToCMDBCache assembleCMDBTenantBlueprint(tenant) /]
        [#return getCMDBCacheTenantSection(tenant, ["Blueprint"]) ]
    [/#if]

    [#return {} ]
[/#function]

[#function getCMDBAccountBlueprint ]
    [#local tenant = getTenantInputsContext() ]
    [#local account = getAccountInputsContext() ]

    [#if tenant?has_content && account?has_content ]
        [#local cache = getCMDBCacheAccountSection(tenant, account, ["Blueprint"]) ]
        [#if cache?has_content]
            [#return cache]
        [/#if]

        [@addToCMDBCache analyseCMDBTenants(tenant) /]
        [@addToCMDBCache analyseCMDBAccounts(tenant, account) /]
        [@addToCMDBCache assembleCMDBAccountBlueprint(tenant, account) /]
        [#return getCMDBCacheAccountSection(tenant, account, ["Blueprint"]) ]
    [/#if]

    [#return {} ]
[/#function]

[#function getCMDBAccountSettings ]
    [#local tenant = getTenantInputsContext() ]
    [#local account = getAccountInputsContext() ]

    [#if tenant?has_content && account?has_content ]
        [#local cache = getCMDBCacheAccountSection(tenant, account, ["Settings"]) ]
        [#if cache?has_content]
            [#return cache]
        [/#if]

        [@addToCMDBCache analyseCMDBTenants(tenant) /]
        [@addToCMDBCache analyseCMDBAccounts(tenant, account) /]
        [@addToCMDBCache assembleCMDBAccountSettings(tenant, account) /]
        [#return getCMDBCacheAccountSection(tenant, account, ["Settings"]) ]
    [/#if]

    [#return
        {
            "General" : {},
            "Builds" : {},
            "Sensitive" : {}
        }
    ]
[/#function]

[#function getCMDBAccountStackOutputs ]
    [#local tenant = getTenantInputsContext() ]
    [#local account = getAccountInputsContext() ]

    [#if tenant?has_content && account?has_content]
        [#local cache = getCMDBCacheAccountSection(tenant, account, ["StackOutputs"]) ]
        [#if cache?has_content]
            [#return cache]
        [/#if]

        [@addToCMDBCache analyseCMDBTenants(tenant) /]
        [@addToCMDBCache analyseCMDBAccounts(tenant, account) /]
        [@addToCMDBCache assembleCMDBAccountStackOutputs(tenant, account) /]
        [#return getCMDBCacheAccountSection(tenant, account, ["StackOutputs"]) ]
    [/#if]

    [#return [] ]
[/#function]

[#function getCMDBProductBlueprint ]
    [#local tenant = getTenantInputsContext() ]
    [#local product = getProductInputsContext() ]
    [#local environment = getEnvironmentInputsContext() ]
    [#local segment = getSegmentInputsContext() ]

    [#if tenant?has_content && product?has_content && environment?has_content && segment?has_content ]
        [#local cache = getCMDBCacheSegmentSection(tenant, product, environment, segment, ["Blueprint"]) ]
        [#if cache?has_content]
            [#return cache]
        [/#if]

        [@addToCMDBCache analyseCMDBTenants(tenant) /]
        [@addToCMDBCache analyseCMDBProducts(tenant, product, environment, segment) /]
        [@addToCMDBCache assembleCMDBProductBlueprint(tenant, product, environment, segment) /]
        [#return getCMDBCacheSegmentSection(tenant, product, environment, segment, ["Blueprint"]) ]
    [/#if]

    [#return {} ]
[/#function]

[#function getCMDBProductSettings ]
    [#local tenant = getTenantInputsContext() ]
    [#local product = getProductInputsContext() ]
    [#local environment = getEnvironmentInputsContext() ]
    [#local segment = getSegmentInputsContext() ]

    [#if tenant?has_content && product?has_content && environment?has_content && segment?has_content ]
        [#local cache = getCMDBCacheSegmentSection(tenant, product, environment, segment, ["Settings"]) ]
        [#if cache?has_content]
            [#return cache]
        [/#if]

        [@addToCMDBCache analyseCMDBTenants(tenant) /]
        [@addToCMDBCache analyseCMDBProducts(tenant, product, environment, segment) /]
        [@addToCMDBCache assembleCMDBProductSettings(tenant, product, environment, segment) /]
        [#return getCMDBCacheSegmentSection(tenant, product, environment, segment, ["Settings"]) ]
    [/#if]

    [#return
        {
            "General" : {},
            "Builds" : {},
            "Sensitive" : {}
        }
    ]
[/#function]

[#function getCMDBProductStackOutputs ]
    [#local tenant = getTenantInputsContext() ]
    [#local product = getProductInputsContext() ]
    [#local environment = getEnvironmentInputsContext() ]
    [#local segment = getSegmentInputsContext() ]

    [#if tenant?has_content && product?has_content && environment?has_content && segment?has_content ]
        [#local cache = getCMDBCacheSegmentSection(tenant, product, environment, segment, ["StackOutputs"]) ]
        [#if cache?has_content]
            [#return cache]
        [/#if]

        [@addToCMDBCache analyseCMDBTenants(tenant) /]
        [@addToCMDBCache analyseCMDBProducts(tenant, product, environment, segment) /]
        [@addToCMDBCache assembleCMDBProductStackOutputs(tenant, product, environment, segment) /]
        [#return getCMDBCacheSegmentSection(tenant, product, environment, segment, ["StackOutputs"]) ]
    [/#if]

    [#return [] ]
[/#function]

[#function getCMDBProductDefinitions ]
    [#local tenant = getTenantInputsContext() ]
    [#local account = getAccountInputsContext() ]
    [#local region = getRegionInputsContext() ]
    [#local product = getProductInputsContext() ]
    [#local environment = getEnvironmentInputsContext() ]
    [#local segment = getSegmentInputsContext() ]

    [#if
            tenant?has_content && account?has_content && region?has_content &&
            product?has_content && environment?has_content && segment?has_content ]
        [#local cache = getCMDBCacheSegmentSection(tenant, product, environment, segment, ["Definitions", account, region]) ]
        [#if cache?has_content]
            [#return cache]
        [/#if]

        [@addToCMDBCache analyseCMDBTenants(tenant) /]
        [@addToCMDBCache analyseCMDBProducts(tenant, product, environment, segment) /]
        [@addToCMDBCache assembleCMDBProductDefinitions(tenant, product, environment, segment, account, region) /]
        [#return getCMDBCacheSegmentSection(tenant, product, environment, segment, ["Definitions", account, region]) ]
    [/#if]

    [#return {} ]
[/#function]


[#--------------------------------------------------
-- Internal support functions for cmdb processing --
----------------------------------------------------]

[#-- Base function for looking up files in the cmdb file system  --]
[#function internalGetCMDBFiles path alternatives options={} ]

    [#-- Ignore empty paths --]
    [#if !path?has_content]
        [#return [] ]
    [/#if]

    [#-- Construct alternate paths --]
    [#local regex = [] ]
    [#list alternatives as alternative]
        [#local alternativePath = formatRelativePath(alternative)]
        [#if alternativePath?has_content]
            [#local regex += [ alternativePath ] ]
        [/#if]
    [/#list]

    [#-- Find matches --]
    [#return
        getCMDBTree(
            formatAbsolutePath(path),
            {
                "AddEndingWildcard" : false
            } +
            options +
            attributeIfContent("Regex", regex)
        )
    ]
[/#function]

[#-- Return the first file match --]
[#function internalGetFirstCMDBFile path alternatives options={} ]
    [#local result =
        internalGetCMDBFiles(
            path,
            alternatives,
            {
                "StopAfterFirstMatch" : true
            } +
            options
        )
    ]
    [#if result?has_content]
        [#return result[0] ]
    [/#if]
    [#return {} ]
[/#function]

[#-- Convenience method to attach a marker file to a range of alternatives --]
[#-- Marker files may be in a subdirectory of the path, so enable a        --]
[#-- starting wildcard to ensure they are found                            --]
[#function internalGetCMDBMarkerFiles path alternatives marker options={} ]
    [#local markers = [] ]
    [#list alternatives as alternative]
        [#local markers += [ [alternative, marker] ] ]
    [/#list]
    [#return
        internalGetCMDBFiles(
            path,
            markers,
            {
                "IgnoreSubtreeAfterMatch" : true
            } +
            options
        )
    ]
[/#function]

[#--  Merge a collection of JSON/YAML files --]
[#function  internalAssembleCMDBBlueprint path alternatives options={} ]
    [#local result = {}]

    [#-- Support json or yaml --]
    [#local regex = [] ]
    [#list alternatives as alternative]
        [#local regex += [ [alternative, r"[^/]+\.(json|yaml|yml)"] ] ]
    [/#list]
    [#local files =
        internalGetCMDBFiles(
            path,
            regex,
            {
                "AddStartingWildcard" : false
            } +
            options
        )
    ]

    [#list files as file]
        [#if file.ContentsAsJSON?has_content]
            [#local result =
                mergeObjects(result, file.ContentsAsJSON)]
        [/#if]
    [/#list]


    [#return
        {
            "Blueprint" : result
        }
    ]
[/#function]

[#-- Convert paths to setting namespaces --]
[#-- Also handle asFile processing and   --]
[#-- General/Sensitive/Builds            --]
[#function  internalAssembleCMDBSettings path alternatives options={} ]
    [#local result =
        {
            "General" : {},
            "Builds" : {},
            "Sensitive" : {}
        }
    ]

    [#local files =
        internalGetCMDBFiles(
            path,
            alternatives,
            {
                "AddStartingWildcard" : false
            } +
            options
        )
    ]

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
        [#-- For now remove the "/default" form the front to yield a path --]
        [#-- relative to the CMDB root.                                   --]
        [#-- TODO(mfl): Refactor when asFile contents moved to state of   --]
        [#-- CMDB as part of the createTemplate process                   --]
        [#if file.Path?lower_case?contains("asfile") ]
            [#local content =
                {
                    attribute : {
                        "Value" : file.Filename,
                        "AsFile" : file.File?remove_beginning("/default")
                    }
                }
            ]
        [#else]

            [#-- Settings format depends on file extension --]
            [#switch file.Extension?lower_case]
                [#case "json"]
                [#case "yaml"]
                [#case "yml"]
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

    [#return
        {
            "Settings" : result
        }
    ]
[/#function]

[#-- More detailed processing done by stack output handler --]
[#function  internalAssembleCMDBStackOutputs path alternatives options={} ]
    [#local result = [] ]

    [#-- Nothing if no path to check --]
    [#if path?has_content]

        [#local files =
            internalGetCMDBFiles(
                path,
                alternatives,
                {
                    "AddStartingWildcard" : false
                } +
                options
            )
        ]

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

[#function internalAssembleCMDBDefinitions path alternatives account region options={} ]
    [#local result = {} ]

    [#-- Nothing if no path to check --]
    [#if path?has_content]

        [#local files =
            internalGetCMDBFiles(
                path,
                alternatives,
                {
                    "AddStartingWildcard" : false
                } +
                options
            )
        ]

        [#list files as file]
            [#local content = file.ContentsAsJSON!{} ]
            [#-- Ignore if not using a definition structure which includes account and region --]
            [#if (content[account][region])?has_content]
                [#local result = mergeObjects(result, content) ]
            [/#if]
        [/#list]
    [/#if]

    [#return
        {
            "Definitions" : result
        }
    ]
[/#function]

[#-- Determine the key directories associated with a marker file  --]
[#-- Full analysis can optionally be bypassed where not necessary --]
[#function internalAnalyseCMDBPaths path markerFiles full ]
    [#local result = {} ]

    [#-- Analyse paths --]
    [#list markerFiles as markerFile]
        [#local name = markerFile.Path?keep_after_last("/") ]
        [#local rootDir = markerFile.Path ]
        [#if name == "config"]
            [#local rootDir = rootDir?keep_before_last("/") ]
            [#local name = rootDir?keep_after_last("/") ]
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
                [#-- First try the common case of a single cmdb --]
                [#local config =
                    internalGetFirstCMDBFile(
                        rootDir,
                        [
                            ["config", "settings"]
                        ],
                        {
                            "AddStartingWildcard" : false,
                            "MinDepth" : 2,
                            "MaxDepth" : 2
                        }
                    )
                ]
                [#local operations =
                    internalGetFirstCMDBFile(
                        rootDir,
                        [
                            ["operations", "settings"],
                            ["infrastructure", "operations"]
                        ],
                        {
                            "AddStartingWildcard" : false,
                            "MinDepth" : 2,
                            "MaxDepth" : 2
                        }
                    )
                ]
                [#local solutions =
                    internalGetFirstCMDBFile(
                        rootDir,
                        [
                            ["infrastructure", "solutions"],
                            ["config", "solutionsv2"]
                        ],
                        {
                            "AddStartingWildcard" : false,
                            "MinDepth" : 2,
                            "MaxDepth" : 2
                        }
                    )
                ]
                [#local builds =
                    internalGetFirstCMDBFile(
                        rootDir,
                        [
                            ["infrastructure", "builds"],
                            ["config", "settings"]
                        ],
                        {
                            "AddStartingWildcard" : false,
                            "MinDepth" : 2,
                            "MaxDepth" : 2
                        }
                    )
                ]
                [#local state =
                    internalGetFirstCMDBFile(
                        rootDir,
                        [
                            ["state"],
                            ["infrastructure"]
                        ],
                        {
                            "AddStartingWildcard" : false,
                            "MinDepth" : 1,
                            "MaxDepth" : 1
                        }
                    )
                ]

                [#-- Try more expensive searches if not the common case --]
                [#if !config?has_content]
                    [#local config =
                        internalGetFirstCMDBFile(
                            path,
                            [
                                [name, "config", "settings"],
                                ["config", ".*", name, "settings"]
                            ],
                            {
                                "AddStartingWildcard" : true
                            }
                        )
                    ]
                [/#if]
                [#if !operations?has_content]
                    [#local operations =
                        internalGetFirstCMDBFile(
                            path,
                            [
                                [name, "operations", "settings"],
                                ["operations", ".*", name, "settings"],
                                [name, "infrastructure", "operations"],
                                ["infrastructure", ".*", name, "operations"]
                            ],
                            {
                                "AddStartingWildcard" : true
                            }
                        )
                    ]
                [/#if]
                [#if !solutions?has_content]
                    [#local solutions =
                        internalGetFirstCMDBFile(
                            path,
                            [
                                [name, "infrastructure", "solutions"],
                                ["infrastructure", ".*", name, "solutions"],
                                [name, "config", "solutionsv2"],
                                ["config", ".*", name, "solutionsv2"]
                            ],
                            {
                                "AddStartingWildcard" : true
                            }
                        )
                    ]
                [/#if]
                [#if !builds?has_content]
                    [#local builds =
                        internalGetFirstCMDBFile(
                            path,
                            [
                                [name, "infrastructure", "builds"],
                                ["infrastructure", ".*", name, "builds"],
                                [name, "config", "settings"],
                                ["config", ".*", name, "settings"]
                            ],
                            {
                                "AddStartingWildcard" : true
                            }
                        )
                    ]
                [/#if]
                [#if !state?has_content]
                    [#local state =
                        internalGetFirstCMDBFile(
                            path,
                            [
                                [name, "state"],
                                ["state", ".*", name],
                                [name, "infrastructure"],
                                ["infrastructure", ".*", name]
                            ],
                            {
                                "AddStartingWildcard" : true
                            }
                        )
                    ]
                [/#if]

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
            r"tenant\.(json|yaml|yml)",
            {
                "AddStartingWildcard" : true,
                "IncludeCMDBInformation" : true,
                "FilenameGlob" : r"tenant.*"
            }
        )
    ]

    [#-- Analyse paths --]
    [#return internalAnalyseCMDBPaths(path, markerFiles, false) ]
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
            r"account\.(json|yaml|yml)",
            {
                "AddStartingWildcard" : true,
                "FilenameGlob" : r"account.*"
            }
        )
    ]

    [#-- Analyse paths --]
    [#return internalAnalyseCMDBPaths(path, markerFiles, true) ]
[/#function]

[#function internalAnalyseProductStructure path product=""]
    [#-- Find marker files --]
    [#if product?has_content && path?ends_with(product)]
        [#local markerFiles =
            internalGetCMDBMarkerFiles(
                path,
                [
                    [],
                    ["config"]
                ],
                r"product\.(json|yaml|yml)",
                {
                    "AddStartingWildcard" : false,
                    "FilenameGlob" : r"product.*"
                }
            )
        ]
    [#else]
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
                r"product\.(json|yaml|yml)",
                {
                    "AddStartingWildcard" : true,
                    "FilenameGlob" : r"product.*"
                }
            )
        ]
    [/#if]

    [#-- Analyse paths --]
    [#return internalAnalyseCMDBPaths(path, markerFiles, true) ]

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
            r"environment\.(json|yaml|yml)",
            {
                "AddStartingWildcard" : false,
                "MinDepth" : 2,
                "MaxDepth" : 2,
                "FilenameGlob" : r"environment.*"
            }
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
            r"segment\.(json|yaml|yml)",
            {
                "AddStartingWildcard" : false,
                "MinDepth" : 2,
                "MaxDepth" : 2,
                "FilenameGlob" : r"segment.*"
            }
        )
    ]

    [#-- Analyse paths --]
    [#return internalAnalyseCMDBPaths(path, markerFiles, false) ]

[/#function]

[#function internalFindCMDBPath name ]
    [#local result = ""]
    [#-- Iterate through the CMDBS to see if one matches the name requested --]
    [#local cmdbs = getCMDBs({"ActiveOnly" : true}) ]
    [#list cmdbs as cmdb]
        [#if cmdb.Name == name]
            [#local result = cmdb.CMDBPath]
            [#break]
        [/#if]
    [/#list]

    [#return result]
[/#function]
