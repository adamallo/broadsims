#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -v LD_LIBRARY_PATH
#$ -v PATH

if [[ $# -eq 1 ]]
then
        if [[ -d $1 ]] && [[ -n "$SGE_TASK_ID" ]]
        then
                dir=$1
                id=$(printf "%05d" $SGE_TASK_ID)
        elif [[ -d $1 ]]
        then
                echo "Error, folder_id not specified without using a job array. Usage: script simphy_dir [folder_id]"
                exit
        else
                echo "Error, $1 is not a valid directory. Usage: script simphy_dir [folder_id]"
                exit
        fi

elif [[ $# -eq 2 ]]
then
        if [[ -d $1 ]] && [[ -d $1/$2 ]]
        then
                dir=$1
                id=$2
        elif [[ -d $1 ]]
        then
                echo "Error, $2 is not a valid subdirectory of $1. Usage: script simphy_dir [folder_id]"
                exit
        else
                echo "Error, $1 is not a valid directory. Usage: script simphy_dir [folder_id]"
                exit
        fi

else
        echo "Error. Usage: script simphy_dir [folder_id]"
        exit
fi

cd $dir/$id
rm -f 
infile=$(ls g_trees* | head -n 1)
tips=$(cat $infile | sed -e 's/:[^,)]*//g' -e 's/(//g' -e 's/)//g' -e 's/,/ /g' -e 's/;/ /g' | tr '\n' ' ')
tips=( $tips )
tips=$(printf "%s\n" "${tips[@]}")
species=$(echo $tips | sed -e 's/\([0-9]*\)_[0-9]*_[0-9]*/\1/g')
species=( $species )
species=$(printf "%s\n" "${species[@]}" | sort | uniq)
species=( $species )
tips=( $tips )
tree="("
for sp in ${species[@]}
do
	sp_tips=$(printf "%s\n" "${tips[@]}" | sed -n "/^${sp}_/p" | paste -s -d ",")
	sp_tips="($sp_tips),"
	tree="$tree$sp_tips"
	#printf "%s\n" "${tips[@]}" > umm
	#exit
        #n_tips=$(echo $sp_tips | grep -o " " | wc -l)
        #n_tips=$(($n_tips+1))
        #echo $sp $n_tips $sp_tips >> $2
done
tree=$(echo $tree | sed 's/.$//')
tree="${tree});"
echo $tree
echo $tree > constraintTree.trees
exit
