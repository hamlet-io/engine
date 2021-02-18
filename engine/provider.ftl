[#ftl]

[#-- Processing to include provider configuration --]

[#assign SHARED_PROVIDER = "shared"]

[#assign providerDictionary = [] ]
[#assign providerMarkers = [] ]

[#assign pluginMetadata = {}]

[#macro addPluginMetadata id ref ]
    [#assign pluginMetadata = mergeObjects( pluginMetadata, { id : ref } )]
[/#macro]

[#function getPluginMetadata ]
    [#return pluginMetadata]
[/#function]

[#macro addEnginePluginMetadata pluginState ]
    [#if (pluginState["Plugins"]["_engine"]!{})?has_content ]
        [#local sharedPlugin = pluginState["Plugins"]["_engine" ]]
        [@addPluginMetadata
            id="_engine"
            ref=sharedPlugin.ref
        /]
    [/#if]
[/#macro]

[#function getActivePluginsFromLayers  ]

    [#local plugins = [] ]
    [#local possiblePlugins = asFlattenedArray(getActiveLayerAttributes( [ "Plugins" ] )) ]

    [#list possiblePlugins as pluginInstance ]
        [#list pluginInstance as id, plugin ]
            [#if (plugin.Enabled)!false]
                [#local plugins += [ { "Id" : id } + plugin ] ]
            [/#if]
        [/#list]
    [/#list]
    [#return plugins ]
[/#function]

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

        [/#list]
    [/#list]
[/#macro]

[#macro addPluginsFromLayers pluginState ]
    [#local definedPlugins = getActivePluginsFromLayers() ]

    [#list definedPlugins?sort_by("Priority") as plugin]
        [#local pluginRequired = plugin.Required]
        [#local pluginPath = formatRelativePath(plugin.Id, plugin.Name )]

        [#local definedPluginState = (pluginState["Plugins"][plugin.Id])!{} ]

        [#if pluginRequired && !(definedPluginState?has_content) && plugin.Source != "local" ]
            [@fatal
                message="Plugin setup not complete"
                detail="A plugin was required but plugin setup has not been run"
                context=plugin
            /]
        [/#if]


        [#local pluginProviderMarker = providerMarkers?filter(
                                            marker -> marker.Path?keep_after_last("/") == plugin.Name ) ]

        [#if !(pluginProviderMarker?has_content) && pluginRequired  ]
            [@fatal
                message="Unable to load required provider"
                detail="The provider could not be found in the local state - please load hamlet plugins"
                context=plugin
            /]
            [#continue]
        [/#if]

        [@addPluginMetadata
            id=plugin.Id
            ref=(definedPluginState.ref)!plugin.Source
        /]

        [@addCommandLineOption
            option={
                "Deployment" : {
                    "Provider" : {
                        "Names" : combineEntities( (commandLineOptions.Deployment.Provider.Names)![], [ plugin.Name ], UNIQUE_COMBINE_BEHAVIOUR)
                    }
                }
            }
        /]
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

            [#-- Determine the layers for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "layers"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]
            [#list directories as directory]
                [@internalIncludeTemplatesInDirectory
                    directory,
                    ["id"]
                /]
            [/#list]

            [#-- Determine the AttributeSets for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "attributesets"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]
            [#list directories as directory]
                [@internalIncludeTemplatesInDirectory
                    directory,
                    ["id", "attributeset"]
                /]
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

            [#-- Determine the modules for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "modules"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]
            [#list directories as directory]
                [@internalIncludeTemplatesInDirectory
                    directory,
                    ["id", "module"]
                /]
            [/#list]

            [#-- Determine the extensions for the provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "extensions"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]
            [#list directories as directory]
                [@internalIncludeTemplatesInDirectory
                    directory,
                    ["id", "extension"]
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

            [#-- Determine the modules for the provider --]
            [@internalIncludeTemplatesInDirectory [providerMarker.Path, "modules"] /]
        [/#list]
    [/#list]
[/#macro]

[#macro includeAllServicesConfiguration provider deploymentFramework="" ]

    [#-- Process each provider --]
    [#list providerMarkers as providerMarker ]

        [#if providerMarker.Path?keep_after_last("/") != provider]
            [#continue]
        [/#if]

        [#-- Determine the components available from a provider --]
        [#local directories =
            internalGetPluginFiles(
                [providerMarker.Path, "services"],
                [
                    ["[^/]+"]
                ]
            )
        ]

        [#local providerServices = []]
        [#list directories as directory]
            [#if directory.IsDirectory!false ]
                [#local providerServices += [directory.Filename] ]
            [/#if]
        [/#list]

        [@includeServicesConfiguration
            provider=provider
            services=providerServices
            deploymentFramework=deploymentFramework
        /]

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

[#macro includeAllViewConfiguration providers... ]
    [#list asFlattenedArray(providers) as provider ]

        [#-- Process each provider --]
        [#list providerMarkers as providerMarker ]

            [#if providerMarker.Path?keep_after_last("/") != provider]
                [#continue]
            [/#if]

            [#-- Determine the components available from a provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "views"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]

            [#local providerViews = []]
            [#list directories as directory]
                [#if directory.IsDirectory!false ]
                    [#local providerViews += [directory.Filename] ]
                [/#if]
            [/#list]

            [#list providerViews as providerView ]
                [@includeProviderViewDefinitionConfiguration
                    provider=provider
                    view=providerView
                /]
            [/#list]
        [/#list]
    [/#list]
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

[#macro includeAllComponentDefinitionConfiguration providers... ]

    [#list asFlattenedArray(providers) as provider ]

        [#-- Process each provider --]
        [#list providerMarkers as providerMarker ]

            [#if providerMarker.Path?keep_after_last("/") != provider]
                [#continue]
            [/#if]

            [#-- Determine the components available from a provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "components"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]

            [#local providerComponents = []]
            [#list directories as directory]
                [#if directory.IsDirectory!false ]
                    [#local providerComponents += [directory.Filename] ]
                [/#if]
            [/#list]

            [#list providerComponents as providerComponent ]
                [@includeProviderComponentDefinitionConfiguration
                    provider=provider
                    component=providerComponent
                /]
            [/#list]
        [/#list]
    [/#list]
[/#macro]


[#macro includeAllComponentConfiguration providers... ]

    [#list asFlattenedArray(providers) as provider ]

        [#-- Process each provider --]
        [#list providerMarkers as providerMarker ]

            [#if providerMarker.Path?keep_after_last("/") != provider]
                [#continue]
            [/#if]

            [#-- Determine the components available from a provider --]
            [#local directories =
                internalGetPluginFiles(
                    [providerMarker.Path, "components"],
                    [
                        ["[^/]+"]
                    ]
                )
            ]

            [#local providerComponents = []]
            [#list directories as directory]
                [#if directory.IsDirectory!false ]
                    [#local providerComponents += [directory.Filename] ]
                [/#if]
            [/#list]

            [#list providerComponents as providerComponent ]
                [@includeProviderComponentConfiguration
                    provider=provider
                    component=providerComponent
                /]
            [/#list]
        [/#list]
    [/#list]
[/#macro]

[#--- Query Provider Dictionary --]
[#function getProviderComponentNames provider ]
    [#local providerComponents = getCacheSection(providerDictionary, [provider, "c"] ) ]

    [#local providerComponentNames = []]
    [#list providerComponents as id, component ]
        [#if (component.id.Content.Present)!false ]
            [#local providerComponentNames += [ id ]]
        [/#if]
    [/#list]
    [#return providerComponentNames ]
[/#function]

[#function getProviderViewNames provider ]
    [#local providerViews = getCacheSection(providerDictionary, [provider, "v"] ) ]

    [#local providerViewNames = []]
    [#list providerViews as id, view ]
        [#if (view.id.Content.Present)!false ]
            [#local providerViewNames += [ id ]]
        [/#if]
    [/#list]
    [#return providerViewNames ]
[/#function]

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

    [#-- aws/attributesets/attributeset.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "attributesets"],
        ["attributeset" ]
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

    [#-- aws/layers/layer.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "layers"],
        ["layer" ]
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

    [#-- aws/extensions/extension.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "extensions"],
        [ "extension" ]
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

    [#-- aws/modules/module.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "modules"],
        ["module"]
    /]

    [#-- aws/inputstages/inputstage.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "inputstages"],
        ["inputstage" ]
    /]

    [#-- Determine the input stages --]
    [#local inputStages =
        internalGetPluginFiles(
            [providerMarker.Path, "inputstages"],
            [
                ["[^/]+"]
            ]
        )
    ]

    [#list inputStages as inputStage]
        [#if inputStage.IsDirectory!false ]
            [@internalIncludeTemplatesInDirectory
                inputStage,
                ["id"]
            /]
        [/#if]
    [/#list]

    [#-- aws/inputsources/inputsource.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "inputsources"],
        ["inputsource" ]
    /]

    [#-- Determine the input sources --]
    [#local inputSources =
        internalGetPluginFiles(
            [providerMarker.Path, "inputsources"],
            [
                ["[^/]+"]
            ]
        )
    ]

    [#list inputSources as inputSource]
        [#if inputSource.IsDirectory!false ]
            [@internalIncludeTemplatesInDirectory
                inputSource
            /]
        [/#if]
    [/#list]

    [#-- aws/inputseeders/inputseeder.ftl --]
    [@internalIncludeTemplatesInDirectory
        [providerMarker.Path, "inputseeders"],
        ["inputseeder" ]
    /]

    [#-- Determine the input seeders --]
    [#local inputSeeders =
        internalGetPluginFiles(
            [providerMarker.Path, "inputseeders"],
            [
                ["[^/]+"]
            ]
        )
    ]

    [#list inputSeeders as inputSeeder]
        [#if inputSeeder.IsDirectory!false ]
            [@internalIncludeTemplatesInDirectory
                inputSeeder,
                ["id"]
            /]

            [#local seederLoaderOptions =
                [
                    [ inputSeeder.Filename, "input", "loader" ]
                ]
            ]

            [#local seederLoader = getFirstDefinedDirective(seederLoaderOptions)]

            [#if (.vars[seederLoader]!"")?is_directive]
                [@(.vars[seederLoader]) path=inputSeeder.File /]
            [#else]
                [@debug
                    message="Unable to invoke loader for seeder function"
                    context=seederLoaderOptions
                    enabled=false
                /]
            [/#if]
        [/#if]
    [/#list]
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
