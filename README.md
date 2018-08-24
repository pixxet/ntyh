# Never touch your local /etc/hosts file in OS X again

> To setup your mac to work with *.test domains, e.g. project.test, awesome.test and so on, without having to add to your hosts file each time. (Inspired by https://alanthing.com/blog/2012/04/24/never-touch-your-local-etchosts-file-os-x-again/)

## Requirements

* [Homebrew](https://brew.sh/)
* Mountain Lion -> High Sierra

## How to?
```
./nyth.sh
```

### Or with given domain name
```
./nyth.sh -d domain
```

### Remove already added domain name
```
./nyth.sh -r domain
```

### For help
```
sudo ./add-dnsmasq-domain -h
```


### Setup

#### Create config directory
```
mkdir -pv $(brew --prefix)/etc/
```


## Setup manually

### Install
```
brew install dnsmasq
```

### Setup

#### Create config directory
```
mkdir -pv $(brew --prefix)/etc/
```

#### Setup *.dev
```
echo 'address=/.test/127.0.0.1' >> $(brew --prefix)/etc/dnsmasq.conf
```
#### Change port for High Sierra
```
echo 'port=53' >> $(brew --prefix)/etc/dnsmasq.conf
```

### Autostart - now and after reboot
```
sudo brew services start dnsmasq
```

### Add to resolvers

#### Create resolver directory
```
sudo mkdir -v /etc/resolver
```

#### Add your nameserver to resolvers
```
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/test'
```

That's it! You can run scutil --dns to show all of your current resolvers, and you should see that all requests for a domain ending in .dev will go to the DNS server at 127.0.0.1

## Finished
