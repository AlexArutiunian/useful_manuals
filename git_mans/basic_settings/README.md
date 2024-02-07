# Basic settings

## [Great video](https://youtu.be/R09UNc4ZNi4?si=ZwznyfC_MHfpK_FF)

## ssh generation
```
cd ~/.ssh
ssh-keygen -t ed25519 -C "arutunanalexandr17@gmail.com"
```
```
cat id_ed25519.pub

ssh-add ~/.ssh/id_ed25519
 ```
P.S. insted of id_ed25519 (default name) u can setup ur own name for these files (pub and with no .x)
## add key on github website

by [instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

## Say hello to git@github
```
git config --global user.name "AlexArutiunian"
git config --global user.email "arutunanalexandr17@gmail.com"
```
## Check the results
```
ssh -T git@github.com
```
```
ssh-add ~/.ssh/id_ed25519
```
```
ssh -T git@github.com
```
## P.S. if there is the problem as RermissionDenied when trying to git commands after reload new linux-session, do:
```
ssh-add ~/.ssh/id_ed25519
```
OR FILE in which u saved pubkey 
