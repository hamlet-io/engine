[#ftl]

[@addTask
    type=SSH_COPY_FILE_TASK_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Copy a file between the local host and a remote ssh host"
            }
        ]
    attributes=[
        {
            "Names" : "Host",
            "Description" : "The IP or Hostname of the remote host",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Port",
            "Description" : "The port number the host is listening on for ssh connections",
            "Types" : NUMBER_TYPE,
            "Default" : 22
        },
        {
            "Names" : "Username",
            "Description" : "The username on the remote host",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Password",
            "Description" : "The password for the username on the remote host",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "SSHKey",
            "Description" : "The path or content of an ssh private key to use for authentication",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Direction",
            "Description" : "The direction to copy the file",
            "Values" : [ "RemoteToLocal", "LocalToRemote" ],
            "Mandatory" : true
        },
        {
            "Names" : "LocalPath",
            "Description" : "The path to the local file",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "RemotePath",
            "Description" : "The path to the remote file",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
/]
