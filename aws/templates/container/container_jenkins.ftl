[#case "jenkins-master"]
    [@Attributes image="jenkins-master" /]

    [#assign adminCredentials = 
                (credentialsObject[formatComponentShortName(
                                    tier,
                                    component,
                                    containerId)])!""]
    [#if adminCredentials?has_content]
        [@Variables
            {
                "JENKINS_USER" : adminCredentials.Login.Username,
                "JENKINS_PASS" : adminCredentials.Login.Password
            }
        /]
    [#else]
        [@Variables
            {
                "JENKINS_USER" : "admin",
                "JENKINS_PASS" : "changeme"
            }
        /]
    [/#if]
    
    [@Volume "jenkinsdata" "/var/jenkins_home" "/efs/clusterstorage/jenkins" /]

    [#break]