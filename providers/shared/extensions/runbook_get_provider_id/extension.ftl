[#ftl]

[@addExtension
    id="runbook_get_provider_id"
    aliases=[
        "_runbook_get_provider_id"
    ]
    description=[
        "Sets the runbook task paramter ProviderId to the current Accounts providerId"
    ]
    supportedTypes=[
        RUNBOOK_STEP_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_runbook_get_provider_id_runbook_setup occurrence ]
    [#assign _context = mergeObjects(
        _context,
        {
            "TaskParameters" : {
                "AccountId" : accountObject.Id,
                "ProviderId" : accountObject.ProviderId,
                "Provider" : accountObject.Provider
            }
        }
    )]
[/#macro]
