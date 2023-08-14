#!/bin/sh

# Récupère une version spécifique des sources Bookwyrm
# permet de comparer les fichiers de dépendances et déploiement
# ex pour dépendances python :
#   ./fetchUpstreamCode.sh
#   cp requirements.txt doc/requirements_v0.6.3.txt
#   diff docs/requirements_v0.6.2.txt docs/requirements_v0.6.3.txt
# pour évolutions déploiement :
#   meld upstream_0.6.2/deploy/ upstream_0.6.3/deploy/

VERSION=$1 # ex: v0.6.3 (tag)
REPO_PATH="./upstream_$VERSION/"

[ ! -d $REPO_PATH ] && git clone https://github.com/bookwyrm-social/bookwyrm.git $REPO_PATH
cd $REPO_PATH

# echo "Fetching develop commit for $VERSION"
# git checkout develop && git pull
# COMMIT=$(git log --reverse --ancestry-path $VERSION..develop --oneline | head -1 | awk '{print $1}')
# echo $COMMIT
git checkout $VERSION

# affiche les versions des packages python
# cat requirements.txt
cd -
