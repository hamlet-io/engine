[#assign SSM_DOCUMENT_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]
[#assign outputMappings +=
    {
        SSM_DOCUMENT_RESOURCE_TYPE : SSM_DOCUMENT_OUTPUT_MAPPINGS
    }
]

[#macro createSSMDocument mode id content tags documentType="" dependencies="" ]
    [@cfResource
        mode=mode
        id=id
        type="AWS::SSM::Document"
        properties=
            {
                "Content" : content,
                "DocumentType" : documentType,
                "Tags" : tags
            }
        outputs=SSM_DOCUMENT_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]
