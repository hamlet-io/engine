[#ftl]

[#-- Processing to include provider configuration --]

[#assign SHARED_PROVIDER = "shared"]

[#assign providerDictionary = [] ]
[#assign providerMarkers = [] ]

[#-- Only load configuration once --]
[#function isConfigurationIncluded configuration]
    [#if getDictionaryEntry(providerDictionary, configuration)?has_content]
        [#return true]
    [/#if]
    [#assign providerDictionary = addDictionaryEntry(providerDictionary, configuration, {"Present" : true}) ]
    [#return false]
[/#function]

[#function findProviderMarkers ]

    [#-- Determine the providers available --]
    [#local markers =
        getPluginTree(
            "/",
            {
                "Regex" : [r"provider\.ftl"],
                "AddEndingWildcard" : false,
                "MinDepth" : 2,
                "MaxDepth" : 2,
                "FilenameGlob" : r"provider.ftl"
            }
        )
    ]

    [#-- Order providers --]
    [#return markers?sort_by("Path") ]

[/#function]

[#macro initialiseProviders]
    [#local result = initialisePluginFileSystem() ]
    [#assign providerDictionary = initialiseDictionary() ]
    [#assign providerMarkers = findProviderMarkers()  ]
[/#macro]

[#-- Determine what providers have been configured --]
[#-- Include their input sources                   --]
[#macro includeProviders providers... ]

    [#-- Process each requested provider --]
    [#list asFlattenedArray(providers) as provider]

        [#-- Already loaded? --]
        [#if isConfigurationIncluded([provider]) ]
            [#continue]
        [/#if]

        [#-- Find the provider marker --]
        [#list providerMarkers as providerMarker ]

            [#if providerMarker.Path?keep_after_last("/") != provider]
                [#continue]
            [/#if]

            [@internalIncludeProviderConfiguration providerMarker /]

            [#-- Determine the input sources for the provider --]
            [#local inputSources =
                internalGetPluginFiles(
                    [providerMarker.Path, "inputsources"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]

            [#list inputSources as inputSource]
                [@internalIncludeTemplatesInDirectory inputSource /]
            [/#list]
        [/#list]
    [/#list]
[/#macro]

[#macro includeCoreProviderConfiguration providers... ]

    [#-- Process each requested provider --]
    [#list asFlattenedArray(providers) as provider]

        [#-- Already loaded? --]
        [#if isConfigurationIncluded([provider, "core"]) ]
            [#continue]
        [/#if]

        [#-- Process each provider --]
        [#list providerMarkers as providerMarker ]

            [#if providerMarker.Path?keep_after_last("/") != provider]
                [#continue]
            [/#if]

            [#-- Determine the flows for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "flows"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]

            [#list directories as directory]
                [#if directory.IsDirectory!false ]
                    [@internalIncludeTemplatesInDirectory
                        directory,
                        ["flow"]
                    /]
                [/#if]
            [/#list]

            [#-- Determine the deployment frameworks for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "deploymentframeworks"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]
            [#local deploymentFrameworks = [] ]
            [#list directories as directory]
                [#if directory.IsDirectory!false ]
                    [#local deploymentFrameworks += [directory.Filename] ]
                    [@internalIncludeTemplatesInDirectory
                        directory,
                        ["output"]
                    /]
                [/#if]
            [/#list]

            [#-- Determine the reference data for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "references"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]
            [#list directories as directory]
                [@internalIncludeTemplatesInDirectory
                    directory,
                    ["id", "name", "reference"]
                /]
            [/#list]

            [#-- Determine the entrances for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "entrances"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]
            [#list directories as directory]
                [@internalIncludeTemplatesInDirectory
                    directory,
                    [ "id", "entrance" ]
                /]
            [/#list]

            [#-- Determine the tasks for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "tasks"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]
            [#list directories as directory]
                [@internalIncludeTemplatesInDirectory
                    directory,
                    ["id", "name", "task"]
                /]
            [/#list]

            [#-- Determine the resource labels for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "resourcelabels"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]
            [#list directories as directory]
                [@internalIncludeTemplatesInDirectory
                    directory,
                    ["resourcelabel"]
                /]
            [/#list]

            [#-- Determine the global resource groups for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "resourcegroups"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]
            [#list directories as directory]
                [@internalIncludeProviderResourceGroupConfiguration directory.File deploymentFrameworks /]
            [/#list]

            [#-- Determine the scenarios for the provider --]
            [@internalIncludeTemplatesInDirectory [providerMarker.Path, "scenarios"] /]
        [/#list]
    [/#list]
[/#macro]

[#macro includeServicesConfiguration provider services deploymentFramework]
    [#local templates = [] ]

    [#list asArray(services) as service]
        [#-- Check service not already seen --]
        [#if isConfigurationIncluded([provider, "s", service])]
            [#continue]
        [/#if]
        [#list ["id", "name", "policy", "resource"] as level]
            [#-- aws/services/eip/eip.ftl --]
            [#local templates += [[provider, "services", service, level]] ]
        [/#list]
    [/#list]

    [#if deploymentFramework?has_content]
        [#list asArray(services) as service]
            [#-- Check service not already seen --]
            [#if isConfigurationIncluded([provider, "s", service, deploymentFramework])]
                [#continue]
            [/#if]
            [#list ["id", "name", "policy", "resource"] as level]
                [#-- aws/services/eip/cf/id.ftl --]
                [#local templates += [[provider, "services", service, deploymentFramework, level]] ]
            [/#list]
        [/#list]
    [/#if]

    [@includeTemplates templates=templates /]
[/#macro]

[#macro includeProviderComponentDefinitionConfiguration provider component ]

    [#local templates = [] ]

    [#-- Check component not already seen --]
    [#if !isConfigurationIncluded([provider, "c", component, "id"])]
        [#list ["id", "name"] as level]
            [#-- aws/components/lb/id.ftl --]
            [#local templates += [[provider, "components", component, level]] ]
        [/#list]
    [/#if]

    [@includeTemplates templates=templates /]
[/#macro]

[#macro includeProviderComponentConfiguration provider component services=[] deploymentFramework=""]

    [#-- Services configuration --]
    [@includeServicesConfiguration provider services deploymentFramework /]

    [#local templates = [] ]

    [#-- Check component not already seen --]
    [#if !isConfigurationIncluded([provider, "c", component])]
        [#list ["setup", "state"] as level]
            [#-- aws/components/lb/setup.ftl --]
            [#local templates += [[provider, "components", component, level]] ]
        [/#list]

        [#-- Legacy naming for transition --]
        [#-- TODO(mfl): Remove when transition complete --]
        [#list ["segment", "solution"] as level]
            [#-- aws/components/segment/segment_lb.ftl --]
            [#local templates += [[provider, "components", level, level + "_" + component]] ]
        [/#list]
    [/#if]

    [#if deploymentFramework?has_content]
        [#if !isConfigurationIncluded([provider, "c", component, deploymentFramework])]
            [#list ["id", "name", "policy", "resource"] as level]
                [#-- aws/components/eip/cf/id.ftl --]
                [#local templates += [[provider, "components", component, deploymentFramework, level]] ]
            [/#list]
        [/#if]
    [/#if]

    [@includeTemplates templates=templates /]
[/#macro]

[#macro includeProviderViewDefinitionConfiguration provider view ]

    [#local templates = [] ]

    [#-- Check component not already seen --]
    [#if !isConfigurationIncluded([provider, "v", view, "id"])]
        [#list ["id" ] as level]
            [#-- aws/views/blueprint/id.ftl --]
            [#local templates += [[provider, "views", view, level]] ]
        [/#list]
    [/#if]

    [@includeTemplates templates=templates /]
[/#macro]

[#macro includeProviderViewConfiguration provider view ]
    [#local templates = [] ]

    [#-- Check component not already seen --]
    [#if !isConfigurationIncluded([provider, "v", view])]
        [#list [ "setup" ] as level]
            [#-- aws/views/lb/setup.ftl --]
            [#local templates += [[provider, "views", view, level]] ]
        [/#list]
    [/#if]

    [@includeTemplates templates=templates /]
[/#macro]

[#macro includeSharedComponentConfiguration component ]
    [@includeProviderComponentDefinitionConfiguration SHARED_PROVIDER component /]
    [@includeProviderComponentConfiguration SHARED_PROVIDER component /]
[/#macro]

[#macro includeResourceGroupConfiguration provider component resourceGroup services deploymentFramework]
    [#-- Check resource group not already seen --]
    [#if isConfigurationIncluded([provider, component, resourceGroup, deploymentFramework])]
        [#return]
    [/#if]

    [#-- Provider component configuration --]
    [@includeProviderComponentConfiguration provider component services deploymentFramework /]

    [#local templates = [] ]

    [#-- Component specific resourcegroup configuration --]

    [#-- aws/components/lb/lb-lb.ftl --]
    [#local templates += [[provider, "components", component, resourceGroup]] ]
    [#-- aws/components/lb/lb-lb/cf.ftl --]
    [#local templates += [[provider, "components", component, resourceGroup, deploymentFramework]] ]
    [#-- aws/components/lb/cf/lb-lb.ftl --]
    [#local templates += [[provider, "components", component, deploymentFramework, resourceGroup]] ]

    [#list ["id", "name", "setup", "state"] as level]
        [#-- aws/components/lb/lb-lb/id.ftl --]
        [#local templates += [[provider, "components", component, resourceGroup, level]] ]
        [#-- aws/components/lb/lb-lb/cf/id.ftl --]
        [#local templates += [[provider, "components", component, resourceGroup, deploymentFramework, level]] ]
    [/#list]

    [@includeTemplates templates=templates /]

[/#macro]

[#macro includeProviderResourceGroupConfiguration provider resourceGroup deploymentFramework]

    [#-- Check resource group not already seen --]
    [#if isConfigurationIncluded([provider, resourceGroup, deploymentFramework])]
        [#return]
    [/#if]

    [#local templates = [] ]

    [#-- Shared resourcegroup configuration --]
    [#if resourceGroup != DEFAULT_RESOURCE_GROUP ]
        [#list ["id", "name", "setup", "state", deploymentFramework] as level]
            [#-- aws/resourcegroups/lb-lb/id.ftl --]
            [#local templates += [[provider, "resourcegroups", resourceGroup, level]] ]
        [/#list]

        [#list ["id", "name", "setup", "state"] as level]
            [#-- aws/resourcegroups/lb-lb/cf/id.ftl --]
            [#local templates += [[provider, "resourcegroups", resourceGroup, deploymentFramework, level]] ]
        [/#list]
    [/#if]

    [@includeTemplates templates=templates /]

[/#macro]

[#macro includeComponentConfiguration component placements={} profile={} ignore=[] ]
    [#-- Determine the component type --]
    [#local type = component]
    [#if component?is_hash]
        [#local type = getComponentType(component)]
    [/#if]

    [#-- Ensure the shared configuration is loaded --]
    [@includeSharedComponentConfiguration component=type /]

    [#-- Load static dependencies                                                 --]
    [#-- In general, these shouldn't be needed as link processing will generally  --]
    [#-- pick up most dependencies. However, if code uses definitions from a link --]
    [#-- component type or its resources, then a static dependency may be needed  --]
    [#-- to avoid errors when code is parsed as part of being included.           --]
    [#--                                                                          --]
    [#-- TODO(mfl): reassess this as direct dependency on a resource definitions  --]
    [#-- is bad as it is assuming the provider of the target                      --]
    [#-- list getComponentDependencies(type) as dependency --]
        [#-- Ignore circular references --]
        [#-- if !(asArray(ignore)?seq_contains(dependency)) ]
            [@includeComponentConfiguration
                component=dependency
                ignore=(asArray(ignore) + [type])
            /]
        [/#if]
    [/#list --]

    [#-- Load provider specific component service dependencies --]
    [#list getComponentResourceGroups(type)?keys as key]
        [#-- Check for explicit placements config, then profile based placements --]
        [#local placement =
            (placements[key].Placement) !
            placements[key] !
            getResourceGroupPlacement(key, profile) ]

        [#if placement?has_content]
            [@includeProviderComponentDefinitionConfiguration
                provider=placement.Provider
                component=type
            /]
        [/#if]
    [/#list]

    [#-- Component configuration should now include service dependencies --]

    [#list getComponentResourceGroups(type) as key, value]
        [#-- Check for explicit placements config, then profile based placements --]
        [#local placement =
            (placements[key].Placement) !
            placements[key] !
            getResourceGroupPlacement(key, profile) ]

        [#if placement?has_content]
            [@includeResourceGroupConfiguration
                provider=placement.Provider
                component=type
                resourceGroup=key
                services=(value.Services[placement.Provider])![]
                deploymentFramework=placement.DeploymentFramework
            /]
        [/#if]
    [/#list]
[/#macro]

[#------------------------------------------------------
-- Internal support functions for provider processing --
--------------------------------------------------------]

[#-- Base function for listing directories or files in the plugin file system --]
[#function internalGetPluginFiles path alternatives options={} ]

    [#-- Ignore empty paths --]
    [#if !path?has_content]
        [#return [] ]
    [/#if]

    [#-- Construct alternate paths and anchor to the end of the string --]
    [#local regex = [] ]
    [#list alternatives as alternative]
        [#local alternativePath = formatRelativePath(alternative) ]
        [#if alternativePath?has_content]
            [#local regex += [ alternativePath  ] ]
        [/#if]
    [/#list]

    [#-- Find matches --]
    [#return
        getPluginTree(
            formatAbsolutePath(path),
            {
                "AddStartingWildcard" : false,
                "AddEndingWildcard" : false,
                "MinDepth" : 1,
                "MaxDepth" : 1

            } +
            options +
            attributeIfContent("Regex", regex)
        )
    ]

[/#function]

[#-- Include any templates in a list of files                    --]
[#-- Optionally restrict the templates loaded and the load order --]
[#macro internalIncludePluginTemplates files targets=[] ]
    [#if targets?has_content]
        [#list targets as target]
            [#list files as file]
                [#if file.IsTemplate!false]
                    [#if target?lower_case == file.Filename?lower_case?keep_before_last(".")]
                        [#include file.File]
                        [#break]
                    [/#if]
                [/#if]
            [/#list]
        [/#list]
    [#else]
        [#list files as file]
            [#if file.IsTemplate!false]
                [#include file.File]
            [/#if]
        [/#list]
    [/#if]
[/#macro]

[#-- Include the provided files (if found) in the provider order --]
[#-- Directory may either be a string or a file object from getPluginTree --]
[#macro internalIncludeTemplatesInDirectory directory targets=[] ]

    [#local startingDirectory = directory]

    [#-- Check it is a directory --]
    [#if directory?is_hash]
        [#if directory.IsDirectory!false]
            [#local startingDirectory = directory.File ]
        [#else]
            [#-- Not a directory so ignore the file --]
            [#return]
        [/#if]
    [/#if]

    [#-- See what is there --]
    [#local files =
        internalGetPluginFiles(
            startingDirectory,
            [
                [r"[^/]+.ftl"]
            ]
        )
    ]

    [@internalIncludePluginTemplates files targets /]
[/#macro]


[#macro internalIncludeProviderConfiguration providerMarker ]

    [#-- aws/provider.ftl --]
    [#include providerMarker.File /]

    [#-- aws/services/service.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "services"],
        ["service", "id", "name", "policy", "resource"]
    /]

    [#-- aws/components/component.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "components"],
        ["component", "id", "name"]
    /]

    [#-- aws/views/view.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "views"],
        [ "view" ]
    /]

    [#-- aws/references/reference.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "references"],
        ["reference" ]
    /]

    [#-- aws/entrances/entrance.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "entrances"],
        [ "entrance" ]
    /]

    [#-- aws/tasks/task.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "tasks"],
        ["task" ]
    /]

    [#-- aws/resourcelabels/resourcelabel.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "resourcelabels"],
        ["resourcelabel" ]
    /]

    [#-- aws/resourcegroups/resourcegroup.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "resourcegroups"],
        ["resourcegroup", "id", "name"]
    /]

    [#-- aws/deploymentframeworks/output.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "deploymentframeworks"],
        ["output"]
    /]

    [#-- aws/scenarios/scenario.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "scenarios"],
        ["scenario"]
    /]

[/#macro]

[#macro internalIncludeProviderResourceGroupConfiguration resourceGroupDirectory deploymentFrameworks=[] ]

    [@internalIncludeTemplatesInDirectory
        resourceGroupDirectory,
        ["id", "name", "setup", "state"] + deploymentFrameworks
    /]

    [#-- Per deployment framework config --]
    [#list deploymentFrameworks as deploymentFramework]
        [@internalIncludeTemplatesInDirectory
            [resourceGroupDirectory, deploymentFramework],
            ["id", "name", "setup", "state"]
        /]
    [/#list]
[/#macro]
