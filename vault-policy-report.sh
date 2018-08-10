#!/usr/bin/env bash

# This script will query Vault to:
# 1 - Identify the ACL policies that contain a certain string. For example, if you want to identify
# the policies with permissions to interact with Vault ACL policies (create, update, etc), you could search
# for 'sys/policy'.
#
# 2 - Identify the users in the different authentication methods that are associated with the policies
# found on step 1.
#
# Example on how to run this script:
# $ vault-policy-report.sh sys/policy

# This will hold the string you want to search in the policies
TARGET_STRING=$1

if [ -z "$VAULT_ADDR" ]; then
    echo "Please set the \$VAULT_ADDR environment variable with your Vault address."
    exit 1
fi  

if [ -z "$VAULT_TOKEN" ]; then
    echo "Please set the \$VAULT_TOKEN environment variable with a Vault token with sufficient permissions."
    exit 1
fi  

if ! [ -x "$(command -v vault)" ]; then
  echo 'Error: vault client is not installed. Please download it from https://www.vaultproject.io/downloads.html' >&2
  exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed. Please download this json parser from https://stedolan.github.io/jq/download/' >&2
  exit 1
fi

##
# This function lists objects and then reads each one, trying to find the specifyied string.
# It is used to find the policies that have the string, and then the users that have those policies.
# Parameters:
# $1: Name of what is being searched. Example: policies, appRole
# $2: Path to check string. Example: auth/approle/role, sys/policy
# $3: String to find. Example: the policy name (admin-policy), a string in the policy (sys/policy)
# $4: Reference to an external array that will store results, since bash and passing by reference is ?
##
ARRAY_RESULT=()
check_StringExists () {
  #echo "Retrieving list of $1 ..."
  LIST=$(vault list -format=json $2)

  #echo "Retrieving quantity of $1 ..."
  QTY=$(echo $LIST | jq . | jq length)

  COUNTER=0
  
  #echo "Identifying which $1 have $3 ..."
  while [  $COUNTER -lt $QTY ]; do
    ITEM_NAME=$(echo $LIST | jq -r .[$COUNTER])
    PERMISSIONS=$(vault read -format=json $2/$ITEM_NAME) 

    case "$PERMISSIONS" in 
      *"$3"* ) ARRAY_RESULT+=($ITEM_NAME);;
      * ) ;;
    esac

    let COUNTER++
  done
  # echo "All $1 found: $LIST" 
}

### POLICIES
echo " "
echo "============= Listing policies that contain $TARGET_STRING:"
echo " "
# Retrieves admin policies:
check_StringExists "policies" "sys/policy" "$TARGET_STRING" 

if [ -z $ARRAY_RESULT ]; then
  echo "No policies exist with permissions to '$TARGET_STRING', exiting application."
  exit 0
else
  echo "The following policies have '$TARGET_STRING' permissions:" 
  echo "        ${ARRAY_RESULT[@]}"
  echo " "
  echo "This means that if '$TARGET_STRING' refers to admin privileges, any users associated with these policies can be considered admin users."
fi

# Stores the list of Admin policies
ARRAY_ADMIN_POLICIES=(${ARRAY_RESULT[@]})

### APPROLE
echo " "
echo "============= Verifying AppRole:"
echo " "
# Clears up old results
ARRAY_RESULT=()
ADMIN_QTY=$(echo ${#ARRAY_ADMIN_POLICIES[@]})
COUNT=0
# Check which AppRole users are associated with admin policies:
while [[ $COUNT -lt $ADMIN_QTY ]]; do
  check_StringExists "appRole" "auth/approle/role" "${ARRAY_ADMIN_POLICIES[COUNT]}"
  if [ -z $ARRAY_RESULT ]; then
    echo " "
    echo "No roles exist associated with policy '${ARRAY_ADMIN_POLICIES[COUNT]}'."
  else
    echo " "
    echo "The following roles are associated with policy '${ARRAY_ADMIN_POLICIES[COUNT]}':  "
    echo "        ${ARRAY_RESULT[@]}"
  fi
  ARRAY_RESULT=()
  let COUNT++
done

### USERPASS
echo " "
echo "============= Verifying UserPass:"
echo " "
# Clears up old results
ARRAY_RESULT=()
ADMIN_QTY=$(echo ${#ARRAY_ADMIN_POLICIES[@]})
COUNT=0
# Check which UserPass users are associated with admin policies:
while [ $COUNT -lt $ADMIN_QTY ]; do
  check_StringExists "userpass" "auth/userpass/users" "${ARRAY_ADMIN_POLICIES[COUNT]}"
  if [ -z $ARRAY_RESULT ]; then
    echo " "
    echo "No users exist associated with policy '${ARRAY_ADMIN_POLICIES[COUNT]}'."
  else
    echo " "
    echo "The following users are associated with policy '${ARRAY_ADMIN_POLICIES[COUNT]}': "
    echo "        ${ARRAY_RESULT[@]}"
  fi
  ARRAY_RESULT=()
  let COUNT++
done