# Basic settings

## ssh generation

cd ~/.ssh
ssh-keygen -t ed25519 -C "arutunanalexandr17@gmail.com"

cat id_ed25519.pub

ssh-add ~/.ssh/git_ssh
 
## add key on github website

by [instructions]()

## Say hello to git@github

git config --global user.name "AlexArutiunian"
git config --global user.email "arutunanalexandr17@gmail.com"

## Check the results

ssh -T git@github.com

## P.S. if there is the problem as RermissionDenied when trying to git commans, do:

ssh-add ~/.ssh/id_ed25519

OR FILE in which u saved pubkey 
