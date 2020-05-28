mycluster="ateks1"
f="no"
mkdir -p generated/tf.$mycluster
cd generated/tf.$mycluster
if [ "$f" = "no" ]; then
    echo "Cleaning generated/tf.$mycluster"
    rm -f import.log resources*.txt
    rm -f processed.txt
    rm -f *.tf *.json
    rm -f terraform.*
    rm -rf .terraform
else
    sort -u processed.txt > pt.txt
    cp pt.txt processed.txt
fi
# write the k8s.tf file

printf "provider \"kubernetes\" {}\n" > k8s.tf

terraform init

pre="440*"
t="*"

date

lc=0
echo "t=$t"
echo "loop through providers"
pwd
for com in `ls ../../scripts/$pre-*$t*.sh | cut -d'/' -f4 | sort -g`; do    
        echo "$com"
        docomm=". ../../scripts/$com $i"
        if [ "$f" = "no" ]; then
            eval $docomm 2>&1 | tee -a import.log
        else
            grep "$docomm" processed.txt
            if [ $? -eq 0 ]; then
                echo "skipping $docomm"
            else
                eval $docomm 2>&1 | tee -a import.log
            fi
        fi
        lc=`expr $lc + 1`

        file="import.log"
        while IFS= read -r line
        do
            if [[ "${line}" == *"Error"* ]];then
          
                if [[ "${line}" == *"Duplicate"* ]];then
                    echo "Ignoring $line"
                else
                    echo "Found Error: $line exiting .... (pass for now)"
                    pass
                fi
            fi

        done <"$file"

        echo "$docomm" >> processed.txt
        
    
    rm -f terraform*.backup
done

#########################################################################


date


echo "---------------------------------------------------------------------------"
echo "aws2tf output files are in generated/tf.$mycluster"
echo "---------------------------------------------------------------------------"

echo "Terraform fmt ..."
terraform fmt
echo "Terraform validate ..."
terraform validate .

if [ "$v" = "yes" ]; then
    exit
fi

echo "Terraform Plan ..."
terraform plan .


echo "code in generated/tf.$mycluster"
