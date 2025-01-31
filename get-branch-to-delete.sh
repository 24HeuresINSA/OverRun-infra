#!/usr/bin/env bash

# Se script perme de récupérer les branches à supprimer a partir
# des MR qui sont fermés, notamment les branches lié au depandabot.
# Pour chaque branch, la suppression doit etre confirmé par l'utilisateur.

NC='\033[0m' # No Color
BLUE='\033[0;34m'


# Get all closed and merged MRs from dependabot 
CLOSED_MR=$(curl --silent --location --request GET 'https://gitlab.com/api/v4/projects/24-heures-insa%2Foverrun%2Fbackend/merge_requests?state=closed&labels=dependencies&per_page=100&order_by=updated_at')

# Filter json object to get only the source branch name

BRANCHES=$(echo $CLOSED_MR | jq -r '.[] | .source_branch')

TO_DELETE_BRANCHES=""

for branch in $BRANCHES;
do
    isRemoteBranchExist=$([[ -z $(git ls-remote --heads origin $branch) ]] && echo false  || echo true )
    if [ $isRemoteBranchExist = true ]; then
        echo -e "${BLUE}Going to delete ${branch}${NC}"

        read -p "Do you want to proceed? (y/n) " yn

        case $yn in 
            [yY]es | [yY] )
                TO_DELETE_BRANCHES="${TO_DELETE_BRANCHES} ${branch}"
                continue;;
            [nN]o | [nN] ) 
                echo "Continue verification..."
                continue;;
            * ) 
            echo "Invalid response"
            ;;
        esac
    else
        break
    fi
done

echo About to delete: $TO_DELETE_BRANCHES

for branch in $TO_DELETE_BRANCHES;
do
    git push origin --delete $branch
done

exit 1
