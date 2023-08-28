ttft="kubernetes_config_map_v1"
if [[ $1 != "" ]]; then
    ans=$(echo $1)
else
    ans=$(kubectl get namespaces -o json | jq .items[].metadata.name | tr -d '"')
fi
echo "ans=$ans"
#ans="default"
for ns in $ans; do
    ns=$(echo $ns | tr -d '"')
    #   if [[ "$ns" != kube-* ]]; then
    echo "namespace=$ns"
    comm=$(kubectl get configmaps -n $ns -o json | jq .items[].metadata.name)
    echo "configmaps ...."
    echo "$comm"
    for i in $comm; do
        cname=$(echo $i | tr -d '"')
        echo "configmap $cname in namecpace $ns"
        rname=${cname//:/_} && rname=${rname//./_} && rname=${rname//\//_}
        fn=$(printf "%s__%s__%s.tf" $ttft $ns $rname)
        printf "resource \"%s\" \"%s__%s\" {\n" $ttft $ns $rname >$fn
        printf "}\n" $ttft $ns $rname >>$fn

        ticomm=$(printf "terraform import %s.%s__%s %s/%s" $ttft $ns $rname $ns $cname)
        echo "----------->"
        echo $ticomm
        
        eval $ticomm
        exit
        tscomm=$(printf "terraform state show -no-color %s.%s__%s" $ttft $ns $rname)
        echo $tscomm
        eval $tscomm >t1.txt

        rm -f $fn
        #cat t2.txt | perl -pe 's/\x1b.*?[mGKH]//g' >t1.txt
        file="t1.txt"

        while IFS= read line; do
            skip=0
            # display $line or do something with $line
            t1=$(echo "$line")
            if [[ ${t1} == *"="* ]]; then
                tt1=$(echo "$line" | cut -f1 -d'=' | tr -d ' ')
                tt2=$(echo "$line" | cut -f2- -d'=')

                if [[ ${tt1} == "id" ]]; then skip=1; fi
                if [[ ${tt1} == "self_link" ]]; then skip=1; fi
                if [[ ${tt1} == "uid" ]]; then skip=1; fi
                if [[ ${tt1} == "resource_version" ]]; then skip=1; fi
                if [[ ${tt1} == "generation" ]]; then skip=1; fi
                if [[ ${tt1} == "active_deadline_seconds" ]]; then skip=1; fi
                if [[ ${tt1} == "ttl_seconds_after_finished" ]]; then skip=1; fi
                if [[ ${tt1} == "mount_path" ]]; then
                    printf "mount_propagation = \"None\"\n" >>$fn
                fi
                if [[ ${tt1} == "vpc_id" ]]; then
                    tt2=$(echo $tt2 | tr -d '"')
                    t1=$(printf "%s = aws_vpc.%s.id" $tt1 $tt2)
                fi

            fi
            if [ "$skip" == "0" ]; then
                #echo $skip $t1
                echo $t1 >>$fn
            fi

        done <"$file"
        sed -i 's/<<~/<</g' $fn
        # -f *.tf.bak
    done
    #   fi
done
terraform fmt
