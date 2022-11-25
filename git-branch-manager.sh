#!/bin/sh

#arguments are positional... $1 is the first $2 is the second etc...

git_color_text() {
	text=$1
	gum style --foreground 212 "$text"
}

get_branches() {
  if [ ${1+x} ]; then
    gum choose --limit "$1" $(git branch --format="%(refname:short)") ##This works in pwsh get git branch | gum
  else
    gum choose --no-limit $(git branch --format="%(refname:short)") ##This works in pwsh get git branch | gum
  fi
}

gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin "1 2" --padding "2 4" "$(git_color_text " Git") Branch Manager"

echo "Choose $(git_color_text "branches") to operate on: "
branches=$(get_branches)

echo ""
echo "Choose a $(git_color_text "command":): "
command=$(gum choose rebase delete update)
echo ""

echo $branches | tr " " "\n" | while read branch
do

  case $command in
    rebase)
	    base_branch=$(get_branches 1 )
	    git fetch origin
	    git checkout "$branch"
	    git rebase "origin/$base_branch"
	    echo "rebasing $branch"
      	    ;;
    delete)
	    git branch -D "$branch"
	    echo "deleting $branch"

            ;;
    update)
	    git checkout "$branch"
	    git pull --ff-only 
	    echo "updating $branch"
            ;;
  esac
done







