#!/bin/sh
set -e


#copy file
if [[ -z $TF_ROOT ]]; then
	echo "error=> set: export TF_ROOT=/Users/hejie/Desktop/app_new/tensorflow-master/"
else
	if [ -d $TF_ROOT ]; then #the dir existed
		if [ -d "$TF_ROOT/tensorflow/contrib" ]; then #is real tensorflow dir
			
			
			#check tf version
			set +e
			tf_ver1_4=`cat $TF_ROOT/RELEASE.md | grep "1.4.0"`
			tf_ver1_5=`cat $TF_ROOT/RELEASE.md | grep "1.5.0"`
			set -e

			if [ ! "$tf_ver1_5" = "" ]; then
				echo "error=> current tensorflow version is high than 1.4.0, maybe cause error!!!"
			else
				if [ "$tf_ver1_4" = "" ]; then
					echo "error=> current tensorflow version is low than 1.4.0, maybe cause error!!!"
				else
					#normal
					echo "ok=> current version: $tf_ver1_4"
					#copy file
					cp makefile/* "$TF_ROOT/tensorflow/contrib/makefile/."
					cp tf_op_files.txt "$TF_ROOT/tensorflow/contrib/makefile/."
					cp ops_to_register.h "$TF_ROOT/tensorflow/core/framework/."
					echo "ok=> Ready!"
				fi
			fi
			
			
			
		else
			echo "error=> the $TF_ROOT is not tensorflow dir"
		fi
	else
		echo "error=> no exist: $TF_ROOT"
	fi
fi

