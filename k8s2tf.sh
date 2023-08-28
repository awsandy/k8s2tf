usage() {
    echo "Usage: $0 [-p <profile>] [-c] [-v] [-r <region>] [-t <type>] [-h] [-d] [-n] <namespace name>"
    echo "       -p <profile> specify the AWS profile to use (Default=\"default\")"
    echo "       -c <yes|no> (default=no) Continue from previous run"
    echo "       -f <yes|no> (default=no) fast forward, use with -c"
    echo "       -r <region>  specify the AWS region to use (Default=the aws command line setting)"
    echo "       -v <yes|no> (default=no) Stop after terraform validate step"
    echo "       -h           Help - this message"
    echo "       -d <yes|no|st|info> (default=no)   Debug - lots of output if info"
    echo "       -n <namespace> which namespace to use"
    echo "       -t <type>   choose a sub-type of K8s resources to get:"
    echo "           configmap"
    echo "           serviceaccount"
    exit 1
}

x="no"
p="default" # profile
f="no"
v="no"
r="no" # region
c="no" # combine mode
d="no"
n="no"

while getopts ":p:r:x:f:v:t:i:c:d:h:s:" o; do
    case "${o}" in
    h)
        usage
        ;;
    i)
        i=${OPTARG}
        ;;
    t)
        t=${OPTARG}
        ;;
    r)
        r=${OPTARG}
        ;;
    x)
        x="yes"
        ;;
    p)
        p=${OPTARG}
        ;;
    f)
        f="yes"
        ;;
    v)
        v="yes"
        ;;
    c)
        c="yes"
        ;;
    d)
        d=${OPTARG}
        ;;
    n)
        n=${OPTARG}
        ;;

    *)
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

trap ctrl_c INT

function ctrl_c() {
    echo "Requested to stop."
    exit 1
}


if [ "$d" = "info" ]; then
    set -x
    echo "CAUTION - lots of output, potentially including sensitive information"
fi

if [ ! -z ${AWS_PROFILE+x} ]; then
    p=$(echo $AWS_PROFILE)
    echo "profile $AWS_PROFILE set from env variables"
fi

export aws2tfmess="# File generated by aws2tf see https://github.com/aws-samples/aws2tf"

if [ -z ${AWS_ACCESS_KEY_ID+x} ] && [ -z ${AWS_SECRET_ACCESS_KEY+x} ]; then
    mysub=$(aws sts get-caller-identity --output json --profile $p | jq .Account | tr -d '"')
else
    mysub=$(aws sts get-caller-identity --output json | jq .Account | tr -d '"')
fi

if [ "$r" = "no" ]; then

    if [ ! -z ${AWS_DEFAULT_REGION+x} ]; then
        r=$(echo $AWS_DEFAULT_REGION)
        echo "region $AWS_DEFAULT_REGION set from env variable AWS_DEFAULT_REGION"
    fi

    if [ ! -z ${AWS_REGION+x} ]; then
        r=$(echo $AWS_REGION)
        echo "region $AWS_REGION set from env variable AWS_REGION"
    fi
    if [ "$r" = "no" ]; then
        r=$(aws configure get region)
        echo "Getting region from aws cli = $r"
    fi
fi

if [ "$t" == "no" ]; then t="*"; fi



if [ "$1" == "" ]; then
echo "EKS cluster name must be supplied" && exit
fi
mycluster=$1
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

printf "terraform {\n" > k8s.tf
printf "  required_version = \"~> 1.5.0\"\n" >> k8s.tf
printf "  required_providers {\n" >> k8s.tf
printf "    kubernetes = {\n" >> k8s.tf
printf "      source = \"hashicorp/kubernetes\"\n" >> k8s.tf
printf "      version = \"~>2.23.0\"\n" >> k8s.tf
printf "    }\n" >> k8s.tf   
printf "  }\n" >> k8s.tf
printf "}\n" >> k8s.tf

printf "provider \"kubernetes\" {\n" >> k8s.tf
printf "config_path    = \"~/.kube/config\"\n" >> k8s.tf
printf "}\n" >> k8s.tf

cat k8s.tf

if [ "$c" == "no" ]; then
    echo "terraform init -upgrade"
    terraform init -upgrade -no-color 2>&1 | tee -a import.log
    if [[ $? -ne 0 ]];then 
        echo "Terraform INit failed - exiting ....."
        exit
    fi
else
    if [[ ! -d .terraform ]]; then
        echo ""
        echo "There doesn't appear to be a previous run for aws2tf"
        echo "missing .terraform directory in $mysub"
        echo "exiting ....."
        exit
    fi
fi
pwd

pre="4*"
t="*"

if [ "$t" == "configmap" ]; then pre="404*"; fi


date

lc=0
echo "t=$t"
echo "loop through providers"
pwd
for com in `ls ../../scripts/$pre-*$t*.sh | cut -d'/' -f4 | sort -g`; do    
        echo "$com"
        docomm=". ../../scripts/$com $n"
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
terraform validate

if [ "$v" = "yes" ]; then
    exit
fi

echo "Terraform Plan ..."
terraform plan


echo "code in generated/tf.$mycluster"
