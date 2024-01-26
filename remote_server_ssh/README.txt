# REMOTE Server setup by SSH in linux (kali or others)

## Check ip on device

```
ifconfig
```

## We use service ssh. So if there is no this service u need to indtall it

```
sudo apt-get install openssh-server
```

P.S on kali it is default

## Check status of ssh service (with root rigths)

```
service ssh status
```
In default case status is disabled, so we have to start service:

```
service ssh start
```

U need to do this on both devices - server and PC

```
service ssh start
```


## Connection to remote

```
ssh server@192.168.0.180
```
to check that connect is ok:
```
uname -a
```

# FILE TRANSPORT BY SSH (scp)




