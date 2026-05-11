#!/bin/bash

# Configuration dynamique de l'URL publique (Zéro Localhost)
PUBLIC_ENDPOINT="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
AWS_CMD="aws --endpoint-url=$PUBLIC_ENDPOINT --region us-east-1"

echo "⏳ Préparation de l'environnement..."
zip -q function.zip lambda_function.py
$AWS_CMD lambda delete-function --function-name ControlEC2 2>/dev/null || true
$AWS_CMD lambda create-function --function-name ControlEC2 --runtime python3.9 --handler lambda_function.lambda_handler --role arn:aws:iam::000000000000:role/lambda-role --zip-file fileb://function.zip > /dev/null

echo "📦 Création d'une instance EC2 de test..."
$AWS_CMD ec2 run-instances --image-id ami-df5136b6 --count 1 --instance-type t2.micro > /dev/null

echo "🌐 Configuration de l'API Gateway"
API_ID=$($AWS_CMD apigateway create-rest-api --name 'EC2PilotAPI' --query 'id' --output text)
ROOT_ID=$($AWS_CMD apigateway get-resources --rest-api-id "$API_ID" --query 'items[0].id' --output text)

# Fonction pour créer une route GET (start, stop, status)
create_route() {
    local ROUTE=$1
    local RES_ID=$($AWS_CMD apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part "$ROUTE" --query 'id' --output text)
    $AWS_CMD apigateway put-method --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method GET --authorization-type "NONE" > /dev/null
    $AWS_CMD apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RES_ID" --http-method GET --type AWS_PROXY --integration-http-method POST --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:ControlEC2/invocations" > /dev/null
}

create_route "start"
create_route "stop"
create_route "status"

$AWS_CMD apigateway create-deployment --rest-api-id "$API_ID" --stage-name prod > /dev/null

echo "------------------------------------------------"
echo "✅ ARCHITECTURE DÉPLOYÉE !"
echo "Cliquez sur ces liens dans votre navigateur :"
echo "START  : $PUBLIC_ENDPOINT/restapis/$API_ID/prod/_user_request_/start"
echo "STOP   : $PUBLIC_ENDPOINT/restapis/$API_ID/prod/_user_request_/stop"
echo "STATUS : $PUBLIC_ENDPOINT/restapis/$API_ID/prod/_user_request_/status"
echo "------------------------------------------------"
