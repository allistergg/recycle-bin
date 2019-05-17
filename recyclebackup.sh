#!/bin/bash



function recycle() {

	if [[ ! -d ${file} || (dflag -gt 0 && -z "$(ls -A ${file})") || (rflag -gt 0 && fflag -gt 0)]]; then 
	mv ${file} -f ~/recyclebin; if [[ vflag -gt 0 ]]; then echo "...recycling ${file}"; fi; echo `readlink -f ${file}` >> ~/recyclebin/.recycle.log
	elif [[ ! dflag -gt 0 && ! rflag -gt 0 ]]; then  echo "cannot recycle directory. Use -d to recycle empty directories. Use -r to recycle non-empty directories"
	elif [[ rflag -gt 0 ]]; then echo "Are you sure you want to recursively recycle this directory and all of its subdirectories and files?"
		read response
		if [[ $response == "y" ]];
			then
				mv ${file} ~/recyclebin; 
				if [[ vflag -gt 0 ]]; 
					then 
						echo "...recycling ${file}"; 
				fi; 
				echo `readlink -f ${file}` >> ~/recyclebin/.recycle.log
		fi
	else echo "directory not empty. -d only deletes empty directories. use -r to recycle non-empty directories"
	fi
}


function check_write_permission() {
	if [[ -w ${file} ]]; then recycle
	elif [[ -f ${file} || -d ${file} ]]; then  echo "You do not have write permission for this file. Are you sure you want to recycle ${file}?"
		read response
		if [[ $response == 'y' ]];
			then recycle
		fi
	fi
}

function usage() {
	
	cat <<EOF
	Usage: $0 [options] <file1> [...files]
		-i : interactive mode, prompts for every file
		-I : interactive mode, doesn't prompt for 3 or more files
		-r : recursive mode, use to recycle directories
		-d : directory, use to recycle empty directories
		-h : help, displays usage
		-s : restores files to location before recycle
		-v : verbose, shows files being recycled
		-f : force deletion of write-protected files
		-e : empties recycle bin, deleting files permanently
EOF
	exit 0
}

function restore() {

	if [[ $# -gt 0 ]]; then
		for file in $@; do mv -i ~/recyclebin/${file} `grep ${file}$ ~/recyclebin/.recycle.log | head -1` && sed -i "0,/\($file$\)/d" ~/recyclebin/.recycle.log ;done 
	else
		for file in `ls ~/recyclebin`; 
			do mv -i ~/recyclebin/${file} `grep ${file}$ ~/recyclebin/.recycle.log | head -1` && sed -i "0,/\($file$\)/d" ~/recyclebin/.recycle.log ;done;
	fi
		
}


function interactive() {

	for file in $@; 
		do echo "Are you sure you want to recycle ${file}?" 
		read response 
		if [[ $response == 'y' ]];
			then recycle
	        
		else 
			continue
		fi; done
}

function multiple_interactive() {

	if [[ $# -gt 2 ]] 
		then
			echo "Are you sure you want to recycle $@?"
			read response
			if [[ $response == "y" ]]
				then for file in $@
					do recycle; done
					
			fi
		else
			interactive $@;
		fi
	

}

function empty() {
	if [[ $# -eq 0 ]]; then 
	echo "Are you sure you want to empty your recycle bin? This will permanently remove all `ls -a ~/recyclebin | wc -l` files in the recycle bin. This is irreversible"
	read response
	if [[ $response == "y" ]]
		then rm -rf ~/recyclebin/.recycle.log ~/recyclebin/*
	fi
	else echo "Are you sure you want to permanently delete $@ ? This is irreversible."
	read response
	if [[ $response == "y" ]];
		then for file in $@; do rm -rf ~/recyclebin/${file}; sed -i "/\($file$\)/d" ~/recyclebin/.recycle.log ; done
	fi
	fi
}




mkdir -p ~/recyclebin

while getopts dfhrsiIve option
do
  case $option in
  d)  dflag=1;;
  e)  eflag=1;;
  f)  fflag=1 iflag=0 Iflag=0;;
  i)  iflag=1 fflag=0;;
  I)  Iflag=1 fflag=0;;
  h|\?)  usage;;
  r)  rflag=1;;
  s)  sflag=1;;
  v)  vflag=1;;
esac
done
if [ ! -z "$aflag" ]; then
  printf 'Option a specified\n'
fi
if [ ! -z "$bflag" ]; then
  printf 'Option -b specified\n'
fi
shift $((OPTIND-1))
# echo "you provided the arguments:" "$@"

if [[ $# -gt 0 && sflag -eq 0 && iflag -eq 0 && Iflag -eq 0 && eflag -eq 0 ]];
	then 
		for file in $@; 
			do 
				if [[ fflag -gt 0 ]];
					then
						recycle 2>/dev/null
				else 
					check_write_permission
				fi
			done;
	
	elif [[ iflag -eq 1 ]]
	then
		interactive $@
	elif [[ sflag -eq 1 ]]
	then
		restore $@	
	elif [[ Iflag -eq 1 ]]
	then 
		multiple_interactive $@
	elif [[ eflag -eq 1 ]]
	then
		empty $@
	

	else
		echo "You must specify at least one file to recycle"
		usage
fi
