[#ftl]

[#macro aws_s3_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local id = formatOccurrenceS3Id(occurrence)]
    [#local name = formatOccurrenceBucketName(occurrence) ]
    [#local publicAccessEnabled = false ]
    [#list solution.PublicAccess?values as publicPrefixConfiguration]
        [#if publicPrefixConfiguration.Enabled]
            [#local publicAccessEnabled = true ]
            [#break]
        [/#if]
    [/#list]

    [#assign componentState =
        {
            "Resources" : {
                "bucket" : {
                    "Id" : id,
                    "Name" :
                        firstContent(
                            getExistingReference(id, NAME_ATTRIBUTE_TYPE),
                            name),
                    "Type" : AWS_S3_RESOURCE_TYPE
                },
                "role" : {
                    "Id" : formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, core.Id ),
                    "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                    "IncludeInDeploymentState" : false
                },
                "bucketpolicy" : {
                        "Id" : formatResourceId(AWS_S3_BUCKET_POLICY_RESOURCE_TYPE, core.Id),
                        "Type" : AWS_S3_BUCKET_POLICY_RESOURCE_TYPE
                }
            },
            "Attributes" : {
                "NAME" : getExistingReference(id, NAME_ATTRIBUTE_TYPE),
                "FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
                "INTERNAL_FQDN" : getExistingReference(id, DNS_ATTRIBUTE_TYPE),
                "WEBSITE_URL" : getExistingReference(id, URL_ATTRIBUTE_TYPE),
                "ARN" : getExistingReference(id, ARN_ATTRIBUTE_TYPE),
                "REGION" : getExistingReference(id, REGION_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Inbound" : {
                    "invoke" : {
                        "Principal" : "s3.amazonaws.com",
                        "SourceArn" : getReference(id, ARN_ATTRIBUTE_TYPE)
                    }
                },
                "Outbound" : {
                    "all" : s3AllPermission(id),
                    "produce" : s3ProducePermission(id),
                    "consume" : s3ConsumePermission(id),
                    "replicadestination" : s3ReplicaDestinationPermission(id),
                    "replicasource" : {},
                    "datafeed" : s3KinesesStreamPermission(id)
               }
            }
        }
    ]
[/#macro]
