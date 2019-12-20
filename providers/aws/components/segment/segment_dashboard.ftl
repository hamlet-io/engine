[#ftl]
[#macro aws_dashboard_cf_genplan_segment occurrence ]
    [@addDefaultGenerationPlan subsets="template" /]
[/#macro]

[#macro aws_dashboard_cf_setup_segment occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#if deploymentSubsetRequired("dashboard", true)]
        [@createDashboard
            id=formatSegmentCWDashboardId()
            name=formatSegmentFullName()
            components=dashboardComponents
        /]
    [/#if]
[/#macro]
