#! /usr/bin/env bash
CWD=$PWD
source_branch=dev-looker-support-jxtz
target_branch=dev-looker-support-9nrv
# Download repos if they don't exist
if [ ! -d "inventory-analytics" ]; then
    echo -e " "
    git clone https://github.com/turnercode/inventory-analytics.git
fi
if [ ! -d "rev-analytics-prod" ]; then
    echo -e " "
    git clone https://github.com/turnercode/rev-analytics-prod.git
fi
get_diff(){
    
    # Check for changes
    echo -e "Fech any updates from both repositories"
    cd $CWD/inventory-analytics/; git checkout ${source_branch}; git pull;
    cd $CWD/rev-analytics-prod/; git checkout ${target_branch}; git pull;
    # Push selected changes from Development to Production
    echo -e "\nDetermining changes between repos:"
    cd $CWD/rev-analytics-prod/
    git checkout ${target_branch}
    git remote add -f inventory-analytics https://github.com/turnercode/inventory-analytics.git
    git remote update
    echo -e "\n\n\nFile differences between inventory-analytics and rev-analytics-prod repos"
    git diff --name-only ${target_branch} remotes/inventory-analytics/${source_branch}
}
get_diff_file(){
    # Check for changes
    echo -e "Fech any updates from both repositories"
    cd $CWD/inventory-analytics/; git checkout ${source_branch}; git pull;
    cd $CWD/rev-analytics-prod/; git checkout ${target_branch}; git pull;
    # Push selected changes from Development to Production
    echo -e "\nDetermining changes between repos:"
    cd $CWD/rev-analytics-prod/
    git checkout ${target_branch}
    git remote add -f inventory-analytics https://github.com/turnercode/inventory-analytics.git
    git remote update
    echo -e "\n\n\nFile differences between inventory-analytics and rev-analytics-prod repos"
    echo -e "file: $1"
    git diff ${target_branch} remotes/inventory-analytics/${source_branch} -- "$1" 
    
}
while test $# -gt 0; do
        case "$1" in
                -h|--help)
                    echo "push_dev_to_prod - Update repos locally and update Looker via webhook"
                    echo " "
            echo "Usage:"
                    echo "push_dev_to_prod_repos [options]"
                    echo " "
                    echo "options:"
                    echo "-h, --help                    Show brief help"
            echo "--diff                        Show repo differences"
                    echo "--update-file <file-name>     LookML file to transfer locally from Dev to Production"
            echo "--push-to-prod                Update production Looker server repo to capture changes"
            echo "--reset                       Remove local repos and hence changes"
                    exit 0
                    ;;
        --diff)
            shift
            get_diff
            exit 0
            ;;
        --diff-file)
            shift
            get_diff_file $1
            exit 0
            ;;
        --update-file)
                    shift
                    if test $# -gt 0; then
            echo -e "Transferring file $1"
            cp ${CWD}/inventory-analytics/$1 ${CWD}/rev-analytics-prod/.
            exit 0
                    else
                        echo -e "\nERROR:  No LookML file specified"
                        exit 1
                    fi
                    shift
                    ;;
        --push-to-prod)
            shift
            echo -e "Updating Looker production server..."
            cd $CWD/rev-analytics-prod/
            git add -A && git commit -m "Pushing changes by user ${USER}"
            git push origin ${target_branch}
            curl https://looker.turner.com/webhooks/projects/prod_inventory_analytics/deploy
            echo -e "\n"
            exit 0
            ;;
        --reset)
            shift
            echo -e "Resetting and removing all changes..."
            rm -rf ${CWD}/inventory-analytics/
            rm -rf ${CWD}/rev-analytics-prod/
            exit 0
            ;;
        *)
            break
            ;;
    esac
done
