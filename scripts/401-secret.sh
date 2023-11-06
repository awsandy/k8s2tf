ttft="kubernetes_secret_v1"
ans=`kubectl get namespaces -o json | jq .items[].metadata.name | tr -d '"'`
#echo $ans
#ans="default"
for ns in $ans; do
    ns=`echo $ns | tr -d '"'`
    if [[ $1 != "" ]]; then
        if [[ $1 != $ns ]]; then continue; fi
    fi
    if [[ "$ns" != kube-* ]]; then
        echo "namespace = $ns"
        comm=`kubectl get secret -n $ns -o json | jq '.items[].metadata.name'`
        #echo "comm=$comm"
        for i in $comm; do
            cname=`echo $i | tr -d '"'`
            rname=${cname//:/_} && rname=${rname//./_} && rname=${rname//\//_}

            echo $cname
            un=$(kubectl get secret $cname -n $ns -o json | jq '.data.username' | tr -d '"') 
            pw=$(kubectl get secret $cname -n $ns -o json | jq '.data.password' | tr -d '"')
            fn=`printf "%s__%s__%s.tf" $ttft $ns $cname`
            printf "resource \"%s\" \"%s__%s\" {" $ttft $ns $rname > $fn
            printf "}\n" >> $fn
            
            comm=`printf "terraform import %s.%s__%s %s/%s" $ttft $ns $rname $ns $cname`
            echo $comm
            eval $comm
            comm=`printf "terraform state show %s.%s__%s" $ttft $ns $rname`
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
                    if [[ ${tt1} == "data" ]];then 
                        if [[ ${un} == "null" ]];then 
                             skip=1;
                        else    
                            printf "data = {\n" >> $fn
                            printf "username = \"${un}\"\n" >> $fn
                            printf "password = \"${pw}\"\n" >> $fn
                            printf "}\n" >> $fn 
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
        done
    fi
done
exit
terraform fmt
