# Clean history to reduce size of your repo

Check hash of a commit after that u want to delete history

```
git log --oneline

```

Update history on github server

```
git push -f origin COMMIT_ID:main

```

And update hist on local device:

```
git reser --hard origin COMMIT_ID

```

This approach helps to reduce size of git repo

I used this for it
