#!/bin/bash

# Never touch your local /etc/hosts file in OS X again
# To setup your mac to work with *.test domains, e.g. project.test, awesome.test and so on,
# without having to add to your hosts file each time.

## Constants
RED='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

## Functions

add()
{
    printf "\nNever touch your local /etc/hosts file in OS X again\n\n"
    dnsmasqConfigurationsChanged=false

    ### Install dnsmasq if missing
    if [[ ! $(brew ls --versions dnsmasq) ]]; then
        printf "${RED}Installing dnsmasq...${NC}\n"
        brew install dnsmasq
        printf "${GREEN}Done installing dnsmasq${NC}\n"
    else
        printf "${GREEN}dnsmasq is already installed.${NC}\n"
    fi

    ### Create config directory if missing
    if [[ ! -d $(brew --prefix)/etc/ ]]; then
        printf "${RED}Creating config directory...${NC}\n"
        mkdir -pv $(brew --prefix)/etc/
        dnsmasqConfigurationsChanged=true;
        printf "${GREEN}Created config directory.${NC}\n"
    else
        printf "${GREEN}Config directory exists already!!${NC}\n"
    fi

    if [ -z "$domain" ]; then
        printf "\nPlease enter the domain you want to add: "
        read domain
        printf "\n"
    fi

    ### Setup *.domain
    if [[ ! $(grep "address=/.$domain/127.0.0.1" $(brew --prefix)/etc/dnsmasq.conf) ]]; then
        printf "${RED}Adding the domain \"$domain\" to dnsmasq configurations...${NC}\n"
        echo "address=/.$domain/127.0.0.1" >> $(brew --prefix)/etc/dnsmasq.conf
        dnsmasqConfigurationsChanged=true;
        printf "${GREEN}The domain \"$domain\" was added to dnsmasq configurations.${NC}\n"
    else
        printf "${GREEN}The domain \"$domain\" is already found in dnsmasq configurations!${NC}\n"
    fi

    ### Change port for High Sierra
    if [[ ! $(grep 'port=53' $(brew --prefix)/etc/dnsmasq.conf) ]]; then
        printf "${RED}Adding the port \"53\" to dnsmasq configurations...${NC}\n"
        echo 'port=53' >> $(brew --prefix)/etc/dnsmasq.conf
        dnsmasqConfigurationsChanged=true;
        printf "${GREEN}The port \"53\" was added to dnsmasq configurations.${NC}\n"
    else
        printf "${GREEN}The port \"53\" is already found in dnsmasq configurations!${NC}\n"
    fi

    ### Autostart - now and after reboot if not se
    if (ps cax | grep dnsmasq > /dev/null ) && [ ! $? -eq 0 ]; then
        printf "${RED}Starting the service \"dnsmasq\" now...${NC}\n"
        sudo brew services start dnsmasq
        printf "${GREEN}The service \"dnsmasq\" was started and will autostart after reboot.${NC}\n"
    else
        $dnsmasqConfigurationsChanged && sudo brew services restart dnsmasq
        printf "${GREEN}The service \"dnsmasq\" is already running!${NC}\n"
    fi

    ### Add to resolvers
    #### Create resolver directory
    if [[ ! -d /etc/resolver ]]; then
        printf "${RED}Creating resolver directory...${NC}\n"
        sudo mkdir -v /etc/resolver
        printf "${GREEN}Created resolver directory.${NC}\n"
    else
        printf "${GREEN}Resolver directory exists already!${NC}\n"
    fi

    #### Add nameserver to resolvers
    if [[ ! -f /etc/resolver/$domain || $(< /etc/resolver/$domain) != 'nameserver 127.0.0.1' ]]; then
        printf "${RED}Adding the nameserver $domain to resolvers...${NC}\n"
        echo 'nameserver 127.0.0.1' | sudo tee "/etc/resolver/$domain" > /dev/null
        printf "${GREEN}The namserver $domain was added to resolvers!${NC}\n"
    else
        printf "${GREEN}The namserver $domain is already added to resolvers!${NC}\n"
    fi

    [[ ! $(brew ls --versions pcre) ]] && sudo brew install pcre

    printf "\n${YELLOW}"
    sleep 1
    pcregrep -Mi "resolver\s\#[0-9]+\n\s+domain\s+\:\s$domain\n\s+nameserver.*\n\s+flags.*\s+reach.*" <(scutil --dns)
    
    printf "\n${GREEN}"
    ping -c 1 thereisnowaythisisarealdomain.test
    printf "${NC}\n"
}

remove() {
    dnsmasqConfigurationsChanged=false
    printf "\n${RED}Removing *.$domain${NC} local domains\n\n"

    #### Removes nameserver from resolvers
    if [[ -f /etc/resolver/$domain ]]; then
        printf "${RED}Removing the nameserver $domain from resolvers...${NC}\n"
        sudo rm -rf "/etc/resolver/$domain"
        printf "${GREEN}The namserver $domain was removed from resolvers!${NC}\n"
    else
        printf "${GREEN}The namserver $domain dosn't exist in resolvers!${NC}\n"
    fi

    ### Remove *.domain
    if [[ $(grep "address=/.$domain/127.0.0.1" $(brew --prefix)/etc/dnsmasq.conf) ]]; then
        printf "${RED}Removing the domain \"$domain\" from dnsmasq configurations...${NC}\n"
        sed -i '' "/address=\/\.$domain\/127\.0\.0\.1/d" $(brew --prefix)/etc/dnsmasq.conf
        dnsmasqConfigurationsChanged=true;
        printf "${GREEN}The domain \"$domain\" was removed from dnsmasq configurations.${NC}\n"
    else
        printf "${GREEN}The domain \"$domain\" is already removed from dnsmasq configurations!${NC}\n"
    fi
    
    $dnsmasqConfigurationsChanged && sudo brew services restart dnsmasq

    printf "\n${YELLOW}Use \"sudo brew services stop dnsmasq\" to stop dnsmasq service completly!${NC}\n"
    printf "${YELLOW}Use \"brew uninstall dnsmasq --force\" to uninstall dnsmasq entirly from your mac!${NC}\n\n"
}

usage()
{
    echo "usage:"
    printf "\n${GREEN}    ./add-dnsmasq-domain.sh [[[-d domain ] [-r domain]] | [-h]]${NC}\n\n"
    printf "${YELLOW}"
    printf "    -d domain: Adds the domain to your local nameserver\n"
    printf "    -r domain: Removes the domain from your local nameserver\n"
    printf "${NC}\n"
}

while [ "$1" != "" ]; do
    case $1 in
        -d | --domain )         shift
                                domain=$1
                                add
                                exit
                                ;;
        -r | --remove )         shift
                                domain=$1
                                remove
                                exit
                                ;;    
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

usage
exit 1
