[#ftl]

[#-- Processing to include provider configuration --]

[#assign SHARED_PROVIDER = "shared"]

[#assign includeOnceConfiguration = {} ]

[#-- Only load configuration once --]
[#function isConfigurationIncluded configuration]
    [#local index = concatenate(configuration, "_")?lower_case]
    [#if includeOnceConfiguration[index]??]
        [#return true]
    [/#if]
    [#assign includeOnceConfiguration += {index:{}}]
    [#return false]
[/#function]

[#macro includeProviderConfiguration provider ]
    [#-- Check provider not already seen --]
    [#if isConfigurationIncluded(provider)]
        [#return]
    [/#if]

    [#local templates = [] ]

    [#-- aws/aws.ftl --]
    [#list [provider, "masterData"] as level]
        [#local templates += [[provider, level]] ]
    [/#list]

    [#-- aws/services/service.ftl --]
    [#list ["service", "id", "name", "policy", "resource"] as level]
        [#local templates += [[provider, "services", level]] ]
    [/#list]

    [#-- aws/components/component.ftl --]
    [#list ["component", "id", "name"] as level]
        [#local templates += [[provider, "components", level]] ]
    [/#list]

    [#-- aws/references/reference.ftl --]
    [#list ["reference" ] as level ]
        [#local templates += [[provider, "references", level]] ]
    [/#list]

    [#-- aws/resourcegroups/resourcegroup.ftl --]
    [#list ["resourcegroup", "id", "name"] as level]
        [#local templates += [[provider, "resourcegroups", level]] ]
    [/#list]

    [#-- aws/deploymentframeworks/output.ftl --]
    [#list ["output", "model"] as level]
        [#local templates += [[provider, "deploymentframeworks", level]] ]
    [/#list]

    [@includeTemplates templates=templates /]
[/#macro]

[#macro includeDeploymentFrameworkConfiguration provider deploymentFramework ]

    [#-- Check deployment framework not already seen --]
    [#if isConfigurationIncluded([provider, deploymentFramework])]
        [#return]
    [/#if]

    [#local templates = [] ]

    [#-- aws/deploymentframeworks/cf/output.ftl --]
    [#list ["output", "model"] as level]
        [#local templates += [[provider, "deploymentframeworks", deploymentFramework, level]] ]
    [/#list]

    [@includeTemplates templates=templates /]
[/#macro]

[#macro includeScenarioConfiguration provider scenarios ]
    [#list scenarios as scenario ]
        [#if isConfigurationIncluded([provider, scenario]) ]
            [#return]
        [/#if]

        [#local templates = []]
        [#list ["scenario"] as level ]
            [#-- aws/scenarios/lb-https.ftl --]
            [#local templates+= [[ provider, "scenarios", scenario]] ]
        [/#list]

        [@includeTemplates templates=templates /]

        [#-- load in the scenarios --]
        [#list [ "scenario" ] as level ]
            [#local scenarioMacroOptions = 
                [
                    [ provider, "scenario", scenario ]
                ]]
            
            [#local scenarioMacro = getFirstDefinedDirective(scenarioMacroOptions)]
            [#if scenarioMacro?has_content ]
                [@(.vars[scenarioMacro]) /]
            [#else]
                [@debug
                    message="Unable to invoke any of the setting scenario macro options"
                    context=scenarioMacroOptions
                    enabled=false
                /]
            [/#if]    
        [/#list]

    [/#list]
[/#macro]

[#macro includeInputSourceConfiguration provider inputSource ]
    [#-- Check inputsource configuration not already seen --]
    [#if isConfigurationIncluded([provider, inputSource]) ]
        [#return]
    [/#if]

    [#local templates = [] ]
    [#-- aws/inputsources/composite/setting.ftl --]
    [#list [ "blueprint", "stackoutput", "setting", "definition" ] as level]
        [#local templates += [[provider, "inputsources", inputSource, level]] ]
    [/#list]

    [@includeTemplates templates=templates /]

    [#-- seed in data provided at the inputsources level for provider and inputSource --]
    [#list [ "setting", "blueprint", "definition" ] as level ]
        [#local seedMacroOptions = 
            [
                [ provider, "input", commandLineOptions.Input.Source, level, "seed" ]
            ]]
        
        [#local seedMacro = getFirstDefinedDirective(seedMacroOptions)]
        [#if seedMacro?has_content ]
            [@(.vars[seedMacro]) /]
        [#else]
            [@debug
                message="Unable to invoke any of the setting seed macro options"
                context=seedMacroOptions
                enabled=false
            /]
        [/#if]    
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

[#macro includeProviderReferenceDefinitionConfiguration provider referenceType ]

    [#local templates = [] ]

    [#-- Check component not already seen --]
    [#if !isConfigurationIncluded([provider, "r", referenceType, "id"])]
        [#list ["id", "name"] as level]
            [#-- aws/references/logFile/id.ftl --]
            [#local templates += [[provider, "references", referenceType, level]] ]
        [/#list]
    [/#if]

    [@includeTemplates templates=templates /]
[/#macro]

[#macro includeSharedReferenceConfiguration referenceType ]
    [@includeProviderReferenceDefinitionConfiguration SHARED_PROVIDER referenceType /]
[/#macro]
