pwd
ttft="kubernetes_config_map"
kmaps=`kubectl get configmaps -n kube-system -o json | jq .items[].metadata.name`
for i in $kmaps; do
    echo $i
    cname=`echo $i | tr -d '"'`
    printf "resource \"%s\" \"%s__%s\" {" $ttft $ns $cname > $ttft.$cname.tf
    printf "}" $cname >> $ttft.$cname.tf
    terraform import $ttft.default__kube-bench-node default/kube-bench-node
    exit
    #terraform import $ttft.$ns__$cname $ns/$cname
    terraform state show $ttft.$ns__$cname > t2.txt
    rm $ttft.$cname.tf
    cat t2.txt | perl -pe 's/\x1b.*?[mGKH]//g' > t1.txt
            #	for k in `cat t1.txt`; do
            #		echo $k
            #	done
    file="t1.txt"
    fn=`printf "%s__%s.tf" $ttft $cname`

            while IFS= read line
            do
				skip=0
                # display $line or do something with $line
                t1=`echo "$line"` 
                if [[ ${t1} == *"="* ]];then
                    tt1=`echo "$line" | cut -f1 -d'=' | tr -d ' '` 
                    tt2=`echo "$line" | cut -f2- -d'='`
                    if [[ ${tt1} == "id" ]];then skip=1; fi  
                    if [[ ${tt1} == "self_link" ]];then skip=1; fi
                    if [[ ${tt1} == "uid" ]];then skip=1; fi 
                    if [[ ${tt1} == "resource_version" ]];then skip=1; fi             
                    if [[ ${tt1} == "generation" ]];then skip=1; fi 
                    if [[ ${tt1} == "vpc_id" ]]; then
                        tt2=`echo $tt2 | tr -d '"'`
                        t1=`printf "%s = aws_vpc.%s.id" $tt1 $tt2`
                    fi

                fi
                if [ "$skip" == "0" ]; then
                    #echo $skip $t1
                    echo $t1 >> $fn
                fi
                
            done <"$file"
            sed -i 's/<<~/<</g' $fn
            rm -f *.tf.bak
done
terraform fmt
