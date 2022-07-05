#!/usr/bin/env bash
#global variables
REPO_AUTH="https://$username:$token@$REPO_NAME"
#colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#set the correct java version based on the XVERSION config variable
IFS='.' read -ra v <<< "$XVERSION"

if [ ${v[0]} -gt 8 ]; then
	GVN="gvn8"
elif [ ${v[0]} -eq 8 ]; then
	if [ ${v[1]} -ge 1 ]; then
		GVN="gvn8"
	else
		GVN="gvn7"
	fi
else
	GVN="gvn7"
fi


init (){
sudo pwd
if ! command -v docker; then
	echo "Docker is not installed."
	prompt="Pick an action:"
	options=("Install docker")

	PS3="$prompt "

	select opt in "${options[@]}" "Cancel"; do

			case "$REPLY" in

			1 ) install_docker
					break;;

			$(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
			*) echo "Invalid option. Try another one.";continue;;

			esac

	done
fi
if  ! docker volume ls | [ "$(grep -c maven-repo)" -ge 1 ]; then
	echo "Creating docker volume..."
	docker volume create maven-repo
fi
if  ! docker images | [ "$(grep -c ${GVN})" -ge 1 ]; then
	echo "Creating docker gvn image..."
	if [[ "${GVN}" == 'gvn8' ]]; then
		docker build --tag ${GVN} docker_maver_363_jdk8_git
	else
		docker build --tag ${GVN} docker_maver_363_jdk7_git
	fi
fi
}

clone_repo (){
	if docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git clone $2; then
		sudo chown -R :docker $GIT_DIR
	else
		echo "Could not clone repository"
	fi
}
prepare (){
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git remote add upstream $2
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git fetch upstream --tags
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git checkout xwiki-platform-$XVERSION
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git checkout -b $BRANCH
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git pull $REPO_AUTH $BRANCH
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git fetch upstream
}
staging_modified_files (){
	mkdir modified_files &> /dev/null
	modified=$(status $CLONE_FOLDER | grep "modified:")
	while IFS= read -r line; do
		IFS=':' read -ra file <<< "$line"
		file_no_spaces="$(echo ${file[1]} | tr -cd "[:print:]\n" | xargs)"
		file_no_spaces=$(echo "${file_no_spaces/[m/''}")
		file_full_path="${CLONE_FOLDER}/${file_no_spaces}"
		file_name="$(basename $file_no_spaces)"
		file_og_path="$(dirname $file_no_spaces)"
		mkdir -p "${PWD}/modified_files/${file_og_path}"
		sudo ln -s ${file_full_path} ${PWD}/modified_files/${file_og_path}/$(basename $file_full_path)
	done <<< "$modified"
}
build (){
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} mvn clean install -Dmaven.test.skip=true -Dxwiki.revapi.skip=true
}
build_all (){
	if [ -z "$(ls -A ${GIT_DIR})" ]; then
		echo -e "No local repository found, try ${GREEN}make all${NC} or ${GREEN}make clone${NC} first."
	else
		for i in "${MODULES_TO_BUILD[@]}"
		do
			build "${GIT_DIR}/${i}" | tee run.out
			if grep -q "BUILD FAILURE" run.out; then
				echo "===================================================================================="
				echo "===================================================================================="
				echo -e "Building the ${BLUE}${GIT_DIR}/${i}${NC} module ${RED}failed${NC}"
				echo "Please fix the issue and then try the **make build** command to rebuild the modules."
				break
			fi
		done
		sudo rm run.out
		rename_and_extract_build
	fi
}
logs (){
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git log
}
cherry_pick (){
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git config user.email $email
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git config credential.username $username
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git cherry-pick -x $2
}
cherry_pick_continue (){
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git -c core.editor=true cherry-pick --continue
}
diff (){
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git diff
}
add_files (){
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git add .
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git commit -a
}
cherry_pick_abort (){
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git cherry-pick --abort
}
status (){
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git status
}
menu_option_continue (){
	echo "resuming..."
	add_files $CLONE_FOLDER
	cherry_pick_continue $CLONE_FOLDER
}
menu_option_abort (){
	echo "aborting cherry-pick..."
	cherry_pick_abort $CLONE_FOLDER
}
cherry-pick_menu (){
	title="Conflicts detected"
	prompt="Pick an action:"
	options=("CONTINUE (adds files and execute git cherry-pick --continue)" "SHOW DIFF" "SHOW STATUS" "ABORT" "ABORT & RESET")

	echo "$title"
	status $CLONE_FOLDER
	echo    "==================================================================================================================================================="
	echo -e "You can find the files that need attention in the ${GREEN}${PWD}/modified_files${NC} directory."
	echo -e "There you can modify or overwrite them to resolve the conflicts."
	echo    ""
	echo -e "The complete clone directory can be found in ${GREEN}${CLONE_FOLDER}${NC}"
	echo 		"if you need to add/delete/modify additional files"
	echo    "==================================================================================================================================================="
	PS3="$prompt "

	select opt in "${options[@]}" "Quit"; do

			case "$REPLY" in

			1 ) menu_option_continue
					break;;
			2 ) diff $CLONE_FOLDER;;
			3 ) status $CLONE_FOLDER;;
			4 ) menu_option_abort
					abort=1
					break;;
			5 ) menu_option_abort
					abort=1
					reset
					break;;

			$(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
			*) echo "Invalid option. Try another one.";continue;;

			esac

	done
}
cherry_pick_all (){
	abort=0
	for i in "${COMMITS_TO_CHERRYPICK[@]}"
	do
		if [[ "$abort" -eq 1 ]]; then
			break
		fi
		if cherry_pick $CLONE_FOLDER "$i" | grep -q "conflicts"; then
			staging_modified_files
			cherry-pick_menu
			#cherry_pick_abort $CLONE_FOLDER
		fi
		sudo rm -r $my_dir/modified_files &> /dev/null
	done
}
rename_and_extract_build (){
	mkdir ${BUILDS} &> /dev/null
	sudo rm ${BUILDS}/* &> /dev/null
	for i in "${MODULES_TO_BUILD[@]}"
	do
		packet=$(ls "${GIT_DIR}/${i}/target" | egrep '\.jar|\.xar')
		crtRev="$(sudo docker run -it --rm -v "$CLONE_FOLDER":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git rev-parse HEAD)"
		if echo "${packet}" | grep '.jar'; then
			replacer="-${BRANCH}-${crtRev}.jar"
			replacer=${replacer/$'\r'/}
			newPacketName="${packet/'.jar'/$replacer}"
		elif echo "${packet}" | grep '.xar'; then
			replacer="-${BRANCH}-${crtRev}.xar"
			replacer=${replacer/$'\r'/}
			newPacketName="${packet/'.xar'/$replacer}"
		fi
		sudo cp "${GIT_DIR}/${i}/target/$packet" "${BUILDS}/$newPacketName"
	done
}
push (){
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git add .
	sudo docker run -it --rm -v "$1":/usr/src/mymaven -v maven-repo:/root/.m2 -w /usr/src/mymaven ${GVN} git push $REPO_AUTH $BRANCH
}
init
