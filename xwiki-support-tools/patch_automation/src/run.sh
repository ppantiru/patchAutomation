#!/usr/bin/env bash
#This script currently works only for xwiki versions that use java 7 or 8
#Support for earlier version coming soon
#config file
my_dir="$(dirname "$0")"
. "$my_dir/vars.config"
. "$my_dir/docker_unix_installer.sh"
. "$my_dir/run_module.sh"
####
##Makefile functions
run_all (){
init
abort=0
if [ -z "$(ls -A ${GIT_DIR})" ]; then
   clone
fi
prepare $CLONE_FOLDER $UPSTREAM
cherry_pick_all
if [[ "$abort" -eq 0 ]]; then
  build_all
  rename_and_extract_build
fi
}
clone (){
	clone_repo $GIT_DIR $REPO_AUTH
	memFolder="${CLONE_FOLDER}-clean"
	sudo cp -r $CLONE_FOLDER ${memFolder}
	USER=$(stat -c '%U'  ${CLONE_FOLDER})
	GROUP=$(stat -c '%G'  ${CLONE_FOLDER})
	sudo chown $USER:$GROUP -R ${memFolder}
}
co_branch (){
  if [ -z "$(ls -A ${GIT_DIR})" ]; then
    echo -e "No local repository found, try ${GREEN}make all${NC} or ${GREEN}make clone${NC} first."
  else
    prepare $CLONE_FOLDER $UPSTREAM
  fi
}
cherry-pick (){
  if [ -z "$(ls -A ${GIT_DIR})" ]; then
    echo -e "No local repository found, try ${GREEN}make all${NC} or ${GREEN}make clone${NC} first."
  else
    cherry_pick_all
  fi
}
push_to_remote (){
  if [ -z "$(ls -A ${GIT_DIR})" ]; then
    echo -e "No local repository found, try ${GREEN}make all${NC} or ${GREEN}make clone${NC} first."
  else
    push $CLONE_FOLDER
  fi
}
git_logs (){
  if [ -z "$(ls -A ${GIT_DIR})" ]; then
    echo -e "No local repository found, try ${GREEN}make all${NC} or ${GREEN}make clone${NC} first."
  else
    logs $CLONE_FOLDER
  fi
}
reset (){
  if [ -z "$(ls -A ${GIT_DIR})" ]; then
    echo -e "No local repository found, try ${GREEN}make all${NC} or ${GREEN}make clone${NC} first."
  else
    sudo rm -r $CLONE_FOLDER
    memFolder="${CLONE_FOLDER}-clean"
    sudo cp -r ${memFolder} $CLONE_FOLDER
    USER=$(stat -c '%U'  ${memFolder})
	  GROUP=$(stat -c '%G'  ${memFolder})
    sudo chown $USER:$GROUP -R ${CLONE_FOLDER}
    sudo rm -r modified_files &> /dev/null
    echo "The working directory has been reset to the initial clone state."
  fi
}
make_status (){
  if [ -z "$(ls -A ${GIT_DIR})" ]; then
    echo -e "No local repository found, try ${GREEN}make all${NC} or ${GREEN}make clone${NC} first."
  else
    status $CLONE_FOLDER
  fi
}
make_abort (){
  if [ -z "$(ls -A ${GIT_DIR})" ]; then
    echo -e "No local repository found, try ${GREEN}make all${NC} or ${GREEN}make clone${NC} first."
  else
    cherry_pick_abort $CLONE_FOLDER
  fi
}
make_purge (){
  sudo rm -r ${GIT_DIR} &> /dev/null
	sudo rm -r ${BUILDS} &> /dev/null
  echo "Starting from scratch".
}
####
#Testing area
tests (){
	echo "Testing:"
	echo -e "No ${GREEN}tests ${NC}to run."
}
#cherry_pick $CLONE_FOLDER $COMMIT
#build $MODULE_OLDCORE
#cherry_pick_continue $CLONE_FOLDER -F
#cherry_pick_abort $CLONE_FOLDER

#push $CLONE_FOLDER
#logs $CLONE_FOLDER
"$@"

if [[ $# -eq 0 ]] ; then
		echo -e "Pleas use the ${GREEN}make commands${NC}"
		cat ../README.md
    exit 0
fi
