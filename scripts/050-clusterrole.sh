ttft="kubernetes_cluster_role_v1"

        comm=`kubectl get clusterrole -o json | jq .items[].metadata.name`
        #echo "comm=$comm"
        for i in $comm; do
            cname=`echo $i | tr -d '"'`
            echo $cname
            if [[ ${cname} != *":"* ]] ;then
            fn=`printf "%s__%s.tf" $ttft $cname`
            printf "resource \"%s\" \"%s\" {" $ttft $cname > $fn
            printf "}\n" >> $fn
            
            comm=`printf "terraform import %s.%s %s" $ttft $cname $cname`
            echo $comm
            eval $comm
            comm=`printf "terraform state show %s.%s" $ttft $cname`
            echo $comm
            eval $comm > t2.txt
            
            rm -f $fn
            cat t2.txt | perl -pe 's/\x1b.*?[mGKH]//g' > t1.txt
            file="t1.txt"
            
            while IFS= read line
            do
				skip=0
                # display $line or do something with $line
                t1=`echo "$line"` 
                if [[ ${t1} == *"="* ]];then
                    tt1=`echo "$line" | cut -f1 -d'=' | tr -d ' '` 
                    tt2=`echo "$line" | cut -f2- -d'=' | tr -d ' '`

                    if [[ ${tt1} == "id" ]];then skip=1; fi  
                    if [[ ${tt1} == "self_link" ]];then skip=1; fi
                    if [[ ${tt1} == "uid" ]];then skip=1; fi 
                    if [[ ${tt1} == "resource_version" ]];then skip=1; fi             
                    if [[ ${tt1} == "default_secret_name" ]];then skip=1; fi
                    if [[ ${tt1} == "generation" ]];then skip=1; fi
                    if [[ ${tt1} == "active_deadline_seconds" ]];then skip=1; fi
                    if [[ ${tt1} == "mount_path" ]];then
                        printf "mount_propagation = \"None\"\n" >> $fn
                    fi
                    if [[ ${tt1} == "api_groups" ]];then
                        if [[ "$tt2" == "[]" ]]; then
                            skip=1
                        fi
                    fi

                fi
                if [ "$skip" == "0" ]; then
                    #echo $skip $t1
                    echo $t1 >> $fn
                fi
                
            done <"$file"
            #sed -i 's/<<~/<</g' $fn
            rm -f *.tf.bak
            else
            echo "Skipping $cname"
            fi
        done
    

exit
terraform fmt
