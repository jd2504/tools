#!/bin/bash
#
# update git rev analytics prod repo and update remote branches for code review
# latest update: jd, 20180205
#
# READ: if another user is using this script, change parent and documents folder variables to /Users/<your user name>/...
#

read -d '' git_usage <<- EOF

    Usage: source target

    Defaulting SOURCE branch to dev-looker-support-jxtz on inventory_analytics repo...
    Defaulting TARGET branch to master on rev-analytics-prod repo...

EOF

if [ $# -ne 2 ]
then
    echo "$git_usage"
    #
    # default source and target assignments
    #
    source=dev-looker-support-jxtz
    target=master
else
    #
    # assign source and target to user defined
    source=$1
    target=$2
fi

#
# folder assignments
#
parent_folder=/Users/jdeerwester/code/
documents_folder=/Users/jdeerwester/Documents/
target_folder=rev-analytics-prod/
source_folder=inventory_analytics/

cd $parent_folder$target_folder

if [ -d $target_folder ]
then
    echo -e "\nFolder $target_folder exists. Replace and refresh existing local $target_folder repo."
    read -p "Continue? [y]|[n]..." del
    if [ $del -ne "y" ]
	echo "Exiting..."
	exit
    fi
fi

rm -rf $target_folder
echo -e "$target_folder removed"
echo -e "\nCloning latest version of rev-analytics-prod repo from Github..."
git clone https://github.com/turnercode/rev-analytics-prod.git

cd $target_folder
echo -e "\nAdding $source_folder source branch to remote dev"
git remote add dev https://github.com/turnercode/inventory-analytics -t $source
git remote update

echo -e "\nGit repo updates complete...\n"

# while true
# do
#     read -p "Perform git diff on FILE (git diff $target $source <FILE>), 0 to exit: " diff_file
#     if [ "$diff_file" = 0 ]
#     then
# 	break
#     else
# 	lines=$(git diff $target remotes/b/$source *$diff_file* | wc -l)
# 	printf "Files:\n"
# 	ls | grep $diff_file
# 	printf "\n"

# 	ndims=$(grep '\+ *dimension' *$diff_file* | wc -l)
# 	nmeas=$(grep '\+ *measure' *$diff_file* | wc -l)
# 	nfilt=$(grep '\+ *filter' *$diff_file* | wc -l)
# 	printf "Dimensions added (excl commented) : %s" "$ndims"
# 	printf "Measures added (excl commented)   : %s" "$nmeas"
# 	printf "Filters added (excl commented)    : %s" "$nfilt"
# 	printf "%s diff contains %s lines..." "$diff_file" "$lines"
# 	read -p "Continue? [y]|[n]..." breakdiff
# 	if [ $breakdiff="n" ]
# 	then
# 	    continue
# 	elif [ $breakdiff="y" ]
# 	then
# 	    git diff $target remotes/b/$source *$diff_file*
# 	else
# 	    printf "Invalid input...\n"
# 	    continue
# 	fi
#     fi
# done
