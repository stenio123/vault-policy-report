# vault-policy-report

Lists which policies contain a specific string, and then lists which users/entities are associated with those policies.

This script will allow a Vault admin to identify the users that are associated with policies that contain permissions to a certain path.

For example, if you want to find out the users that potentially have permission to create or alter Vault ACL policies, you can use "sys/policy" as the parameter when calling the script.

## Requirements
- A Vault server initialized, unsealed and configured
- Properly set $VAULT_ADDR and $VAULT_TOKEN environment vars
- vault client 
- jq, a json parsing utility

## Running
On a terminal, execute:
```
$ vault-policy-report.sh <STRING TO SEARCH>
```

The parameter <STRING TO SEARCH> could be something like "sys/policy" if you want to ultimately list all the users that have permissions to interact with that particular endpoint.

## TODO
Implement additional authentication methods:
- AppRole (done)
- Userpass (done)
- Kubernetes
- AWS
- Azure
...
