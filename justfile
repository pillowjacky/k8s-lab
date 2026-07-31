decrypt:
    ./scripts/decrypt.sh

encrypt:
    ./scripts/encrypt.sh

[working-directory('terraform')]
apply env="default":
    terraform apply "{{ env }}.tfplan"
    rm -f "{{ env }}.tfplan"

[working-directory('terraform')]
init env="default":
    terraform init -backend-config="./envs/{{ env }}.tfbackend"

[working-directory('terraform')]
plan env="default":
    terraform plan -var-file="./envs/{{ env }}.tfvars" -out="{{ env }}.tfplan"

[working-directory('terraform')]
plan-destroy env="default":
    terraform plan -destroy -var-file="./envs/{{ env }}.tfvars" -out="{{ env }}.tfplan"
