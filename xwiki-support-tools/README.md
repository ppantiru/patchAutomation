# XWiki Support Tools
## Patch automation
	
1. Prerequisites:
- Unix environment
- Docker (installer included)
- Github Personal access tokens
  - To obtain a Personal access tokens, go to https://github.com/ and login, then click on your profile image in the upper right corner and from the drop-down menu select **Settings**, then click on **Developer settings** from the left panel and then on **Personal access token**. Click on **Generate new token** button and insert your password. Now give your token a suggestive name and check the repo box. Finally click the green **Generate token** button and save you token somewere safe.

2. Usage
- Clone or download the repository
- Go into the *xwiki-support-tools/patch_automation* diectory
- Edit the *vars.config* file accordingly
    - on the first line add you actual github username (**username="[your github username]"** should become something like **username="ppantiru"**)
    - on the second line add your github **Personal access token**
    - the variable that follow are dependent on the patch you are trying to make and are as follows (should be modified accordingly):
        - REPO_NAME - the target repository that will be cloned and we'll be working on
        - XVERSION - the version of xwiki you are aiming to do the patch for
        - BRANCH - the branch on which the commits will be pushed on, if it does not exist, a new one will be created
        - GIT_DIR - the local directory in whihc the target repository will be cloned in (default value: **"${PWD}/repos"** - means it will be the in the reops directory located in the same place as the script)
        - CLONE_FOLDER - the target repository's directory (should be deduced from the *REPO\_NAME* variable )
        - UPSTREAM - the repository from where the commits will be cherry-picked
        - MODULES\_TO\_BUILD - the list of modules you want to build
        - COMMITS\_TO\_CHERRYPICK - the list of commits that constitue your patch
- From command line **cd** in the *patch_automation* directory where you can use the floowing commands:
	- **make reset** - resets the repository to the state just after a fresh clone ( back on the master branch )
	- **make all** - checks your dependcies and based on your config file it will clone the repository, add the remote upstream, fetch the upstream tags, checkout the version of xwiki, checkout the mentioned branch, pull the lates head form that branch, cherry-pick the commits specified in the config file, and build the modules also specified in the config file, estract the packeges created from the built modules (*note* this will not push to remote)
	- **make clone** - clones the repository declared in the config file
	- **make branch** - switches to the branch declared in the config file and if the branch exists pulls the content otherwise creates a new branch 
	- **make cherry-pick** - executes a cherry-pick for each commit declared in your config file
	- **make abort** - aborts current cherry-pick if it was not commited (if it it had conflicts)
	- **make build** - builds the modules specified in the config file and extract the packeges from the built modules in the builds directory
	- **make push** - pushes whatever commits you have in the local repository to the remote brached
	- **make status** - equivalent to *git status* command for the cloned repository
	- **make logs** - equivalent to *git logs* for the cloned repository
	- **make purge** - empties the *repos* and the *build* directories

- The builds will be automatically extracted from the specified module in the *builds* directory after a successful build
