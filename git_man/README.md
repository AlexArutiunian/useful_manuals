#Basic settings

##ssh generation

cd ~/.ssh
ssh-keygen -t ed25519 -C "arutunanalexandr17@gmail.com"

cat id_ed25519.pub

##add key on github website

by [instructions]()

##Say hello to git@github

git config --global user.name "AlexArutiunian"
git config --global user.email "arutunanalexandr17@gmail.com"

##Check the results

ssh -T git@github.com

