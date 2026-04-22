import boto3
import json

def lambda_handler(event, context):
    # 1. Connexion au service EC2 de LocalStack
    # On précise l'URL locale car la Lambda tourne "dans" LocalStack
    ec2 = boto3.client('ec2', endpoint_url='http://localhost.localstack.cloud:4566', region_name='us-east-1')

    # 2. Identification de la cible
    # REMPLACE CET ID PAR LE TIEN (celui qui commence par i-)
    instance_id = "i-d159f4d44bc8c2f4a"

    # 3. Récupération de l'action demandée (?action=start ou ?action=stop)
    # Si rien n'est précisé, on choisit 'start' par défaut
    params = event.get('queryStringParameters') or {}
    action = params.get('action', 'start')

    try:
        if action == 'stop':
            ec2.stop_instances(InstanceIds=[instance_id])
            message = f"Succès : Instance {instance_id} en cours d'arrêt."
        else:
            ec2.start_instances(InstanceIds=[instance_id])
            message = f"Succès : Instance {instance_id} en cours de démarrage."

        return {
            'statusCode': 200,
            'body': json.dumps({'message': message})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
