import boto3
import json
import os

# Communication interne LocalStack (zéro localhost)
endpoint_url = f"http://{os.environ.get('LOCALSTACK_HOSTNAME')}:4566"

def lambda_handler(event, context):
    ec2 = boto3.client('ec2', endpoint_url=endpoint_url, region_name='us-east-1')
    
    # On récupère l'action directement depuis le chemin de l'URL (start, stop ou status)
    path = event.get('path', '')
    action = path.split('/')[-1] 
    
    # Récupération automatique de la première instance disponible pour le test
    instances = ec2.describe_instances()
    if not instances['Reservations']:
        return {'statusCode': 404, 'body': json.dumps("Erreur : Aucune instance EC2 trouvée.")}
    
    instance_id = instances['Reservations'][0]['Instances'][0]['InstanceId']
    current_state = instances['Reservations'][0]['Instances'][0]['State']['Name']

    try:
        if action == 'start':
            ec2.start_instances(InstanceIds=[instance_id])
            msg = f"L'instance {instance_id} a été DÉMARRÉE."
        elif action == 'stop':
            ec2.stop_instances(InstanceIds=[instance_id])
            msg = f"L'instance {instance_id} a été ARRÊTÉE."
        elif action == 'status':
            msg = f"L'instance {instance_id} est actuellement : {current_state}"
        else:
            msg = f"Action '{action}' non reconnue."

        # On renvoie du JSON qui sera affiché proprement dans le navigateur
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                "service": "Pilotage EC2",
                "action_demandee": action,
                "resultat": msg,
                "etat_actuel": current_state
            }, indent=4)
        }
    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps(str(e))}
