#!/bin/bash

# Set program version
BR_VERSION="System Tar & Restore 6.0"

# Set EFI detection directory
BR_EFI_DETECT_DIR="/sys/firmware/efi"

# Set some colors
color_variables() {
  NORM='\e[00m'
  RED='\e[00;31m'
  GREEN='\e[00;32m'
  YELLOW='\e[00;33m'
  CYAN='\e[00;36m'
  BOLD='\033[1m'
}

# Set hide/unhide cursor vars
HIDE='\033[?25l'
SHOW='\033[?25h'

# Store default IFS
DEFAULTIFS=$IFS

# Show version
echo -e "\n$BR_VERSION"

# Set arguments and help page
BRargs=$(getopt -o "i:d:n:c:u:HNjqvgDzP:E:oaC:Mwr:e:l:s:b:h:G:S:f:y:p:R:Om:k:t:B:xWFL" -l "mode:,directory:,filename:,compression:,user-opts:,exclude-home,no-hidden,no-color,quiet,verbose,generate,disable-genkernel,hide-cursor,passphrase:,encryption:,override,clean,conf:,multi-core,wrapper,root:,esp:,esp-mpoint:,swap:,boot:,home:,grub:,syslinux:,file:,username:,password:,rootsubvol:,only-hidden,mount-opts:,kernel-opts:,custom-parts:,other-subvols:,dont-check-root,bios,efistub,bootctl,help" -n "$1" -- "$@")

if [ "$?" -ne "0" ]; then
  echo "See $0 --help"
  exit
fi

eval set -- "$BRargs";

while true; do
  case "$1" in
    -i|--mode)
      BRmode=$2
      shift 2
    ;;
    -u|--user-opts)
      BR_USER_OPTS=$2
      shift 2
    ;;
    -d|--directory)
      BRFOLDER=$2
      shift 2
    ;;
    -n|--filename)
      BRNAME=$2
      shift 2
    ;;
    -c|--compression)
      BRcompression=$2
      shift 2
    ;;
    -H|--exclude-home)
      BRhome="No"
      shift
    ;;
    -N|--no-hidden)
      BRhidden="No"
      shift
    ;;
    -j|--no-color)
      BRnocolor="y"
      shift
    ;;
    -q|--quiet)
      BRquiet="y"
      shift
    ;;
    -v|--verbose)
      BRverb="y"
      shift
    ;;
    -g|--generate)
      BRgen="y"
      shift
    ;;
    -D|--disable-genkernel)
      BRgenkernel="n"
      shift
    ;;
    -z|--hide-cursor)
      BRhide="y"
      shift
    ;;
    -P|--passphrase)
      BRencpass=$2
      shift 2
    ;;
    -E|--encryption)
      BRencmethod=$2
      shift 2
    ;;
    -o|--override)
      BRoverride="y"
      shift
    ;;
    -a|--clean)
      BRclean="y"
      shift
    ;;
    -C|--conf)
      BRconf=$2
      shift 2
    ;;
    -M|--multi-core)
      BRmcore="y"
      shift
    ;;
    -w|--wrapper)
      BRwrap="y"
      shift
    ;;
    -r|--root)
      BRroot=$2
      shift 2
    ;;
    -e|--esp)
      BResp=$2
      shift 2
    ;;
    -l|--esp-mpoint)
      BRespmpoint=$2
      shift 2
    ;;
    -s|--swap)
      BRswap=$2
      shift 2
    ;;
    -b|--boot)
      BRbootpart=$2
      shift 2
    ;;
    -h|--home)
      BRhomepart=$2
      shift 2
    ;;
    -G|--grub)
      BRgrub=$2
      shift 2
    ;;
    -S|--syslinux)
      BRsyslinux=$2
      shift 2
    ;;
    -f|--file)
      BRuri=$2
      shift 2
    ;;
    -y|--username)
      BRusername=$2
      shift 2
    ;;
    -p|--password)
      BRpassword=$2
      shift 2
    ;;
    -R|--rootsubvol)
      BRrootsubvolname=$2
      shift 2
    ;;
    -O|--only-hidden)
      BRhid="y"
      shift
    ;;
    -m|--mount-opts)
      BR_MOUNT_OPTS=$2
      shift 2
    ;;
    -k|--kernel-opts)
      BR_KERNEL_OPTS=$2
      shift 2
    ;;
    -t|--custom-parts)
      BRcustomparts=($2)
      shift 2
    ;;
    -B|--other-subvols)
      BRsubvols=($2)
      shift 2
    ;;
    -x|--dont-check-root)
      BRdontckroot="y"
      shift
    ;;
    -W|--bios)
      unset BR_EFI_DETECT_DIR
      shift
    ;;
    -F|--efistub)
      BRefistub="y"
      shift
    ;;
    -L|--bootctl)
      BRbootctl="y"
      shift
    ;;
    --help)
      echo "Usage: $0 -i mode [options]

General Options:
  -i, --mode                  Select mode: 0 (Backup) 1 (Restore) 2 (Transfer)
  -j, --no-color              Disable colors
  -q, --quiet                 Dont ask, just run
  -v, --verbose               Enable verbose archiver output
  -z, --hide-cursor           Hide the cursor when running archiver (useful for some terminal emulators)
  -w, --wrapper               Make the script wrapper-friendly
  -u, --user-opts             Additional tar/rsync options. See tar/rsync --help
                              If you want spaces in names replace them with //
  -o, --override              Override the default tar/rsync options with user options (use with -u)
  -D, --disable-genkernel     Disable genkernel check and initramfs building in gentoo
      --help	              Print this page

Backup Mode:
  Destination:
    -d, --directory           Backup destination path
    -n, --filename            Backup filename (without extension)

  Home Directory:
    -H, --exclude-home	      Exclude /home directory (keep hidden files and folders)
    -N, --no-hidden           Dont keep home's hidden files and folders (use with -H)

  Archiver Options:
    -c, --compression         Compression type: gzip bzip2 xz none
    -M, --multi-core          Enable multi-core compression (via pigz, pbzip2 or pxz)

  Encryption Options:
    -E, --encryption          Encryption method: openssl gpg
    -P, --passphrase          Passphrase for encryption

  Misc Options:
    -C, --conf                Alternative configuration file path
    -g, --generate            Generate configuration file (in case of successful backup)
    -a, --clean               Remove older backups in the destination directory

Restore / Transfer Mode:
  Partitions:
    -r,  --root               Target root partition
    -e,  --esp                Target EFI system partition
    -l,  --esp-mpoint         Mount point for ESP: /boot/efi /boot
    -b,  --boot               Target /boot partition
    -h,  --home               Target /home partition
    -s,  --swap               Swap partition
    -t,  --custom-parts       Specify custom partitions. Syntax is mountpoint=device (e.g /var=/dev/sda3)
                              If you want spaces in mountpoints replace them with //
    -m,  --mount-opts         Comma-separated list of mount options (root partition only)

  Btrfs Subvolumes:
    -R,  --rootsubvol         Subvolume name for /
    -B,  --other-subvols      Specify other subvolumes (subvolume path e.g /home /var /usr ...)

  Bootloaders:
    -G,  --grub               Target disk for grub
    -S,  --syslinux           Target disk for syslinux
    -F,  --efistub            Enable EFISTUB/efibootmgr
    -L,  --bootctl            Enable Systemd/bootctl
    -k,  --kernel-opts        Additional kernel options

  Restore Mode:
    -f,  --file               Backup file path or url
    -y,  --username           Ftp/http username
    -p,  --password           Ftp/http password
    -P,  --passphrase         Passphrase for decryption

  Transfer Mode:
    -O,  --only-hidden        Transfer /home's hidden files and folders only

  Misc Options:
    -x,  --dont-check-root    Dont check if root partition is empty (dangerous)
    -W,  --bios               Ignore UEFI environment"
      exit
      shift
    ;;
    --)
      shift
      break
    ;;
  esac
done

# Give PID to wrapper
if [ -n "$BRwrap" ]; then
  echo $$ > /tmp/wr_pid
fi

# Apply colors
if [ -z "$BRnocolor" ]; then
  color_variables
fi

# Check if run with root privileges
if [ $(id -u) -gt 0 ]; then
  echo -e "[${RED}ERROR${NORM}] Script must run as root" >&2
  exit
fi

# Check mode
if [ -z "$BRmode" ]; then
  echo -e "[${RED}ERROR${NORM}] You must specify a mode" >&2
  exit
elif  [ -n "$BRmode" ] && [ ! "$BRmode" = "0" ] && [ ! "$BRmode" = "1" ] && [ ! "$BRmode" = "2" ]; then
  echo -e "[${RED}ERROR${NORM}] Wrong mode: $BRmode. Available options: 0 (Backup) 1 (Restore) 2 (Transfer)" >&2
  exit
fi

pstr="========================"
dstr="                        "

# Backup mode
if [ "$BRmode" = "0" ]; then

  # Delete temporary files if exist
  clean_tmp_files() {
    if [ -f /tmp/excludelist ]; then rm /tmp/excludelist; fi
    if [ -f /tmp/b_error ]; then rm /tmp/b_error; fi
    if [ -f /tmp/b_filelist ]; then rm /tmp/b_filelist; fi
    if [ -f /target_architecture.$(uname -m) ]; then rm /target_architecture.$(uname -m); fi
  }

  # Show a nice summary
  show_summary() {
    echo "ARCHIVE"
    echo "$BRFOLDER/$BRNAME.$BR_EXT $mcinfo"

    echo -e "\nARCHIVER OPTIONS"
    for i in "${BR_TAROPTS[@]}"; do echo "$i"; done

    echo -e "\nHOME DIRECTORY"
    if [ "$BRhome" = "Yes" ]; then
      echo "Include"
    elif [ "$BRhome" = "No" ] && [ "$BRhidden" = "Yes" ]; then
      echo "Only hidden files and folders"
    elif [ "$BRhome" = "No" ] && [ "$BRhidden" = "No" ]; then
      echo "Exclude"
    fi

    echo -e "\nFOUND BOOTLOADERS"
    if which grub-mkconfig &>/dev/null || which grub2-mkconfig &>/dev/null; then echo "Grub"; else BRgrub="n"; fi
    if which extlinux &>/dev/null && which syslinux &>/dev/null; then echo "Syslinux"; else BRsyslinux="n"; fi
    if which efibootmgr &>/dev/null; then echo "EFISTUB/efibootmgr"; else BRefibootmgr="n"; fi
    if which bootctl &>/dev/null; then echo "Systemd/bootctl"; else BRbootctl="n"; fi

    if [ -n "$BRgrub" ] && [ -n "$BRsyslinux" ] && [ -n "$BRefibootmgr" ] && [ -n "$BRbootctl" ]; then
      echo "None or not supported"
    fi

    if [ -n "$BRoldbackups" ] && [ -n "$BRclean" ]; then
      echo -e "\nREMOVE BACKUPS"
      for item in "${BRoldbackups[@]}"; do echo "$item"; done
    fi
  }

  # Calculate files to create percentage and progress bar
  run_calc() {
    tar cvf /dev/null "${BR_TAROPTS[@]}" / 2>/dev/null | tee /tmp/b_filelist
  }

  # Run tar with given input
  run_tar() {
    if [ -n "$BRencpass" ] && [ "$BRencmethod" = "openssl" ]; then
      tar ${BR_MAINOPTS} >( openssl aes-256-cbc -salt -k "$BRencpass" -out "$BRFOLDER/$BRNAME.$BR_EXT" 2>> "$BRFOLDER"/backup.log ) "${BR_TAROPTS[@]}" /
    elif [ -n "$BRencpass" ] && [ "$BRencmethod" = "gpg" ]; then
      tar ${BR_MAINOPTS} >( gpg -c --batch --yes --passphrase "$BRencpass" -z 0 -o "$BRFOLDER/$BRNAME.$BR_EXT" 2>> "$BRFOLDER"/backup.log ) "${BR_TAROPTS[@]}" /
    else
      tar ${BR_MAINOPTS} "$BRFOLDER/$BRNAME.$BR_EXT" "${BR_TAROPTS[@]}" /
    fi
  }

  # Calculate  percentage and compose a simple progress bar
  pgrs_bar() {
    lastper=-1
    while read ln; do
      b=$((b + 1))
      per=$(($b*100/$total))
      if [ -n "$BRverb" ] && [[ $per -le 100 ]]; then
        echo -e "${YELLOW}[$per%] ${GREEN}$ln${NORM}"
      elif [[ $per -gt $lastper ]] && [[ $per -le 100 ]]; then
        lastper=$per
        if [ -n "$BRwrap" ]; then
          echo "Archiving: $per% ($b / $total Files)" > /tmp/wr_proc
        else
          echo -ne "\rArchiving: [${pstr:0:$(($b*24/$total))}${dstr:0:24-$(($b*24/$total))}] $per%"
        fi
      fi
    done
  }

 # Generate configuration file
  generate_conf() {
    echo -e "#Auto-generated configuration file\n#Place it in /etc/backup.conf\n\n"
    echo -e "BRFOLDER='$(dirname "$BRFOLDER")'"
    if [ -n "$BRNAME" ] && [[ ! "$BRNAME" == Backup-$(hostname)-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]:[0-9][0-9]:[0-9][0-9] ]]; then echo "BRNAME='$BRNAME'"; fi
    echo -e "BRcompression=$BRcompression"
    if [ "$BRhome" = "No" ] && [ "$BRhidden" = "Yes" ]; then echo "BRhome=No"; fi
    if [ "$BRhome" = "No" ] && [ "$BRhidden" = "No" ]; then echo -e "BRhome=No\nBRhidden=No"; fi
    if [ -n "$BR_USER_OPTS" ]; then echo "BR_USER_OPTS='$BR_USER_OPTS'"; fi
    if [ -n "$BRnocolor" ]; then echo "BRnocolor=Yes"; fi
    if [ -n "$BRverb" ]; then echo "BRverb=Yes"; fi
    if [ -n "$BRquiet" ]; then echo "BRquiet=Yes"; fi
    if [ -n "$BRoverride" ]; then echo "BRoverride=Yes"; fi
    if [ -n "$BRencpass" ]; then echo -e "BRencmethod=$BRencmethod\nBRencpass='$BRencpass'"; fi
    if [ -n "$BRclean" ]; then echo "BRclean=Yes"; fi
    if [ -n "$BRhide" ]; then echo "BRhide=Yes"; fi
    if [ -n "$BRgenkernel" ]; then echo "BRgenkernel=No"; fi
  }

  # Check for configuration file and source it
  if [ -z "$BRconf" ]; then
    BRconf="/etc/backup.conf"
  elif [ -n "$BRconf" ] && [ ! -f "$BRconf" ]; then
    echo -e "[${RED}ERROR${NORM}] File does not exist: $BRconf" >&2
    exit
  fi
  if [ -f "$BRconf" ] && [ -z "$BRwrap" ]; then
    source "$BRconf"
  fi

  clean_tmp_files

  # Check user input, exit on error
  if [ ! -d "$BRFOLDER" ] && [ -n "$BRFOLDER" ]; then
    echo -e "[${RED}ERROR${NORM}] Directory does not exist: $BRFOLDER" >&2
    exit
  fi

  if [ -n "$BRcompression" ] && [ ! "$BRcompression" = "gzip" ] && [ ! "$BRcompression" = "xz" ] && [ ! "$BRcompression" = "bzip2" ] && [ ! "$BRcompression" = "none" ]; then
    echo -e "[${RED}ERROR${NORM}] Wrong compression type: $BRcompression. Available options: gzip bzip2 xz none" >&2
    exit
  fi

  if [ -f /etc/portage/make.conf ] || [ -f /etc/make.conf ] && [ -z "$BRgenkernel" ] && [ -z $(which genkernel 2>/dev/null) ]; then
    echo -e "[${YELLOW}WARNING${NORM}] Package genkernel is not installed. Install the package and re-run the script. (you can disable this check with -D)" >&2
    exit
  fi

  if [ -z "$BRencmethod" ] ||  [ "$BRencmethod" = "none" ] && [ -n "$BRencpass" ]; then
    echo -e "[${YELLOW}WARNING${NORM}] You must specify an encryption method" >&2
    exit
  fi

  if [ -z "$BRencpass" ] && [ -n "$BRencmethod" ] && [ ! "$BRencmethod" = "none" ]; then
    echo -e "[${YELLOW}WARNING${NORM}] You must specify a passphrase" >&2
    exit
  fi

  if [ -n "$BRencmethod" ] && [ ! "$BRencmethod" = "openssl" ] && [ ! "$BRencmethod" = "gpg" ] && [ ! "$BRencmethod" = "none" ]; then
    echo -e "[${RED}ERROR${NORM}] Wrong encryption method: $BRencmethod. Available options: openssl gpg" >&2
    exit
  fi

  if [ -n "$BRmcore" ] && [ -z "$BRcompression" ]; then
    echo -e "[${YELLOW}WARNING${NORM}] You must specify compression type" >&2
    exit
  elif [ -n "$BRmcore" ] && [ "$BRcompression" = "gzip" ] && [ -z $(which pigz 2>/dev/null) ]; then
    echo -e "[${RED}ERROR${NORM}] Package pigz is not installed. Install the package and re-run the script." >&2
    exit
  elif [ -n "$BRmcore" ] && [ "$BRcompression" = "bzip2" ] && [ -z $(which pbzip2 2>/dev/null) ]; then
    echo -e "[${RED}ERROR${NORM}] Package pbzip2 is not installed. Install the package and re-run the script." >&2
    exit
  elif [ -n "$BRmcore" ] && [ "$BRcompression" = "xz" ] && [ -z $(which pxz 2>/dev/null) ]; then
    echo -e "[${RED}ERROR${NORM}] Package pxz is not installed. Install the package and re-run the script." >&2
    exit
  fi

  if [ -n "$BRwrap" ] && [ -z "$BRFOLDER" ]; then
    echo -e "[${YELLOW}WARNING${NORM}] You must specify destination directory" >&2
    exit
  fi

  # Set some defaults if not given by the user
  if [ -z "$BRFOLDER" ]; then BRFOLDER="/"; fi
  if [ -z "$BRNAME" ]; then BRNAME="Backup-$(hostname)-$(date +%Y-%m-%d-%T)"; fi
  if [ -z "$BRhidden" ]; then BRhidden="Yes"; fi
  if [ -z "$BRhome" ]; then BRhome="Yes"; fi
  if [ -z "$BRcompression" ]; then BRcompression="gzip"; fi
  if [ -z "$BRencmethod" ]; then BRencmethod="none"; fi

 # Set backup subdirectory
  BRFOLDER=$(echo "$BRFOLDER"/Backup-$(date +%Y-%m-%d) | sed 's://*:/:g')

  # Set tar compression options and backup file extension
  if [ "$BRcompression" = "gzip" ] && [ -n "$BRmcore" ]; then
    BR_MAINOPTS="-c -I pigz -vpf"
    BR_EXT="tar.gz"
    mcinfo="(pigz)"
  elif [ "$BRcompression" = "gzip" ]; then
    BR_MAINOPTS="cvpzf"
    BR_EXT="tar.gz"
  elif [ "$BRcompression" = "xz" ] && [ -n "$BRmcore" ]; then
    BR_MAINOPTS="-c -I pxz -vpf"
    BR_EXT="tar.xz"
    mcinfo="(pxz)"
  elif [ "$BRcompression" = "xz" ]; then
    BR_MAINOPTS="cvpJf"
    BR_EXT="tar.xz"
  elif [ "$BRcompression" = "bzip2" ] && [ -n "$BRmcore" ]; then
    BR_MAINOPTS="-c -I pbzip2 -vpf"
    BR_EXT="tar.bz2"
    mcinfo="(pbzip2)"
  elif [ "$BRcompression" = "bzip2" ]; then
    BR_MAINOPTS="cvpjf"
    BR_EXT="tar.bz2"
  elif [ "$BRcompression" = "none" ]; then
    BR_MAINOPTS="cvpf"
    BR_EXT="tar"
  fi

  # Set backup file extension based on encryption
  if [ -n "$BRencpass" ] && [ "$BRencmethod" = "openssl" ]; then
    BR_EXT="$BR_EXT.aes"
  elif [ -n "$BRencpass" ] && [ "$BRencmethod" = "gpg" ]; then
    BR_EXT="$BR_EXT.gpg"
  fi

  # Set tar default options
  BR_TAROPTS=(--exclude=/run/* --exclude=/dev/* --exclude=/sys/* --exclude=/tmp/* --exclude=/mnt/* --exclude=/proc/* --exclude=/media/* --exclude=/var/run/* --exclude=/var/lock/* --exclude=.gvfs --exclude=lost+found --exclude="$BRFOLDER" --sparse)

  # Keep only this if -o is given
  if [ -n "$BRoverride" ]; then
    BR_TAROPTS=(--exclude="$BRFOLDER")
  fi

  # Needed by Fedora
  if [ -f /etc/yum.conf ] || [ -f /etc/dnf/dnf.conf ]; then
    BR_TAROPTS+=(--acls --xattrs --selinux)
  fi

  # Set /home directory options
  if [ "$BRhome" = "No" ] && [ "$BRhidden" = "No" ]; then
    BR_TAROPTS+=(--exclude=/home/*)
  elif [ "$BRhome" = "No" ] && [ "$BRhidden" = "Yes" ]; then
    find /home/*/* -maxdepth 0 -iname ".*" -prune -o -print > /tmp/excludelist
    BR_TAROPTS+=(--exclude-from=/tmp/excludelist)
  fi

  # Add tar user options to the main array, replace any // with space
  for i in ${BR_USER_OPTS[@]}; do BR_TAROPTS+=("${i///\//\ }"); done

  # Check destination for backup directories with older date
  IFS=$'\n'
  for i in $(find $(dirname "$BRFOLDER") -mindepth 1 -maxdepth 1 -type d -iname "Backup-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"); do
    if [ "${i//[^0-9]/}" -lt "${BRFOLDER//[^0-9]/}" ]; then BRoldbackups+=("$i"); fi
  done
  IFS=$DEFAULTIFS

  # Check if backup file already exists and prompt the user to overwrite
  if [ -z "$BRquiet" ]; then
    while [ -f "$BRFOLDER/$BRNAME.$BR_EXT" ]; do
      echo -e "${BOLD}"
      read -p "Destination ($BRNAME.$BR_EXT) already exists. Overwrite? [y/N]: " an
      echo -ne "${NORM}"
      if [ -z "$an" ]; then an=n; fi

      if [ "$an" = "y" ] || [ "$an" = "Y" ]; then
        break
      elif [ "$an" = "n" ] || [ "$an" = "N" ]; then
        exit
      else
        echo -e "${RED}Please enter a valid option${NORM}"
      fi
    done
  fi

  # Show summary and prompt the user to continue
  echo -e "\n${BOLD}[SUMMARY]${CYAN}"
  show_summary
  echo -ne "${NORM}"

  while [ -z "$BRquiet" ]; do
    echo -e "${BOLD}"
    read -p "Continue? [Y/n]: " an
    echo -ne "${NORM}"
    if [ -z "$an" ]; then an=y; fi

    if [ "$an" = "y" ] || [ "$an" = "Y" ]; then
      break
    elif [ "$an" = "n" ] || [ "$an" = "N" ]; then
      clean_tmp_files
      exit
    else
      echo -e "${RED}Please enter a valid option${NORM}"
    fi
  done

  # Delete older backup directories if -a is given
  if [ -n "$BRoldbackups" ] && [ -n "$BRclean" ]; then
    for item in "${BRoldbackups[@]}"; do rm -r "$item"; done
  fi

  # Prepare directories, start the log, store start time
  echo -e "\n${BOLD}[PROCESSING]${NORM}"
  if [ -n "$BRwrap" ]; then echo "Preparing..." > /tmp/wr_proc; fi
  touch /target_architecture.$(uname -m)
  mkdir -p "$BRFOLDER"
  sleep 1
  echo -e "$BR_VERSION [Backup $(date +%Y-%m-%d-%T)]\n" > "$BRFOLDER"/backup.log
  ( echo "[SUMMARY]"; show_summary; echo -e "\n[ARCHIVER]" ) >> "$BRFOLDER"/backup.log
  start=$(date +%s)

  # Hide the cursor if -H is given
  if [ -n "$BRhide" ]; then echo -en "${HIDE}"; fi

  # Calculate the number of files and store it
  if [ -n "$BRwrap" ]; then echo "Please wait while calculating files..." > /tmp/wr_proc; fi
  run_calc | while read ln; do a=$((a + 1)) && echo -en "\rCalculating: $a Files"; done
  total=$(cat /tmp/b_filelist | wc -l)
  sleep 1
  echo

  # Run tar and pipe it through the progress calculation
  ( run_tar 2>> "$BRFOLDER"/backup.log || touch /tmp/b_error ) | pgrs_bar

  # Give full permissions to destination directory
  OUTPUT=$(chmod ugo+rw -R "$BRFOLDER" 2>&1) && echo -ne "\nSetting permissions: Done\n" || echo -ne "\nSetting permissions: Failed\n$OUTPUT\n"

  # Complete the log, calculate and show elapsed time
  if [ ! -f /tmp/b_error ]; then echo "System archived successfully" >> "$BRFOLDER"/backup.log; fi
  elapsed="Elapsed time: $(($(($(date +%s)-start))/3600)) hours $((($(($(date +%s)-start))%3600)/60)) min $(($(($(date +%s)-start))%60)) sec"
  echo "$elapsed" >> "$BRFOLDER"/backup.log

  # Inform the user if error occurred or not
  if [ -f /tmp/b_error ]; then
    echo -e "${RED}\nAn error occurred.\n\nCheck $BRFOLDER/backup.log for details.\n$elapsed${NORM}"
  else
    echo -e "${CYAN}\nBackup archive and log saved in $BRFOLDER\n$elapsed${NORM}"
  fi

  # Generate configuration file if -g is given and no error occurred, unhide the cursor if -H is given, give log to wrapper
  if [ -n "$BRgen" ] && [ ! -f /tmp/b_error ]; then generate_conf > "$BRFOLDER"/backup.conf; fi
  if [ -n "$BRhide" ]; then echo -en "${SHOW}"; fi
  if [ -n "$BRwrap" ]; then cat "$BRFOLDER"/backup.log > /tmp/wr_log; fi

  clean_tmp_files

# Restore / Transfer Mode
elif [ "$BRmode" = "1" ] || [ "$BRmode" = "2" ]; then

  # Delete temporary files if exist
  clean_tmp_files() {
    if [ -f /tmp/filelist ]; then rm /tmp/filelist; fi
    if [ -f /tmp/bl_error ]; then rm /tmp/bl_error; fi
  }

  # Show the exit screen
  exit_screen() {
    if [ -f /tmp/bl_error ]; then
      echo -e "\n${RED}Error installing $BRbootloader. Check /tmp/restore.log for details.\n\n${CYAN}Press ENTER to unmount all remaining (engaged) devices.${NORM}"
    elif [ -n "$BRbootloader" ]; then
      echo -e "\n${CYAN}Completed. Log: /tmp/restore.log\n\nPress ENTER to unmount all remaining (engaged) devices, then reboot your system.${NORM}"
    else
      echo -e "\n${CYAN}Completed. Log: /tmp/restore.log\n\n${YELLOW}You didn't choose a bootloader, so this is the right time to install and\nupdate one. To do so:"
      echo -e "\n==>For internet connection to work, on a new terminal with root\n   access enter: cp -L /etc/resolv.conf /mnt/target/etc/resolv.conf"
      echo -e "\n==>Then chroot into the target system: chroot /mnt/target\n\n==>Install and update a bootloader\n\n==>When done, leave chroot: exit"
      echo -e "\n==>Finally, return to this window and press ENTER to unmount\n   all remaining (engaged) devices.${NORM}"
    fi
  }

  # Show alternative exit screen if -q is given
  exit_screen_quiet() {
    if [ -f /tmp/bl_error ]; then
      echo -e "\n${RED}Error installing $BRbootloader.\nCheck /tmp/restore.log for details.${NORM}"
    else
      echo -e "\n${CYAN}Completed. Log: /tmp/restore.log${NORM}"
    fi
  }

  # Print success message, set var for processing custom partitions
  ok_status() {
    echo -e "\r[${GREEN}SUCCESS${NORM}]"
    custom_ok="y"
  }

  # Print failure message, set var for errors
  error_status() {
    echo -e "\r[${RED}FAILURE${NORM}]\n$OUTPUT"
    BRSTOP="y"
  }

  # Detect root partition filesystem and size, exit if filesystem not found
  detect_root_fs_size() {
    BRfsystem=$(blkid -s TYPE -o value $BRroot)
    BRfsize=$(lsblk -d -n -o size 2>/dev/null $BRroot | sed -e 's/ *//')
    if [ -z "$BRfsystem" ]; then
      echo -e "[${RED}ERROR${NORM}] Unknown root file system" >&2
      exit
    fi
  }

  # Detect backup archive encryption
  detect_encryption() {
    if [ "$(file -b "$BRsource")" = "data" ]; then
      BRencmethod="openssl"
    elif file -b "$BRsource" | grep -qw GPG; then
      BRencmethod="gpg"
    else
      unset BRencmethod
    fi
  }

  # Detect backup archive filetype and set tar options accordingly
  detect_filetype() {
    echo "Checking archive type..."
    if [ -n "$BRwrap" ]; then echo "Checking archive type..." > /tmp/wr_proc; fi
    if [ -n "$BRencpass" ] && [ "$BRencmethod" = "openssl" ]; then
      BRtype=$(openssl aes-256-cbc -d -salt -in "$BRsource" -k "$BRencpass" 2>/dev/null | file -b -)
    elif [ -n "$BRencpass" ] && [ "$BRencmethod" = "gpg" ]; then
      BRtype=$(gpg -d --batch --passphrase "$BRencpass" "$BRsource" 2>/dev/null | file -b -)
    else
      BRtype=$(file -b "$BRsource")
    fi

    if echo "$BRtype" | grep -q -w gzip; then
      BRfiletype="gzip compressed"
      BRreadopts="tfz"
      BR_MAINOPTS="xvpfz"
    elif echo "$BRtype" | grep -q -w bzip2; then
      BRfiletype="bzip2 compressed"
      BRreadopts="tfj"
      BR_MAINOPTS="xvpfj"
    elif echo "$BRtype" | grep -q -w XZ; then
      BRfiletype="xz compressed"
      BRreadopts="tfJ"
      BR_MAINOPTS="xvpfJ"
    elif echo "$BRtype" | grep -q -w POSIX; then
      BRfiletype="uncompressed"
      BRreadopts="tf"
      BR_MAINOPTS="xvpf"
    else
       BRfiletype="wrong"
    fi
  }

  # Check wget exit status, exit on error, process the downloaded backup archive if otherwise
  check_wget() {
    if [ -f /tmp/wget_error ]; then
      rm /tmp/wget_error
      echo -e "[${RED}ERROR${NORM}] Error downloading file. Wrong URL, wrong authentication, network is down or package wget is not installed." >&2
      clean_unmount_in
    else
      detect_encryption
      if [ -n "$BRencmethod" ] && [ -z "$BRencpass" ]; then
        echo -ne "${BOLD}"
        read -p "Enter Passphrase: " BRencpass
        echo -ne "${NORM}"
      fi
      detect_filetype
      if [ "$BRfiletype" = "wrong" ]; then
        echo -e "[${RED}ERROR${NORM}] Invalid file type or wrong passphrase" >&2
        clean_unmount_in
      fi
    fi
  }

  # Detect the distro by checking for known package manager conf files
  detect_distro() {
    if [ "$BRmode" = "1" ]; then
      if grep -Fxq "etc/yum.conf" /tmp/filelist || grep -Fxq "etc/dnf/dnf.conf" /tmp/filelist; then
        BRdistro="Fedora"
        USER_OPTS+=(--selinux --acls "--xattrs-include='*'")
      elif grep -Fxq "etc/pacman.conf" /tmp/filelist; then
        BRdistro="Arch"
      elif grep -Fxq "etc/apt/sources.list" /tmp/filelist; then
        BRdistro="Debian"
      elif grep -Fxq "etc/zypp/zypp.conf" /tmp/filelist; then
        BRdistro="Suse"
      elif grep -Fxq "etc/urpmi/urpmi.cfg" /tmp/filelist; then
        BRdistro="Mandriva"
      elif grep -Fxq "etc/portage/make.conf" /tmp/filelist || grep -Fxq "etc/make.conf" /tmp/filelist; then
        BRdistro="Gentoo"
      else
        BRdistro="Unsupported"
      fi

    elif [ "$BRmode" = "2" ]; then
      if [ -f /etc/yum.conf ] || [ -f /etc/dnf/dnf.conf ]; then
        BRdistro="Fedora"
      elif [ -f /etc/pacman.conf ]; then
        BRdistro="Arch"
      elif [ -f /etc/apt/sources.list ]; then
        BRdistro="Debian"
      elif [ -f /etc/zypp/zypp.conf ]; then
        BRdistro="Suse"
      elif [ -f /etc/urpmi/urpmi.cfg ]; then
        BRdistro="Mandriva"
      elif [ -f /etc/portage/make.conf ] || [ -f /etc/make.conf ]; then
        BRdistro="Gentoo"
      else
        BRdistro="Unsupported"
      fi
    fi
  }

  # Set the root in Syslinux, EFISTUB and Bootctl configuration entries
  detect_bl_root() {
    if [[ "$BRroot" == *mapper* ]]; then
      echo "root=$BRroot"
    else
      echo "root=UUID=$(blkid -s UUID -o value $BRroot)"
    fi
  }

  # Set the root in fstab
  detect_fstab_root() {
    if [[ "$BRroot" == *dev/md* ]]; then
      echo "$BRroot"
    else
      echo "UUID=$(blkid -s UUID -o value $BRroot)"
    fi
  }

  # Detect the partition table for Syslinux so we can use the corresponding bin files
  detect_partition_table_syslinux() {
    if [[ "$BRsyslinux" == *md* ]]; then
      BRsyslinuxdisk="$BRdev"
    else
      BRsyslinuxdisk="$BRsyslinux"
    fi
    if dd if="$BRsyslinuxdisk" skip=64 bs=8 count=1 2>/dev/null | grep -qw "EFI PART"; then
      BRpartitiontable="gpt"
    else
      BRpartitiontable="mbr"
    fi
  }

  # Apply appropriate partition flags for Syslinux and search known locations for bin and com32 Syslinux files
  set_syslinux_flags_and_paths() {
    if [ "$BRpartitiontable" = "gpt" ]; then
      echo "Setting legacy_boot flag on partition $BRpart of $BRdev"
      sgdisk $BRdev --attributes=$BRpart:set:2 &>> /tmp/restore.log || touch /tmp/bl_error
      BRsyslinuxmbr="gptmbr.bin"
    else
      echo "Setting boot flag on partition $BRpart of $BRdev"
      sfdisk $BRdev -A $BRpart &>> /tmp/restore.log || touch /tmp/bl_error
      BRsyslinuxmbr="mbr.bin"
    fi

    for BIN in /mnt/target/usr/lib/syslinux/$BRsyslinuxmbr \
      /mnt/target/usr/lib/syslinux/mbr/$BRsyslinuxmbr \
      /mnt/target/usr/share/syslinux/$BRsyslinuxmbr; do
      if [ -f "$BIN" ]; then
        BRsyslinuxmbrpath=$(dirname "$BIN")
      fi
    done

    for COM32 in /mnt/target/usr/lib/syslinux/menu.c32 \
      /mnt/target/usr/lib/syslinux/modules/bios/menu.c32 \
      /mnt/target/usr/share/syslinux/menu.c32; do
      if [ -f "$COM32" ]; then
        BRsyslinuxcompath=$(dirname "$COM32")
      fi
    done
  }

  # Generate Syslinux configuration file
  generate_syslinux_cfg() {
    echo -e "UI menu.c32\nPROMPT 0\nMENU TITLE Boot Menu\nTIMEOUT 50"

    for FILE in /mnt/target/boot/*; do
      if file -b -k "$FILE" | grep -qw "bzImage"; then
        cn=$(echo "$FILE" | sed -n 's/[^-]*-//p')
        kn=$(basename "$FILE")

        if [ "$BRdistro" = "Arch" ]; then
          echo -e "LABEL arch\n\tMENU LABEL $BRdistro $cn\n\tLINUX ../$kn\n\tAPPEND $(detect_bl_root) $BR_KERNEL_OPTS\n\tINITRD ../$ipn-$cn.img"
          echo -e "LABEL archfallback\n\tMENU LABEL $BRdistro $cn fallback\n\tLINUX ../$kn\n\tAPPEND $(detect_bl_root) $BR_KERNEL_OPTS\n\tINITRD ../$ipn-$cn-fallback.img"
        elif [ "$BRdistro" = "Debian" ]; then
          echo -e "LABEL debian\n\tMENU LABEL $BRdistro-$cn\n\tLINUX ../$kn\n\tAPPEND $(detect_bl_root) $BR_KERNEL_OPTS\n\tINITRD ../$ipn.img-$cn"
        elif [ "$BRdistro" = "Fedora" ]; then
          echo -e "LABEL fedora\n\tMENU LABEL $BRdistro-$cn\n\tLINUX ../$kn\n\tAPPEND $(detect_bl_root) $BR_KERNEL_OPTS\n\tINITRD ../$ipn-$cn.img"
        elif [ "$BRdistro" = "Suse" ]; then
          echo -e "LABEL suse\n\tMENU LABEL $BRdistro-$cn\n\tLINUX ../$kn\n\tAPPEND $(detect_bl_root) $BR_KERNEL_OPTS\n\tINITRD ../$ipn-$cn"
        elif [ "$BRdistro" = "Mandriva" ]; then
          echo -e "LABEL suse\n\tMENU LABEL $BRdistro-$cn\n\tLINUX ../$kn\n\tAPPEND $(detect_bl_root) $BR_KERNEL_OPTS\n\tINITRD ../$ipn-$cn.img"
        elif [ "$BRdistro" = "Gentoo" ] && [ -z "$BRgenkernel" ]; then
          echo -e "LABEL gentoo\n\tMENU LABEL $BRdistro-$kn\n\tLINUX ../$kn\n\tAPPEND $(detect_bl_root) $BR_KERNEL_OPTS\n\tINITRD ../$ipn-$cn"
        elif [ "$BRdistro" = "Gentoo" ]; then
          echo -e "LABEL gentoo\n\tMENU LABEL $BRdistro-$kn\n\tLINUX ../$kn\n\tAPPEND root=$BRroot $BR_KERNEL_OPTS"
        fi
      fi
    done
  }

  # Set tar/rsync user options, replace any // with space
  set_user_options() {
    IFS=$DEFAULTIFS
    for i in ${BR_USER_OPTS[@]}; do USER_OPTS+=("${i///\//\ }"); done
    IFS=$'\n'
  }

  # Run tar with given input
  run_tar() {
    if [ -n "$BRencpass" ] && [ "$BRencmethod" = "openssl" ]; then
      openssl aes-256-cbc -d -salt -in "$BRsource" -k "$BRencpass" 2>> /tmp/restore.log | tar ${BR_MAINOPTS} - "${USER_OPTS[@]}" -C /mnt/target && (echo "System extracted successfully" >> /tmp/restore.log)
    elif [ -n "$BRencpass" ] && [ "$BRencmethod" = "gpg" ]; then
      gpg -d --batch --passphrase "$BRencpass" "$BRsource" 2>> /tmp/restore.log | tar ${BR_MAINOPTS} - "${USER_OPTS[@]}" -C /mnt/target && (echo "System extracted successfully" >> /tmp/restore.log)
    else
      tar ${BR_MAINOPTS} "$BRsource" "${USER_OPTS[@]}" -C /mnt/target && (echo "System extracted successfully" >> /tmp/restore.log)
    fi
  }

  # Set default rsync options if -o is not given, add user options to the main array
  set_rsync_opts() {
    if [ -z "$BRoverride" ]; then
      BR_RSYNCOPTS=(--exclude=/run/* --exclude=/dev/* --exclude=/sys/* --exclude=/tmp/* --exclude=/mnt/* --exclude=/proc/* --exclude=/media/* --exclude=/var/run/* --exclude=/var/lock/* --exclude=/home/*/.gvfs --exclude=lost+found)
    fi
    if [ -n "$BRhid" ]; then
      BR_RSYNCOPTS+=(--exclude=/home/*/[^.]*)
    fi
    BR_RSYNCOPTS+=("${USER_OPTS[@]}")
  }

  # Calculate files to create percentage and progress bar
  run_calc() {
    rsync -av / /mnt/target "${BR_RSYNCOPTS[@]}" --dry-run 2>/dev/null | tee /tmp/filelist
  }

  # Run rsync with given input
  run_rsync() {
    rsync -aAXv / /mnt/target "${BR_RSYNCOPTS[@]}" && (echo "System transferred successfully" >> /tmp/restore.log)
  }

  # Scan normal partitions, lvm, md arrays and sd card partitions
  scan_parts() {
    for f in $(find /dev -regex "/dev/[vhs]d[a-z][0-9]+"); do echo "$f"; done | sort
    for f in $(find /dev/mapper/ -maxdepth 1 -mindepth 1 ! -name "control"); do echo "$f"; done
    for f in $(find /dev -regex "^/dev/md[0-9]+$"); do echo "$f"; done
    for f in $(find /dev -regex "/dev/mmcblk[0-9]+p[0-9]+"); do echo "$f"; done
  }

  # Scan disks, md arrays and sd card devices
  scan_disks() {
    for f in /dev/[vhs]d[a-z]; do echo "$f"; done
    for f in $(find /dev -regex "^/dev/md[0-9]+$"); do echo "$f"; done
    for f in $(find /dev -regex "/dev/mmcblk[0-9]+"); do echo "$f"; done
  }

  # Check user input in many possible ways
  check_input() {
    if [ -n "$BRsource" ] && [ ! -f "$BRsource" ]; then
      echo -e "[${RED}ERROR${NORM}] File not found: $BRsource"
      exit
    elif [ -n "$BRsource" ] && [ -f "$BRsource" ] && [ -z "$BRfiletype" ]; then
      detect_encryption
      detect_filetype
      if [ "$BRfiletype" = "wrong" ]; then
        echo -e "[${RED}ERROR${NORM}] Invalid file type or wrong passphrase"
        exit
      fi
    fi

    if [ "$BRmode" = "2" ]; then
      if [ -z $(which rsync 2>/dev/null) ];then
        echo -e "[${RED}ERROR${NORM}] Package rsync is not installed. Install the package and re-run the script"
        exit
      fi
      if [ -f /etc/portage/make.conf ] || [ -f /etc/make.conf ] && [ -z "$BRgenkernel" ] && [ -z $(which genkernel 2>/dev/null) ]; then
        echo -e "[${RED}ERROR${NORM}] Package genkernel is not installed. Install the package and re-run the script. (you can disable this check with -D)"
        exit
      fi
      if [ -n "$BRgrub" ] && [ -z $(which grub-mkconfig 2>/dev/null) ] && [ -z $(which grub2-mkconfig 2>/dev/null) ]; then
        echo -e "[${RED}ERROR${NORM}] Grub not found. Install it and re-run the script."
        exit
      elif [ -n "$BRsyslinux" ]; then
        if [ -z $(which extlinux 2>/dev/null) ]; then
          echo -e "[${RED}ERROR${NORM}] Extlinux not found. Install it and re-run the script"
          exit
        fi
        if [ -z $(which syslinux 2>/dev/null) ]; then
          echo -e "[${RED}ERROR${NORM}] Syslinux not found. Install it and re-run the script"
          exit
        fi
      fi
      if [ -n "$BRbootctl" ] || [ -n "$BRefistub" ] || [ -n "$BRgrub" ] && [ -d "$BR_EFI_DETECT_DIR" ] && [ -z $(which mkfs.vfat 2>/dev/null) ]; then
        echo -e "[${RED}ERROR${NORM}] Package dosfstools is not installed. Install the package and re-run the script"
        exit
      fi
      if [ -n "$BRefistub" ] || [ -n "$BRgrub" ] && [ -d "$BR_EFI_DETECT_DIR" ] && [ -z $(which efibootmgr 2>/dev/null) ]; then
        echo -e "[${RED}ERROR${NORM}] Package efibootmgr is not installed. Install the package and re-run the script"
        exit
      fi
      if [ -n "$BRbootctl" ] && [ -d "$BR_EFI_DETECT_DIR" ] && [ -z $(which bootctl 2>/dev/null) ]; then
        echo -e "[${RED}ERROR${NORM}] Bootctl not found"
        exit
      fi
    fi

    if [ -n "$BRroot" ]; then
      for i in $(scan_parts); do if [ "$i" = "$BRroot" ]; then BRrootcheck="true"; fi; done
      if [ ! "$BRrootcheck" = "true" ]; then
        echo -e "[${RED}ERROR${NORM}] Wrong root partition: $BRroot"
        exit
      elif [ ! -z $(lsblk -d -n -o mountpoint 2>/dev/null $BRroot) ]; then
        echo -e "[${YELLOW}WARNING${NORM}] $BRroot is already mounted as $(lsblk -d -n -o mountpoint 2>/dev/null $BRroot), refusing to use it"
        exit
      fi
    fi

    if [ -n "$BRswap" ]; then
      for i in $(scan_parts); do if [ "$i" = "$BRswap" ]; then BRswapcheck="true"; fi; done
      if [ ! "$BRswapcheck" = "true" ]; then
        echo -e "[${RED}ERROR${NORM}] Wrong swap partition: $BRswap"
        exit
      fi
      if [ "$BRswap" = "$BRroot" ]; then
        echo -e "[${YELLOW}WARNING${NORM}] $BRswap already used"
        exit
      fi
    fi

    if [ -n "$BRcustomparts" ]; then
      BRdevused=(`for i in ${BRcustomparts[@]}; do BRdevice=$(echo $i | cut -f2 -d"=") && echo $BRdevice; done | sort | uniq -d`)
      BRmpointused=(`for i in ${BRcustomparts[@]}; do BRmpoint=$(echo $i | cut -f1 -d"=") && echo $BRmpoint; done | sort | uniq -d`)
      if [ -n "$BRdevused" ]; then
        for a in ${BRdevused[@]}; do
          echo -e "[${YELLOW}WARNING${NORM}] $a already used"
          exit
        done
      fi
      if [ -n "$BRmpointused" ]; then
        for a in ${BRmpointused[@]}; do
          echo -e "[${YELLOW}WARNING${NORM}] Duplicate mountpoint: $a"
          exit
        done
      fi

      for k in ${BRcustomparts[@]}; do
        BRmpoint=$(echo $k | cut -f1 -d"=")
        BRdevice=$(echo $k | cut -f2 -d"=")

        for i in $(scan_parts); do if [ "$i" = "$BRdevice" ]; then BRcustomcheck="true"; fi; done
        if [ ! "$BRcustomcheck" = "true" ]; then
          echo -e "[${RED}ERROR${NORM}] Wrong $BRmpoint partition: $BRdevice"
          exit
        elif [ ! -z $(lsblk -d -n -o mountpoint 2>/dev/null $BRdevice) ]; then
          echo -e "[${YELLOW}WARNING${NORM}] $BRdevice is already mounted as $(lsblk -d -n -o mountpoint 2>/dev/null $BRdevice), refusing to use it"
          exit
        fi
        if [ "$BRdevice" = "$BRroot" ] || [ "$BRdevice" = "$BRswap" ]; then
          echo -e "[${YELLOW}WARNING${NORM}] $BRdevice already used"
          exit
        fi
        if [ "$BRmpoint" = "/" ]; then
          echo -e "[${YELLOW}WARNING${NORM}] Dont assign root partition as custom"
          exit
        fi
        if [[ ! "$BRmpoint" == /* ]]; then
          echo -e "[${RED}ERROR${NORM}] Wrong mountpoint syntax: $BRmpoint"
          exit
        fi
        unset BRcustomcheck
      done
    fi

    if [ -n "$BRsubvols" ] && [ -z "$BRrootsubvolname" ]; then
      echo -e "[${YELLOW}WARNING${NORM}] You must specify a root subvolume name"
      exit
    fi

    if [ -n "$BRsubvols" ]; then
      BRsubvolused=(`for i in ${BRsubvols[@]}; do echo $i; done | sort | uniq -d`)
      if [ -n "$BRsubvolused" ]; then
        for a in ${BRsubvolused[@]}; do
          echo -e "[${YELLOW}WARNING${NORM}] Duplicate subvolume: $a"
          exit
        done
      fi

      for k in ${BRsubvols[@]}; do
        if [[ ! "$k" == /* ]]; then
          echo -e "[${RED}ERROR${NORM}] Wrong subvolume syntax: $k"
          exit
        fi
        if [ "$k" = "/" ]; then
          echo -e "[${YELLOW}WARNING${NORM}] Use -R to assign root subvolume"
          exit
        fi
      done
    fi

    if [ -n "$BRgrub" ] && [ ! "$BRgrub" = "auto" ]; then
      for i in $(scan_disks); do if [ "$i" = "$BRgrub" ]; then BRgrubcheck="true"; fi; done
      if [ ! "$BRgrubcheck" = "true" ]; then
        echo -e "[${RED}ERROR${NORM}] Wrong disk for grub: $BRgrub"
        exit
      fi
    fi

    if [ -n "$BRgrub" ] && [ "$BRgrub" = "auto" ] && [ ! -d "$BR_EFI_DETECT_DIR" ]; then
      echo -e "[${RED}ERROR${NORM}] Use 'auto' in UEFI environment only"
      exit
    fi

    if [ -n "$BRgrub" ] && [ ! "$BRgrub" = "auto" ] && [ -d "$BR_EFI_DETECT_DIR" ]; then
      echo -e "[${YELLOW}WARNING${NORM}] In UEFI environment use 'auto' for grub location"
      exit
    fi

    if [ -n "$BRsyslinux" ]; then
      for i in $(scan_disks); do if [ "$i" = "$BRsyslinux" ]; then BRsyslinuxcheck="true"; fi; done
      if [ ! "$BRsyslinuxcheck" = "true" ]; then
        echo -e "[${RED}ERROR${NORM}] Wrong disk for syslinux: $BRsyslinux"
        exit
      fi
      if [ -d "$BR_EFI_DETECT_DIR" ]; then
        echo -e "[${RED}ERROR${NORM}] The script does not support Syslinux as UEFI bootloader"
        exit
      fi
    fi

    if [ -n "$BRgrub" ] && [ -n "$BRsyslinux" ]; then
      echo -e "[${YELLOW}WARNING${NORM}] Dont use multiple bootloaders"
      exit
    elif [ -n "$BRgrub" ] && [ -n "$BRefistub" ]; then
      echo -e "[${YELLOW}WARNING${NORM}] Dont use multiple bootloaders"
      exit
    elif [ -n "$BRgrub" ] && [ -n "$BRbootctl" ]; then
      echo -e "[${YELLOW}WARNING${NORM}] Dont use multiple bootloaders"
      exit
    elif [ -n "$BRefistub" ] && [ -n "$BRbootctl" ]; then
      echo -e "[${YELLOW}WARNING${NORM}] Dont use multiple bootloaders"
      exit
    fi

    if [ ! -d "$BR_EFI_DETECT_DIR" ] && [ -n "$BResp" ]; then
      echo -e "[${YELLOW}WARNING${NORM}] Dont use EFI system partition in bios mode"
      exit
    fi

    if [ -n "$BRgrub" ] || [ -n "$BRefistub" ] || [ -n "$BRbootctl" ] && [ -d "$BR_EFI_DETECT_DIR" ] && [ -n "$BRroot" ] && [ -z "$BResp" ]; then
      echo -e "[${RED}ERROR${NORM}] You must specify a target EFI system partition"
      exit
    fi

    if [ -n "$BRefistub" ] && [ ! -d "$BR_EFI_DETECT_DIR" ]; then
      echo -e "[${RED}ERROR${NORM}] EFISTUB is available in UEFI environment only"
      exit
    fi

    if [ -n "$BRbootctl" ] && [ ! -d "$BR_EFI_DETECT_DIR" ]; then
      echo -e "[${RED}ERROR${NORM}] Bootctl is available in UEFI environment only"
      exit
    fi

    if [ -n "$BResp" ] && [ -z "$BRespmpoint" ] && [ -d "$BR_EFI_DETECT_DIR" ]; then
      echo -e "[${YELLOW}WARNING${NORM}] You must specify mount point for ESP ($BResp)"
      exit
    elif [ -n "$BResp" ] && [ ! "$BRespmpoint" = "/boot/efi" ] && [ ! "$BRespmpoint" = "/boot" ] && [ -d "$BR_EFI_DETECT_DIR" ]; then
      echo -e "[${YELLOW}WARNING${NORM}] Wrong ESP mount point: $BRespmpoint. Available options: /boot/efi /boot"
      exit
    fi
  }

  # Mount root partition and check if it's empty, create brtfs subvolumes and re-mount if specified, mount other partitions, find partition sizes, exit on errors
  mount_all() {
    if [ -n "$BRwrap" ]; then echo "Mounting..." > /tmp/wr_proc; fi
    echo -e "\n${BOLD}[MOUNTING]${NORM}"
    echo -ne "${WRK}Making working directory"
    OUTPUT=$(mkdir /mnt/target 2>&1) && ok_status || error_status

    echo -ne "${WRK}Mounting $BRroot"
    OUTPUT=$(mount -o $BR_MOUNT_OPTS $BRroot /mnt/target 2>&1) && ok_status || error_status
    BRsizes+=(`lsblk -n -b -o size "$BRroot" 2>/dev/null`=/mnt/target)
    if [ -n "$BRSTOP" ]; then
      echo -e "\n[${RED}ERROR${NORM}] Error while mounting partitions" >&2
      clean_tmp_files
      rm -r /mnt/target
      exit
    fi

    if [ "$(ls -A /mnt/target | grep -vw "lost+found")" ]; then
      if [ -z "$BRdontckroot" ]; then
        echo -e "[${RED}ERROR${NORM}] Root partition not empty, refusing to use it" >&2
        echo -e "[${CYAN}INFO${NORM}] Root partition must be formatted and cleaned" >&2
        echo -ne "${WRK}Unmounting $BRroot"
        sleep 1
        OUTPUT=$(umount $BRroot 2>&1) && (ok_status && rm_work_dir) || (error_status && echo -e "[${YELLOW}WARNING${NORM}] /mnt/target remained")
        exit
      else
        echo -e "[${YELLOW}WARNING${NORM}] Root partition not empty"
      fi
    fi

    if [ "$BRfsystem" = "btrfs" ] && [ -n "$BRrootsubvolname" ]; then
      echo -ne "${WRK}Creating $BRrootsubvolname"
      OUTPUT=$(btrfs subvolume create /mnt/target/$BRrootsubvolname 2>&1 1>/dev/null) && ok_status || error_status

      if [ -n "$BRsubvols" ]; then
        while read ln; do
          echo -ne "${WRK}Creating $BRrootsubvolname$ln"
          OUTPUT=$(btrfs subvolume create /mnt/target/$BRrootsubvolname$ln 2>&1 1>/dev/null) && ok_status || error_status
        done< <(for a in "${BRsubvols[@]}"; do echo "$a"; done | sort)
      fi

      echo -ne "${WRK}Unmounting $BRroot"
      OUTPUT=$(umount $BRroot 2>&1) && ok_status || error_status

      echo -ne "${WRK}Mounting $BRrootsubvolname"
      OUTPUT=$(mount -t btrfs -o $BR_MOUNT_OPTS,subvol=$BRrootsubvolname $BRroot /mnt/target 2>&1) && ok_status || error_status
      if [ -n "$BRSTOP" ]; then
        echo -e "\n[${RED}ERROR${NORM}] Error while making subvolumes" >&2
        unset BRSTOP
        clean_unmount_in
      fi
    fi

    if [ -n "$BRcustomparts" ]; then
      BRsorted=(`for i in ${BRcustomparts[@]}; do echo $i; done | sort -k 1,1 -t =`)
      unset custom_ok
      for i in ${BRsorted[@]}; do
        BRdevice=$(echo $i | cut -f2 -d"=")
        BRmpoint=$(echo $i | cut -f1 -d"=")
        BRmpoint="${BRmpoint///\//\ }" # Replace any // with space
        echo -ne "${WRK}Mounting $BRdevice"
        mkdir -p /mnt/target$BRmpoint
        OUTPUT=$(mount $BRdevice /mnt/target$BRmpoint 2>&1) && ok_status || error_status
        BRsizes+=(`lsblk -n -b -o size "$BRdevice" 2>/dev/null`=/mnt/target$BRmpoint)
        if [ -n "$custom_ok" ]; then
          unset custom_ok
          BRumountparts+=($BRmpoint=$BRdevice)
          if [ "$(ls -A /mnt/target$BRmpoint | grep -vw "lost+found")" ]; then
            echo -e "[${CYAN}INFO${NORM}] $BRmpoint partition not empty"
          fi
        fi
      done
      if [ -n "$BRSTOP" ]; then
        echo -e "\n[${RED}ERROR${NORM}] Error while mounting partitions" >&2
        unset BRSTOP
        clean_unmount_in
      fi
    fi
    # Find the bigger partition to save the downloaded backup archive
    BRmaxsize=$(for i in ${BRsizes[@]}; do echo $i; done | sort -nr -k 1,1 -t = | head -n1 | cut -f2 -d"=")
  }

  # Show a nice summary
  show_summary() {
    echo "TARGET PARTITION SCHEME:"
    BRpartitions="Partition|Mountpoint|Filesystem|Size|Options"
    BRpartitions="$BRpartitions\n$BRroot $BRmap|/|$BRfsystem|$BRfsize|$BR_MOUNT_OPTS"
    if [ -n "$BRcustomparts" ]; then
      for i in ${BRsorted[@]}; do
        BRdevice=$(echo $i | cut -f2 -d"=")
        BRmpoint=$(echo $i | cut -f1 -d"=")
        BRmpoint="${BRmpoint///\//\ }"
        BRcustomfs=$(blkid -s TYPE -o value $BRdevice)
        BRcustomsize=$(lsblk -d -n -o size 2>/dev/null $BRdevice | sed -e 's/ *//')
        BRpartitions="$BRpartitions\n$BRdevice|$BRmpoint|$BRcustomfs|$BRcustomsize"
      done
    fi
    if [ -n "$BRswap" ]; then
      BRpartitions="$BRpartitions\n$BRswap|swap"
    fi
    echo -e "$BRpartitions" | column -t -s '|'

    if [ "$BRfsystem" = "btrfs" ] && [ -n "$BRrootsubvolname" ]; then
      echo -e "\nSUBVOLUMES:"
      echo "$BRrootsubvolname"
      if [ -n "$BRsubvols" ]; then
        for k in "${BRsubvols[@]}"; do
          echo "$BRrootsubvolname$k"
        done | sort
      fi
    fi

    echo -e "\nBOOTLOADER:"
    if [ -n "$BRgrub" ]; then
      if [ -d "$BR_EFI_DETECT_DIR" ]; then
        echo "$BRbootloader ($BRgrubefiarch)"
      else
        echo "$BRbootloader (i386-pc)"
      fi
      if [[ "$BRgrub" == *md* ]]; then
        echo Locations: $(grep -w "${BRgrub##*/}" /proc/mdstat | grep -oP '[vhs]d[a-z]')
      else
        echo "Location: $BRgrub"
      fi
    elif [ -n "$BRsyslinux" ]; then
      echo "$BRbootloader ($BRpartitiontable)"
      if [[ "$BRsyslinux" == *md* ]]; then
        echo Locations: $(grep -w "${BRsyslinux##*/}" /proc/mdstat | grep -oP '[vhs]d[a-z]')
      else
        echo "Location: $BRsyslinux"
      fi
    elif [ -n "$BRefistub" ] || [ -n "$BRbootctl" ]; then
      echo "$BRbootloader"
    else
      echo "None (WARNING)"
    fi

    if [ -n "$BRbootloader" ] && [ -n "$BR_KERNEL_OPTS" ]; then
      echo "Kernel Options: $BR_KERNEL_OPTS"
    fi

    echo -e "\nPROCESS:"
    if [ "$BRmode" = "1" ]; then
      echo "Mode:     Restore"
    elif [ "$BRmode" = "2" ]; then
      echo "Mode:     Transfer"
     fi
    if [ -n "$BRencpass" ] && [ -n "$BRencmethod" ]; then
      enc_info="$BRencmethod encrypted"
    fi

    if [ "$BRmode" = "1" ]; then
      echo "Archive:  $BRfiletype $enc_info"
    elif [ "$BRmode" = "2" ] && [ -n "$BRhid" ]; then
      echo "Home:     Only hidden files and folders"
    elif [ "$BRmode" = "2" ]; then
      echo "Home:     Include"
    fi

    if [ "$BRdistro" = "Unsupported" ]; then
      echo "System:   $BRdistro (WARNING)"
    elif [ "$BRmode" = "1" ]; then
      echo "System:   $BRdistro based $target_arch"
    elif [ "$BRmode" = "2" ]; then
      echo "System:   $BRdistro based $(uname -m)"
    fi

    if [ "$BRdistro" = "Gentoo" ] && [ -n "$BRgenkernel" ]; then
      echo "Info:     Skip initramfs building"
    fi

    if [ "$BRmode" = "2" ] && [ -n "$BR_RSYNCOPTS" ]; then
      echo -e "\nRSYNC OPTIONS:"
      for i in "${BR_RSYNCOPTS[@]}"; do echo "$i"; done
    elif [ "$BRmode" = "1" ] && [ -n "$USER_OPTS" ]; then
      echo -e "\nARCHIVER OPTIONS:"
      for i in "${USER_OPTS[@]}"; do echo "$i"; done
    fi
  }

  # Bind needed directories so we can chroot in the target system
  prepare_chroot() {
    echo -e "\nPreparing chroot environment"
    echo "Binding /run"
    mount --bind /run /mnt/target/run
    echo "Binding /dev"
    mount --bind /dev /mnt/target/dev
    echo "Binding /dev/pts"
    mount --bind /dev/pts /mnt/target/dev/pts
    echo "Binding /proc"
    mount --bind /proc /mnt/target/proc
    echo "Binding /sys"
    mount --bind /sys /mnt/target/sys
    if [ -d "$BR_EFI_DETECT_DIR" ]; then
      echo "Binding /sys/firmware/efi/efivars"
      mount --bind /sys/firmware/efi/efivars /mnt/target/sys/firmware/efi/efivars
    fi
  }

  # Generate target system's fstab
  generate_fstab() {
    if [ "$BRfsystem" = "btrfs" ] && [ -n "$BRrootsubvolname" ] && [ ! "$BRdistro" = "Suse" ]; then
      echo -e "# $BRroot\n$(detect_fstab_root)  /  btrfs  $BR_MOUNT_OPTS,subvol=$BRrootsubvolname  0  0"
    elif [ "$BRfsystem" = "btrfs" ]; then
      echo -e "# $BRroot\n$(detect_fstab_root)  /  btrfs  $BR_MOUNT_OPTS  0  0"
    else
      echo -e "# $BRroot\n$(detect_fstab_root)  /  $BRfsystem  $BR_MOUNT_OPTS  0  1"
    fi

    if [ -n "$BRcustomparts" ]; then
      for i in ${BRsorted[@]}; do
        BRdevice=$(echo $i | cut -f2 -d"=")
        BRmpoint=$(echo $i | cut -f1 -d"=")
        BRmpoint="${BRmpoint///\//\\040}" # Convert // with 040, needed for paths with spaces
        BRcustomfs=$(blkid -s TYPE -o value $BRdevice)
        echo -e "\n# $BRdevice"
        if [[ "$BRdevice" == *dev/md* ]]; then
          echo "$BRdevice  $BRmpoint  $BRcustomfs  defaults  0  2"
        else
          echo "UUID=$(blkid -s UUID -o value $BRdevice)  $BRmpoint  $BRcustomfs  defaults  0  2"
        fi
      done
    fi

    if [ -n "$BRswap" ]; then
      if [[ "$BRswap" == *dev/md* ]]; then
        echo -e "\n# $BRswap\n$BRswap  none  swap  defaults  0  0"
      else
        echo -e "\n# $BRswap\nUUID=$(blkid -s UUID -o value $BRswap)  none  swap  defaults  0  0"
      fi
    fi
    ( echo -e "\nGenerated fstab:"; cat /mnt/target/etc/fstab ) >> /tmp/restore.log
  }

  # Generate a basic mdadm.conf and crypttab, rebuild initramfs images for all available kernels
  build_initramfs() {
    echo -e "\nRebuilding initramfs images"
    if grep -q dev/md /mnt/target/etc/fstab || [[ "$BRmap" == *raid* ]]; then
      echo "Generating mdadm.conf..."
      if [ "$BRdistro" = "Debian" ]; then
        BR_MDADM_PATH="/mnt/target/etc/mdadm"
      else
        BR_MDADM_PATH="/mnt/target/etc"
      fi
      if [ -f "$BR_MDADM_PATH/mdadm.conf" ]; then
        mv "$BR_MDADM_PATH/mdadm.conf" "$BR_MDADM_PATH/mdadm.conf-old"
      fi
      mdadm --examine --scan > "$BR_MDADM_PATH/mdadm.conf"
      cat "$BR_MDADM_PATH/mdadm.conf"
      echo
    fi

    if [ -n "$BRencdev" ] && [ ! "$BRdistro" = "Arch" ] && [ ! "$BRdistro" = "Gentoo" ]; then
      if [ -f  /mnt/target/etc/crypttab ]; then
        mv /mnt/target/etc/crypttab /mnt/target/etc/crypttab-old
      fi
      echo "Generating basic crypttab..."
      echo "$crypttab_root UUID=$(blkid -s UUID -o value $BRencdev) none luks" > /mnt/target/etc/crypttab
      cat /mnt/target/etc/crypttab
      echo
    fi

    for FILE in /mnt/target/boot/*; do
      if file -b -k "$FILE" | grep -qw "bzImage"; then
        cn=$(echo "$FILE" | sed -n 's/[^-]*-//p')
        if [ -n "$BRwrap" ] && [ ! "$BRdistro" = "Gentoo" ] && [ ! "$BRdistro" = "Unsupported" ]; then
          echo "Building initramfs image for $cn..." > /tmp/wr_proc
        fi

        if [ "$BRdistro" = "Arch" ]; then
          chroot /mnt/target mkinitcpio -p $cn
        elif [ "$BRdistro" = "Debian" ]; then
          chroot /mnt/target update-initramfs -u -k $cn
        elif [ "$BRdistro" = "Suse" ]; then
          chroot /mnt/target mkinitrd -k vmlinuz-$cn -i $ipn-$cn
        elif [ "$BRdistro" = "Mandriva" ] || [ "$BRdistro" = "Fedora" ]; then
          chroot /mnt/target dracut -f -v /boot/$ipn-$cn.img $cn
        fi
      fi
    done

    if [ "$BRdistro" = "Gentoo" ]; then
      if [ -n "$BRgenkernel" ]; then
        echo "Skipping..."
      else
        if [ -n "$BRwrap" ]; then echo "Building initramfs images..." > /tmp/wr_proc; fi
        chroot /mnt/target genkernel --no-color --install initramfs
      fi
    fi
  }

  # Check the initramfs name prefix
  detect_initramfs_prefix() {
    if ls /mnt/target/boot/ | grep -q "initramfs-"; then
      ipn="initramfs"
    else
      ipn="initrd"
    fi
  }

  # Find and copy Grub efi bootloader executable
  cp_grub_efi() {
    if [ ! -d /mnt/target$BRespmpoint/EFI/boot ]; then
      mkdir /mnt/target$BRespmpoint/EFI/boot
    fi

    BR_GRUBX64_EFI="$(find /mnt/target$BRespmpoint/EFI ! -path "*/EFI/boot/*" ! -path "*/EFI/BOOT/*" -name "grubx64.efi" 2>/dev/null)"
    BR_GRUBIA32_EFI="$(find /mnt/target$BRespmpoint/EFI ! -path "*/EFI/boot/*" ! -path "*/EFI/BOOT/*" -name "grubia32.efi" 2>/dev/null)"

    if [ -f "$BR_GRUBX64_EFI" ]; then
      echo "Copying "$BR_GRUBX64_EFI" as /mnt/target$BRespmpoint/EFI/boot/bootx64.efi..."
      cp "$BR_GRUBX64_EFI" /mnt/target$BRespmpoint/EFI/boot/bootx64.efi
    elif [ -f "$BR_GRUBIA32_EFI" ]; then
      echo "Copying "$BR_GRUBIA32_EFI" as /mnt/target$BRespmpoint/EFI/boot/bootx32.efi..."
      cp "$BR_GRUBIA32_EFI" /mnt/target$BRespmpoint/EFI/boot/bootx32.efi
    fi
  }

  # Find and copy kernels in case of ESP on /boot/efi
  cp_kernels() {
    for FILE in /mnt/target/boot/*; do
      if file -b -k "$FILE" | grep -qw "bzImage"; then
        echo "Copying $FILE in /mnt/target/boot/efi/"
        cp "$FILE" /mnt/target/boot/efi/
      fi
    done

    for FILE in /mnt/target/boot/*; do
      if [[ "$FILE" == *initramfs* ]] || [[ "$FILE" == *initrd* ]]; then
        echo "Copying $FILE in /mnt/target/boot/efi/"
        cp "$FILE" /mnt/target/boot/efi/
      fi
    done
  }

  # Detect luks/lvm/raid combinations
  detect_root_map() {
    if [[ "$BRroot" == *mapper* ]] && cryptsetup status "$BRroot" &>/dev/null; then
      BRencdev=$(cryptsetup status $BRroot 2>/dev/null | grep device | sed -e "s/ *device:[ \t]*//")

      if [[ "$BRencdev" == *mapper* ]] && lvdisplay "$BRencdev" &>/dev/null; then
        BRphysical=$(lvdisplay --maps $BRencdev 2>/dev/null | grep "Physical volume" | sed -e "s/ *Physical volume[ \t]*//")
        if [[ "$BRphysical" == *dev/md* ]]; then
          BRmap="luks->lvm->raid"
        else
          BRmap="luks->lvm"
        fi
      elif [[ "$BRencdev" == *dev/md* ]]; then
        BRmap="luks->raid"
      else
        BRmap="luks"
      fi

    elif [[ "$BRroot" == *mapper* ]] && lvdisplay "$BRroot" &>/dev/null; then
      BRphysical=$(lvdisplay --maps $BRroot 2>/dev/null | grep "Physical volume" | sed -e "s/ *Physical volume[ \t]*//")
      BRvgname=$(lvdisplay $BRroot 2>/dev/null | grep "VG Name" | sed -e "s/ *VG Name[ \t]*//")

      if [[ "$BRphysical" == *mapper* ]] && cryptsetup status "$BRphysical" &>/dev/null; then
        BRencdev=$(cryptsetup status $BRphysical 2>/dev/null | grep device | sed -e "s/ *device:[ \t]*//")
        if [[ "$BRencdev" == *dev/md* ]]; then
          BRmap="lvm->luks->raid"
        else
          BRmap="lvm->luks"
        fi
      elif [[ "$BRphysical" == *dev/md* ]]; then
        BRmap="lvm->raid"
      else
        BRmap="lvm"
      fi
    elif [[ "$BRroot" == *dev/md* ]]; then
      BRmap="raid"
    fi
  }

  # Set some default and user kernel boot options
  set_kern_opts() {
    if [ -n "$BRsyslinux" ] || [ -n "$BRefistub" ] || [ -n "$BRbootctl" ]; then
      if [ "$BRdistro" = "Arch" ]; then
        BR_KERNEL_OPTS="rw ${BR_KERNEL_OPTS}"
      else
        BR_KERNEL_OPTS="ro quiet ${BR_KERNEL_OPTS}"
      fi
      if [ "$BRfsystem" = "btrfs" ] && [ -n "$BRrootsubvolname" ]; then
        BR_KERNEL_OPTS="rootflags=subvol=$BRrootsubvolname ${BR_KERNEL_OPTS}"
      fi
    elif [ -n "$BRgrub" ] && [ "$BRdistro" = "Fedora" ]; then
      BR_KERNEL_OPTS="quiet rhgb ${BR_KERNEL_OPTS}"
    fi

    if [ "$BRdistro" = "Gentoo" ] && [[ "$BRmap" == *lvm* ]]; then
      BR_KERNEL_OPTS="dolvm ${BR_KERNEL_OPTS}"
    fi
    if [ "$BRdistro" = "Gentoo" ] && [[ "$BRmap" == *raid* ]]; then
      BR_KERNEL_OPTS="domdadm ${BR_KERNEL_OPTS}"
    fi

    if [ "$BRmap" = "luks" ] || [ "$BRmap" = "luks->lvm" ] || [ "$BRmap" = "luks->raid" ] || [ "$BRmap" = "luks->lvm->raid" ]; then
      if [ -n "$BRencdev" ] && [ "$BRdistro" = "Gentoo" ]; then
        BR_KERNEL_OPTS="crypt_root=UUID=$(blkid -s UUID -o value $BRencdev) ${BR_KERNEL_OPTS}"
      elif [ -n "$BRencdev" ]; then
        BR_KERNEL_OPTS="cryptdevice=UUID=$(blkid -s UUID -o value $BRencdev):${BRroot##*/} ${BR_KERNEL_OPTS}"
        crypttab_root="${BRroot##*/}"
      fi
    elif [ "$BRmap" = "lvm->luks" ] || [ "$BRmap" = "lvm->luks->raid" ]; then
      if [ -n "$BRencdev" ] && [ "$BRdistro" = "Gentoo" ]; then
        BR_KERNEL_OPTS="crypt_root=UUID=$(blkid -s UUID -o value $BRencdev) ${BR_KERNEL_OPTS}"
      elif [ -n "$BRencdev" ]; then
        BR_KERNEL_OPTS="cryptdevice=UUID=$(blkid -s UUID -o value $BRencdev):$BRvgname ${BR_KERNEL_OPTS}"
        crypttab_root="${BRphysical##*/}"
      fi
    fi
  }

  # Install the selected bootloader
  install_bootloader() {
    if [ -n "$BRgrub" ]; then
      if [ -n "$BRwrap" ]; then echo "Installing Grub in $BRgrub..." > /tmp/wr_proc; fi
      echo -e "\nInstalling and updating Grub in $BRgrub"
      if [ -d "$BR_EFI_DETECT_DIR" ] && [ "$BRespmpoint" = "/boot" ] && [ -d /mnt/target/boot/efi ]; then
        if [ -d /mnt/target/boot/efi-old ]; then rm -r /mnt/target/boot/efi-old; fi
        mv /mnt/target/boot/efi /mnt/target/boot/efi-old
      fi

      if [[ "$BRgrub" == *md* ]]; then # If raid array selected, install in all disks the array contains
        for f in `grep -w "${BRgrub##*/}" /proc/mdstat | grep -oP '[vhs]d[a-z]'`; do
          if [ "$BRdistro" = "Arch" ]; then
            chroot /mnt/target grub-install --target=i386-pc --recheck /dev/$f || touch /tmp/bl_error
          elif [ "$BRdistro" = "Debian" ]; then
            chroot /mnt/target grub-install --recheck /dev/$f || touch /tmp/bl_error
          else
            chroot /mnt/target grub2-install --recheck /dev/$f || touch /tmp/bl_error
          fi
        done
      elif [ "$BRdistro" = "Arch" ] && [ -d "$BR_EFI_DETECT_DIR" ]; then
        chroot /mnt/target grub-install --target=$BRgrubefiarch --efi-directory=$BRgrub --bootloader-id=grub --recheck || touch /tmp/bl_error
      elif [ "$BRdistro" = "Arch" ]; then
        chroot /mnt/target grub-install --target=i386-pc --recheck $BRgrub || touch /tmp/bl_error
      elif [ "$BRdistro" = "Debian" ] && [ -d "$BR_EFI_DETECT_DIR" ]; then
        chroot /mnt/target grub-install --efi-directory=$BRgrub --recheck
      elif [ "$BRdistro" = "Debian" ]; then
        chroot /mnt/target grub-install --recheck $BRgrub || touch /tmp/bl_error
      elif [ -d "$BR_EFI_DETECT_DIR" ]; then
        chroot /mnt/target grub2-install --efi-directory=$BRgrub --recheck
      else
        chroot /mnt/target grub2-install --recheck $BRgrub || touch /tmp/bl_error
      fi

      if [ ! "$BRdistro" = "Fedora" ] && [ -d "$BR_EFI_DETECT_DIR" ]; then cp_grub_efi; fi
      if [ "$BRdistro" = "Fedora" ] && [ -d "$BR_EFI_DETECT_DIR" ] && [ "$BRespmpoint" = "/boot" ]; then cp_grub_efi; fi

      if [ -n "$BR_KERNEL_OPTS" ]; then
        if [ -f /mnt/target/etc/default/grub ]; then
          cp /mnt/target/etc/default/grub /mnt/target/etc/default/grub-old
        fi

        if grep -q "^GRUB_CMDLINE_LINUX=" /mnt/target/etc/default/grub; then
          sed -i 's\GRUB_CMDLINE_LINUX=.*\GRUB_CMDLINE_LINUX="'"$BR_KERNEL_OPTS"'"\' /mnt/target/etc/default/grub
        else
          echo GRUB_CMDLINE_LINUX='"'$BR_KERNEL_OPTS'"' >> /mnt/target/etc/default/grub
        fi

        ( echo -e "\nModified grub config:"; cat /mnt/target/etc/default/grub; echo ) >> /tmp/restore.log
      fi

      if [ "$BRdistro" = "Gentoo" ]; then
        chroot /mnt/target grub2-mkconfig -o /boot/grub/grub.cfg
      elif [ "$BRdistro" = "Arch" ] || [ "$BRdistro" = "Debian" ]; then
        chroot /mnt/target grub-mkconfig -o /boot/grub/grub.cfg
      else
        chroot /mnt/target grub2-mkconfig -o /boot/grub2/grub.cfg
      fi

    elif [ -n "$BRsyslinux" ]; then
      if [ -n "$BRwrap" ]; then echo "Installing Syslinux in $BRsyslinux..." > /tmp/wr_proc; fi
      echo -e "\nInstalling and configuring Syslinux in $BRsyslinux"
      if [ -d /mnt/target/boot/syslinux ]; then
        mv /mnt/target/boot/syslinux/syslinux.cfg /mnt/target/boot/syslinux.cfg-old
        chattr -i /mnt/target/boot/syslinux/* 2>/dev/null
        rm -r /mnt/target/boot/syslinux/* 2>/dev/null
      else
        mkdir -p /mnt/target/boot/syslinux
      fi
      touch /mnt/target/boot/syslinux/syslinux.cfg

      if [ "$BRdistro" = "Arch" ]; then
        chroot /mnt/target syslinux-install_update -i -a -m || touch /tmp/bl_error
      else
        if [[ "$BRsyslinux" == *md* ]]; then
          chroot /mnt/target extlinux --raid -i /boot/syslinux || touch /tmp/bl_error
          for f in `grep -w "${BRsyslinux##*/}" /proc/mdstat | grep -oP '[vhs]d[a-z][0-9]'`; do
            BRdev=`echo /dev/$f | cut -c -8`
            BRpart=`echo /dev/$f | cut -c 9-`
            detect_partition_table_syslinux
            set_syslinux_flags_and_paths
            echo "Installing $BRsyslinuxmbr in $BRdev ($BRpartitiontable)"
            dd bs=440 count=1 conv=notrunc if=$BRsyslinuxmbrpath/$BRsyslinuxmbr of=$BRdev &>> /tmp/restore.log || touch /tmp/bl_error
          done
        else
          chroot /mnt/target extlinux -i /boot/syslinux || touch /tmp/bl_error
          BRdev="$BRsyslinux"
          if [ -n "$BRbootpart" ]; then
            BRpart="${BRbootpart##*[[:alpha:]]}"
          else
            BRpart="${BRroot##*[[:alpha:]]}"
          fi
          detect_partition_table_syslinux
          set_syslinux_flags_and_paths
          echo "Installing $BRsyslinuxmbr in $BRsyslinux ($BRpartitiontable)"
          dd bs=440 count=1 conv=notrunc if=$BRsyslinuxmbrpath/$BRsyslinuxmbr of=$BRsyslinux &>> /tmp/restore.log || touch /tmp/bl_error
        fi
        echo "Copying com32 modules"
        cp "$BRsyslinuxcompath"/*.c32 /mnt/target/boot/syslinux/
      fi
      echo "Generating syslinux.cfg"
      generate_syslinux_cfg >> /mnt/target/boot/syslinux/syslinux.cfg
      ( echo -e "\nGenerated syslinux config:"; cat /mnt/target/boot/syslinux/syslinux.cfg ) >> /tmp/restore.log

    elif [ -n "$BRefistub" ]; then
      if [ -n "$BRwrap" ]; then echo "Setting boot entries using efibootmgr..." > /tmp/wr_proc; fi
      echo -e "\nSetting boot entries"
      if [[ "$BResp" == *mmcblk* ]]; then
        BRespdev="${BResp%[[:alpha:]]*}"
      else
        BRespdev="${BResp%%[[:digit:]]*}"
      fi
      BRespart="${BResp##*[[:alpha:]]}"

      if [ "$BRespmpoint" = "/boot/efi" ]; then cp_kernels; fi

      for FILE in /mnt/target$BRespmpoint/*; do
        if file -b -k "$FILE" | grep -qw "bzImage"; then
          cn=$(echo "$FILE" | sed -n 's/[^-]*-//p')
          kn=$(basename "$FILE")

          if [ "$BRdistro" = "Arch" ]; then
            chroot /mnt/target efibootmgr -d $BRespdev -p $BRespart -c -L "$BRdistro $cn fallback" -l /$kn -u "$(detect_bl_root) $BR_KERNEL_OPTS initrd=/$ipn-$cn-fallback.img" || touch /tmp/bl_error
            chroot /mnt/target efibootmgr -d $BRespdev -p $BRespart -c -L "$BRdistro $cn" -l /$kn -u "$(detect_bl_root) $BR_KERNEL_OPTS initrd=/$ipn-$cn.img" || touch /tmp/bl_error
          elif [ "$BRdistro" = "Debian" ]; then
            chroot /mnt/target efibootmgr -d $BRespdev -p $BRespart -c -L "$BRdistro-$cn" -l /$kn -u "$(detect_bl_root) $BR_KERNEL_OPTS initrd=/$ipn.img-$cn" || touch /tmp/bl_error
          elif [ "$BRdistro" = "Fedora" ] || [ "$BRdistro" = "Mandriva" ]; then
            chroot /mnt/target efibootmgr -d $BRespdev -p $BRespart -c -L "$BRdistro-$cn" -l /$kn -u "$(detect_bl_root) $BR_KERNEL_OPTS initrd=/$ipn-$cn.img" || touch /tmp/bl_error
          elif [ "$BRdistro" = "Suse" ]; then
            chroot /mnt/target efibootmgr -d $BRespdev -p $BRespart -c -L "$BRdistro-$cn" -l /$kn -u "$(detect_bl_root) $BR_KERNEL_OPTS initrd=/$ipn-$cn" || touch /tmp/bl_error
          elif [ "$BRdistro" = "Gentoo" ] && [ -z "$BRgenkernel" ]; then
            chroot /mnt/target efibootmgr -d $BRespdev -p $BRespart -c -L "$BRdistro-$kn" -l /$kn -u "$(detect_bl_root) $BR_KERNEL_OPTS initrd=/$ipn-$cn" || touch /tmp/bl_error
          elif [ "$BRdistro" = "Gentoo" ]; then
            chroot /mnt/target efibootmgr -d $BRespdev -p $BRespart -c -L "$BRdistro-$kn" -l /$kn -u "root=$BRroot $BR_KERNEL_OPTS" || touch /tmp/bl_error
          fi
        fi
      done
      chroot /mnt/target efibootmgr -v

    elif [ -n "$BRbootctl" ]; then
      if [ -n "$BRwrap" ]; then echo "Installing Bootctl in $BRespmpoint..." > /tmp/wr_proc; fi
      echo -e "\n$Installing Bootctl in $BRespmpoint"
      if [ -d /mnt/target$BRespmpoint/loader/entries ]; then
        for CONF in /mnt/target$BRespmpoint/loader/entries/*; do
          mv "$CONF" "$CONF"-old
        done
      fi
      if [ "$BRespmpoint" = "/boot/efi" ]; then cp_kernels; fi

      chroot /mnt/target bootctl --path=$BRespmpoint install || touch /tmp/bl_error

      if [ -f /mnt/target$BRespmpoint/loader/loader.conf ]; then
        mv /mnt/target$BRespmpoint/loader/loader.conf /mnt/target$BRespmpoint/loader/loader.conf-old
      fi
      echo "timeout  5" > /mnt/target$BRespmpoint/loader/loader.conf
      echo "Generating configuration entries"

      for FILE in /mnt/target$BRespmpoint/*; do
        if file -b -k "$FILE" | grep -qw "bzImage"; then
          cn=$(echo "$FILE" | sed -n 's/[^-]*-//p')
          kn=$(basename "$FILE")

          if [ "$BRdistro" = "Arch" ]; then
            echo -e "title $BRdistro $cn\nlinux /$kn\ninitrd /$ipn-$cn.img\noptions $(detect_bl_root) $BR_KERNEL_OPTS" > /mnt/target$BRespmpoint/loader/entries/$BRdistro-$cn.conf
            echo -e "title $BRdistro $cn fallback\nlinux /$kn\ninitrd /$ipn-$cn-fallback.img\noptions $(detect_bl_root) $BR_KERNEL_OPTS" > /mnt/target$BRespmpoint/loader/entries/$BRdistro-$cn-fallback.conf
          elif [ "$BRdistro" = "Debian" ]; then
            echo -e "title $BRdistro $cn\nlinux /$kn\ninitrd /$ipn.img-$cn\noptions $(detect_bl_root) $BR_KERNEL_OPTS" > /mnt/target$BRespmpoint/loader/entries/$BRdistro-$cn.conf
          elif [ "$BRdistro" = "Fedora" ] || [ "$BRdistro" = "Mandriva" ]; then
            echo -e "title $BRdistro $cn\nlinux /$kn\ninitrd /$ipn-$cn.img\noptions $(detect_bl_root) $BR_KERNEL_OPTS" > /mnt/target$BRespmpoint/loader/entries/$BRdistro-$cn.conf
          elif [ "$BRdistro" = "Suse" ]; then
            echo -e "title $BRdistro $cn\nlinux /$kn\ninitrd /$ipn-$cn\noptions $(detect_bl_root) $BR_KERNEL_OPTS" > /mnt/target$BRespmpoint/loader/entries/$BRdistro-$cn.conf
          elif [ "$BRdistro" = "Gentoo" ] && [ -z "$BRgenkernel" ]; then
            echo -e "title $BRdistro $cn\nlinux /$kn\ninitrd /$ipn-$cn\noptions $(detect_bl_root) $BR_KERNEL_OPTS" > /mnt/target$BRespmpoint/loader/entries/$BRdistro-$cn.conf
          elif [ "$BRdistro" = "Gentoo" ]; then
            echo -e "title $BRdistro $cn\nlinux /$kn\noptions root=$BRroot $BR_KERNEL_OPTS" > /mnt/target$BRespmpoint/loader/entries/$BRdistro-$cn.conf
          fi
          ( echo -e "\nGenerated $BRdistro-$cn.conf:"; cat /mnt/target$BRespmpoint/loader/entries/$BRdistro-$cn.conf )  >> /tmp/restore.log
          if [ "$BRdistro" = "Arch" ]; then
            ( echo -e "\nGenerated $BRdistro-$cn-fallback.conf:"; cat /mnt/target$BRespmpoint/loader/entries/$BRdistro-$cn-fallback.conf ) >> /tmp/restore.log
          fi
        fi
      done
    fi
  }

  # Set the bootloader, check for gptfdisk/gdisk packages, check backup archive if contains the selected bootloader, exit on errors
  set_bootloader() {
    if [ -n "$BRgrub" ]; then
      BRbootloader="Grub"
    elif [ -n "$BRsyslinux" ]; then
      BRbootloader="Syslinux"
    elif [ -n "$BRefistub" ]; then
      BRbootloader="EFISTUB/efibootmgr"
    elif [ -n "$BRbootctl" ]; then
      BRbootloader="Systemd/bootctl"
    fi

    if [ -n "$BRsyslinux" ]; then
      if [[ "$BRsyslinux" == *md* ]]; then
        for f in `grep -w "${BRsyslinux##*/}" /proc/mdstat | grep -oP '[vhs]d[a-z]'`; do
          BRdev="/dev/$f"
        done
      fi
      detect_partition_table_syslinux
      if [ ! "$BRdistro" = "Arch" ] && [ "$BRpartitiontable" = "gpt" ] && [ -z $(which sgdisk 2>/dev/null) ]; then
        echo -e "[${RED}ERROR${NORM}] Package gptfdisk/gdisk is not installed. Install the package and re-run the script" >&2
        BRabort="y"
      elif [ "$BRdistro" = "Arch" ] && [ "$BRpartitiontable" = "gpt" ] && [ "$BRmode" = "2" ] && [ -z $(which sgdisk 2>/dev/null) ]; then
        echo -e "[${RED}ERROR${NORM}] Package gptfdisk/gdisk is not installed. Install the package and re-run the script" >&2
        BRabort="y"
      elif [ "$BRdistro" = "Arch" ] && [ "$BRpartitiontable" = "gpt" ] && [ "$BRmode" = "1" ] && ! grep -Fq "bin/sgdisk" /tmp/filelist; then
        echo -e "[${RED}ERROR${NORM}] sgdisk not found in the archived system" >&2
        BRabort="y"
      fi
    fi

    if [ "$BRmode" = "1" ]; then
      if [ -n "$BRgrub" ] && ! grep -Fq "bin/grub-mkconfig" /tmp/filelist && ! grep -Fq "bin/grub2-mkconfig" /tmp/filelist; then
        echo -e "[${RED}ERROR${NORM}] Grub not found in the archived system" >&2
        BRabort="y"
      elif [ -n "$BRsyslinux" ]; then
        if ! grep -Fq "bin/extlinux" /tmp/filelist; then
          echo -e "[${RED}ERROR${NORM}] Extlinux not found in the archived system" >&2
          BRabort="y"
        fi
        if ! grep -Fq "bin/syslinux" /tmp/filelist; then
          echo -e "[${RED}ERROR${NORM}] Syslinux not found in the archived system" >&2
          BRabort="y"
        fi
      fi

      if [ -n "$BRgrub" ] || [ -n "$BRefistub" ] && [ -d "$BR_EFI_DETECT_DIR" ] && ! grep -Fq "bin/efibootmgr" /tmp/filelist; then
        echo -e "[${RED}ERROR${NORM}] efibootmgr not found in the archived system" >&2
        BRabort="y"
      fi
      if [ -n "$BRgrub" ] || [ -n "$BRefistub" ] || [ -n "$BRbootctl" ] && [ -d "$BR_EFI_DETECT_DIR" ] && ! grep -Fq "bin/mkfs.vfat" /tmp/filelist; then
        echo -e "[${RED}ERROR${NORM}] dosfstools not found in the archived system" >&2
        BRabort="y"
      fi
      if [ -n "$BRbootctl" ] && [ -d "$BR_EFI_DETECT_DIR" ] && ! grep -Fq "bin/bootctl" /tmp/filelist; then
        echo -e "[${RED}ERROR${NORM}] Bootctl not found in the archived system" >&2
        BRabort="y"
      fi
      if [ "$target_arch" = "x86_64" ]; then # Set the EFI Grub architecture in Restore Mode
        BRgrubefiarch="x86_64-efi"
      elif [ "$target_arch" = "i686" ]; then
        BRgrubefiarch="i386-efi"
      fi
    fi

    # Set the EFI Grub architecture in Transfer Mode
    if [ -n "$BRgrub" ] && [ "$BRmode" = "2" ] && [ -d "$BR_EFI_DETECT_DIR" ]; then
      if [ "$(uname -m)" = "x86_64" ]; then
        BRgrubefiarch="x86_64-efi"
      elif [ "$(uname -m)" = "i686" ]; then
        BRgrubefiarch="i386-efi"
      fi
    fi

    if [ -n "$BRgrub" ] && [ -d "$BR_EFI_DETECT_DIR" ]; then
      BRgrub="$BRespmpoint"
    fi

    if [ -n "$BRabort" ]; then
      clean_unmount_in
    fi
  }

  # Check backup archive and set the target system's architecture, exit on errors
  check_archive() {
    if [ -n "$BRhide" ]; then echo -en "${BR_SHOW}"; fi
    echo
    if [ -f /tmp/tar_error ]; then
      rm /tmp/tar_error
      echo -e "[${RED}ERROR${NORM}] Error reading archive" >&2
    else
      target_arch=$(grep -F 'target_architecture.' /tmp/filelist | cut -f2 -d".")
      if [ -z "$target_arch" ]; then
        target_arch="unknown"
      fi
      if [ ! "$(uname -m)" = "$target_arch" ]; then
        unset BRsource BRencpass
        echo -e "[${RED}ERROR${NORM}] Running and target system architecture mismatch or invalid archive" >&2
        echo -e "[${CYAN}INFO${NORM}] Target  system: $target_arch" >&2
        echo -e "[${CYAN}INFO${NORM}] Running system: $(uname -m)" >&2
        clean_unmount_in
      fi
    fi
  }

  # Generate target system's locales
  generate_locales() {
    if [ "$BRdistro" = "Arch" ] || [ "$BRdistro" = "Debian" ] || [ "$BRdistro" = "Gentoo" ]; then
      if [ -n "$BRwrap" ]; then echo "Generating locales..." > /tmp/wr_proc; fi
      echo -e "\nGenerating locales"
      chroot /mnt/target locale-gen
    fi
  }

  # Delete the working directory
  rm_work_dir() {
    sleep 1
    rm -r /mnt/target
  }

  # Early clean and unmount
  clean_unmount_in() {
    if [ -n "$BRwrap" ]; then echo "Unmounting..." > /tmp/wr_proc; fi
    echo -e "\n${BOLD}CLEANING AND UNMOUNTING${NORM}"
    cd ~
    rm "$BRmaxsize/downloaded_backup" 2>/dev/null
    if [ -n "$BRcustomparts" ]; then
      while read ln; do
        sleep 1
        echo -ne "${WRK}Unmounting $ln"
        OUTPUT=$(umount $ln 2>&1) && ok_status || error_status
      done < <(for i in ${BRumountparts[@]}; do BRdevice=$(echo $i | cut -f2 -d"="); echo $BRdevice; done | tac)
    fi

    if [ "$BRfsystem" = "btrfs" ] && [ -n "$BRrootsubvolname" ]; then
      echo -ne "${WRK}Unmounting $BRrootsubvolname"
      OUTPUT=$(umount $BRroot 2>&1) && ok_status || error_status
      sleep 1
      echo -ne "${WRK}Mounting $BRroot"
      OUTPUT=$(mount $BRroot /mnt/target 2>&1) && ok_status || error_status

      if [ -n "$BRsubvols" ]; then
        while read ln; do
          sleep 1
          echo -ne "${WRK}Deleting $BRrootsubvolname$ln"
          OUTPUT=$(btrfs subvolume delete /mnt/target/$BRrootsubvolname$ln 2>&1 1>/dev/null) && ok_status || error_status
        done < <(for i in ${BRsubvols[@]}; do echo $i; done | sort -r)
      fi

      echo -ne "${WRK}Deleting $BRrootsubvolname"
      OUTPUT=$(btrfs subvolume delete /mnt/target/$BRrootsubvolname 2>&1 1>/dev/null) && ok_status || error_status
    fi

    if [ -z "$BRSTOP" ]; then
      if [ -z "$BRdontckroot" ]; then
        rm -r /mnt/target/* 2>/dev/null
      fi
    fi
    clean_tmp_files

    echo -ne "${WRK}Unmounting $BRroot"
    sleep 1
    OUTPUT=$(umount $BRroot 2>&1) && (ok_status && rm_work_dir) || (error_status && echo -e "[${YELLOW}WARNING${NORM}] /mnt/target remained")
    exit
  }

  # Post clean and unmount
  clean_unmount_out() {
    if [ -n "$BRwrap" ]; then echo "Unmounting..." > /tmp/wr_proc; fi
    echo -e "\n${BOLD}CLEANING AND UNMOUNTING${NORM}"
    cd ~
    rm "$BRmaxsize/downloaded_backup" 2>/dev/null
    umount /mnt/target/dev/pts
    umount /mnt/target/proc
    umount /mnt/target/dev
    if [ -d "$BR_EFI_DETECT_DIR" ]; then
      umount /mnt/target/sys/firmware/efi/efivars
    fi
    umount /mnt/target/sys
    umount /mnt/target/run

    if [ -n "$BRcustomparts" ]; then
      while read ln; do
        sleep 1
        echo -ne "${WRK}Unmounting $ln"
        OUTPUT=$(umount $ln 2>&1) && ok_status || error_status
      done < <(for i in ${BRsorted[@]}; do BRdevice=$(echo $i | cut -f2 -d"="); echo $BRdevice; done | tac)
    fi

    echo -ne "${WRK}Unmounting $BRroot"
    if [ -f /mnt/target/target_architecture.$(uname -m) ]; then rm /mnt/target/target_architecture.$(uname -m); fi
    sleep 1
    OUTPUT=$(umount $BRroot 2>&1) && (ok_status && rm_work_dir) || (error_status && echo -e "[${YELLOW}WARNING${NORM}] /mnt/target remained")

    if [ -n "$BRwrap" ]; then cat /tmp/restore.log > /tmp/wr_log; fi
    clean_tmp_files
    exit
  }

  # Create tar progress
  tar_pgrs() {
    lastper=-1
    while read ln; do
      a=$((a + 1))
      per=$(($a*100/$total))
      if [ -n "$BRverb" ] && [[ $per -le 100 ]]; then
        echo -e "${YELLOW}[$per%] ${GREEN}$ln${NORM}"
      elif [[ $per -gt $lastper ]] && [[ $per -le 100 ]]; then
        lastper=$per
        if [ -n "$BRwrap" ]; then
          echo "Extracting: $per% ($a / $total Files)" > /tmp/wr_proc
        else
          echo -ne "\rExtracting: [${pstr:0:$(($a*24/$total))}${dstr:0:24-$(($a*24/$total))}] $per%"
        fi
      fi
    done
  }

  # Create rsync progress
  rsync_pgrs() {
    lastper=-1
    while read ln; do
      b=$((b + 1))
      per=$(($b*100/$total))
      if [ -n "$BRverb" ] && [[ $per -le 100 ]]; then
        echo -e "${YELLOW}[$per%] ${GREEN}$ln${NORM}"
      elif [[ $per -gt $lastper ]] && [[ $per -le 100 ]]; then
        lastper=$per
        if [ -n "$BRwrap" ]; then
          echo "Transferring: $per% ($b / $total Files)" > /tmp/wr_proc
        else
          echo -ne "\rTransferring: [${pstr:0:$(($b*24/$total))}${dstr:0:24-$(($b*24/$total))}] $per%"
        fi
      fi
    done
  }

  # Quick read backup archive
  read_archive() {
    if [ -n "$BRencpass" ] && [ "$BRencmethod" = "openssl" ]; then
      openssl aes-256-cbc -d -salt -in "$BRsource" -k "$BRencpass" 2>/dev/null | tar "$BRreadopts" - "${USER_OPTS[@]}" || touch /tmp/tar_error
    elif [ -n "$BRencpass" ] && [ "$BRencmethod" = "gpg" ]; then
      gpg -d --batch --passphrase "$BRencpass" "$BRsource" 2>/dev/null | tar "$BRreadopts" - "${USER_OPTS[@]}" || touch /tmp/tar_error
    else
      tar tf "$BRsource" "${USER_OPTS[@]}" || touch /tmp/tar_error
    fi
  }

  # Download backup archive
  run_wget() {
    if [ -n "$BRusername" ] || [ -n "$BRpassword" ]; then
      wget --user="$BRusername" --password="$BRpassword" -O "$BRsource" "$BRurl" --tries=2 || touch /tmp/wget_error
    else
      wget -O "$BRsource" "$BRurl" --tries=2 || touch /tmp/wget_error
    fi
  }

  # Start the log
  start_log() {
    echo -e "$BR_VERSION [$(date +%Y-%m-%d-%T)]\n"
    echo "[SUMMARY]"
    show_summary
    echo -e "\n[PROCESSING]"
  }

  # Check if root partition is given
  if [ -z "$BRroot" ]; then
    echo -e "[${RED}ERROR${NORM}] You must specify a target root partition" >&2
    exit
  fi

  # Check if backup archive is given in Restore Mode
  if [ "$BRmode" = "1" ] && [ -z "$BRuri" ]; then
    echo -e "[${RED}ERROR${NORM}] You must specify a backup archive" >&2
    exit
  fi

  # Find if backup archive is a local file or url
  if [[ "$BRuri" == /* ]]; then
    BRsource="$BRuri"
  else
    BRurl="$BRuri"
  fi

  # A nice info
  WRK="[${CYAN}WORKING${NORM}] "

  IFS=$'\n'

  # Add ESP, /home and /boot partitions in custom partitions array
  if [ -n "$BResp" ] && [ -n "$BRespmpoint" ]; then
    BRcustomparts+=("$BRespmpoint"="$BResp")
  fi
  if [ -n "$BRhomepart" ]; then
    BRcustomparts+=(/home="$BRhomepart")
  fi
  if [ -n "$BRbootpart" ]; then
    BRcustomparts+=(/boot="$BRbootpart")
  fi

  # Set default root mount options
  if [ -z "$BR_MOUNT_OPTS" ]; then
    BR_MOUNT_OPTS="defaults,noatime"
  fi

  # Exit if no partitions found by scan_parts
  if [ -z "$(scan_parts 2>/dev/null)" ]; then
    echo -e "[${RED}ERROR${NORM}] No partitions found" >&2
    exit
  fi

  # Check if working directory already exists
  if [ -d /mnt/target ]; then
    echo -e "[${RED}ERROR${NORM}] /mnt/target exists, aborting" >&2
    exit
  fi

  clean_tmp_files

  PATH="$PATH:/usr/sbin:/bin:/sbin"

  if [ -d "$BR_EFI_DETECT_DIR" ]; then
    echo -e "[${CYAN}INFO${NORM}] UEFI environment detected. (use -W to ignore)"
  fi

  check_input >&2
  detect_root_fs_size
  mount_all
  set_user_options

  if [ "$BRmode" = "1" ]; then
    echo -e "\n${BOLD}[BACKUP ARCHIVE]${NORM}"

    if [ -n "$BRurl" ]; then
      BRsource="$BRmaxsize/downloaded_backup"
      if [ -n "$BRwrap" ]; then
        run_wget 2>&1 | while read ln; do if [ -n "$ln" ]; then echo "Downloading: ${ln//.....}" > /tmp/wr_proc; fi; done
      else
        run_wget
      fi
      check_wget
    fi

    if [ -n "$BRsource" ]; then
      IFS=$DEFAULTIFS
      if [ -n "$BRhide" ]; then echo -en "${HIDE}"; fi
      if [ -n "$BRwrap" ]; then echo "Please wait while checking and reading archive..." > /tmp/wr_proc; fi
      read_archive | tee /tmp/filelist | while read ln; do a=$((a + 1)) && echo -en "\rChecking and reading archive ($a Files) "; done

      IFS=$'\n'
      check_archive
    fi
  fi

  detect_distro
  set_bootloader
  detect_root_map

  if [ "$BRmode" = "1" ] && [ "$BRdistro" = "Gentoo" ] && [ -z "$BRgenkernel" ] && ! grep -Fq "bin/genkernel" /tmp/filelist; then
    echo -e "[${YELLOW}WARNING${NORM}] Genkernel not found in the archived system. (you can disable this check with -D)" >&2
    clean_unmount_in
  fi

  if [ "$BRmode" = "2" ]; then set_rsync_opts; fi
  if [ -n "$BRbootloader" ]; then set_kern_opts; fi

  echo -e "\n${BOLD}[SUMMARY]${CYAN}"
  show_summary
  echo -ne "${NORM}"

  while [ -z "$BRquiet" ]; do
    echo -e "${BOLD}"
    read -p "Continue? [Y/n]: " an
    echo -ne "${NORM}"
    if [ -z "$an" ]; then an=y; fi

    if [ "$an" = "y" ] || [ "$an" = "Y" ]; then
      break
    elif [ "$an" = "n" ] || [ "$an" = "N" ]; then
      clean_unmount_in
    else
      echo -e "${RED}Please enter a valid option${NORM}"
    fi
  done

  start_log > /tmp/restore.log
  if [ -n "$BRhide" ]; then echo -en "${HIDE}"; fi
  echo -e "\n${BOLD}[PROCESSING]${NORM}"
  IFS=$DEFAULTIFS

  if [ "$BRmode" = "1" ]; then
    total=$(cat /tmp/filelist | wc -l)
    sleep 1
    run_tar 2>>/tmp/restore.log | tar_pgrs
    echo

  elif [ "$BRmode" = "2" ]; then
    if [ -n "$BRwrap" ]; then echo "Please wait while calculating files..." > /tmp/wr_proc; fi
    run_calc | while read ln; do a=$((a + 1)) && echo -en "\rCalculating: $a Files"; done
    sleep 1
    total=$(cat /tmp/filelist | wc -l)
    echo
    run_rsync 2>>/tmp/restore.log | rsync_pgrs
    echo
  fi

  if [ -n "$BRhide" ]; then echo -en "${SHOW}"; fi

  echo -e "\nGenerating fstab"
  cp /mnt/target/etc/fstab /mnt/target/etc/fstab-old
  generate_fstab > /mnt/target/etc/fstab
  cat /mnt/target/etc/fstab
  detect_initramfs_prefix

  while [ -z "$BRquiet" ]; do
    echo -e "${BOLD}"
    read -p "Edit fstab? [y/N]: " an
    echo -ne "${NORM}"
    if [ -z "$an" ]; then an=n; fi

    if [ "$an" = "y" ] || [ "$an" = "Y" ]; then
      PS3="Enter number: "
      echo -e "\n${CYAN}Select editor${NORM}"
      select BReditor in "nano" "vi"; do
        if [[ "$REPLY" = [1-2] ]]; then
          $BReditor /mnt/target/etc/fstab
          ( echo -e "\nEdited fstab:"; cat /mnt/target/etc/fstab ) >> /tmp/restore.log
          break
        else
          echo -e "${RED}Please select a valid option${NORM}"
        fi
      done
      break
    elif [ "$an" = "n" ] || [ "$an" = "N" ]; then
      break
    else
      echo -e "${RED}Please select a valid option${NORM}"
    fi
  done

 ( prepare_chroot; build_initramfs; generate_locales; install_bootloader) 1> >(tee -a /tmp/restore.log ) 2>&1

   sleep 1

  if [ -z "$BRquiet" ]; then
    exit_screen; read -s
  else
    exit_screen_quiet
  fi
  sleep 1
  clean_unmount_out
fi
