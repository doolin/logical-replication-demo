# shellcheck shell=bash

source ./scripts/utils/ansi_colors.sh

press_enter()
{
  read -rp "${redf}Press [Enter]...${reset}"
}

infotext()
{
  printf "${cyanf}%s${reset}\n" "$1"

  if [[ -n $2 ]];
  then
    echo "    $ ${purplef}$2${reset}"
  fi
}

marquee()
{
  echo -e "${redblink}$1${reset}"
}

# clear the screen
cls()
{
  printf "\033c"
}

# Possibly move these to their own file with
# other useful variables.
upstream_dir=/tmp/upstream
downstream_dir=/tmp/downstream

remove_tmp_directories()
{
  if [ -e $upstream_dir ]
  then
    rm -rf $upstream_dir
  fi

  if [ -e $downstream_dir ]
  then
    rm -rf $downstream_dir
  fi
}

check_for_upstream()
{
  if [[ ! "$PWD" =~ $upstream_dir ]]
  then
    echo "Not in correct upstream"
    exit 1
  else
    echo "We're in ${upstream_dir}, set up is done"
  fi
}
