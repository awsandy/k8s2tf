ttft="kubernetes_ingress"
ans=`kubectl get namespaces -o json | jq .items[].metadata.name | tr -d '"'`
#echo $ans
#ans="default"
for ns in $ans; do
    ns=`echo $ns | tr -d '"'`
    if [[ "$ns" != kube-* ]]; then
        #echo "namespace = $ns"
        comm=`kubectl get ingress -n $ns -o json | jq .items[].metadata.name`
        #echo "comm=$comm"
        for i in $comm; do
            cname=`echo $i | tr -d '"'`
            echo $cname
            fn=`printf "%s__%s__%s.tf" $ttft $ns $cname`
            printf "resource \"%s\" \"%s__%s\" {" $ttft $ns $cname > $fn
            printf "}\n" >> $fn
            
            comm=`printf "terraform import %s.%s__%s %s/%s" $ttft $ns $cname $ns $cname`
            echo $comm
            eval $comm
            comm=`printf "terraform state show %s.%s__%s" $ttft $ns $cname`
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
                    if [[ ${tt1} == "load_balancer_ingress" ]];then skip=1; fi
                    if [[ ${tt1} == "mount_path" ]];then
                        printf "mount_propagation = \"None\"\n" >> $fn
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
