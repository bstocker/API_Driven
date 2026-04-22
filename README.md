------------------------------------------------------------------------------------------------------
ATELIER API-DRIVEN INFRASTRUCTURE
------------------------------------------------------------------------------------------------------
L’idée en 30 secondes : **Orchestration de services AWS via API Gateway et Lambda dans un environnement émulé**.  
Cet atelier propose de concevoir une architecture **API-driven** dans laquelle une requête HTTP déclenche, via **API Gateway** et une **fonction Lambda**, des actions d’infrastructure sur des **instances EC2**, le tout dans un **environnement AWS simulé avec LocalStack** et exécuté dans **GitHub Codespaces**. L’objectif est de comprendre comment des services cloud serverless peuvent piloter dynamiquement des ressources d’infrastructure, indépendamment de toute console graphique.Cet atelier propose de concevoir une architecture API-driven dans laquelle une requête HTTP déclenche, via API Gateway et une fonction Lambda, des actions d’infrastructure sur des instances EC2, le tout dans un environnement AWS simulé avec LocalStack et exécuté dans GitHub Codespaces. L’objectif est de comprendre comment des services cloud serverless peuvent piloter dynamiquement des ressources d’infrastructure, indépendamment de toute console graphique.
  
-------------------------------------------------------------------------------------------------------
Séquence 1 : Codespace de Github
-------------------------------------------------------------------------------------------------------
Objectif : Création d'un Codespace Github  
Difficulté : Très facile (~5 minutes)
-------------------------------------------------------------------------------------------------------
RDV sur Codespace de Github : <a href="https://github.com/features/codespaces" target="_blank">Codespace</a> **(click droit ouvrir dans un nouvel onglet)** puis créer un nouveau Codespace qui sera connecté à votre Repository API-Driven.
  
---------------------------------------------------
Séquence 2 : Création de l'environnement AWS (LocalStack)
---------------------------------------------------
Objectif : Créer l'environnement AWS simulé avec LocalStack  
Difficulté : Simple (~5 minutes)
---------------------------------------------------

Dans le terminal du Codespace copier/coller les codes ci-dessous etape par étape :  

**Installation de l'émulateur LocalStack**  
```
sudo -i mkdir rep_localstack
```
```
sudo -i python3 -m venv ./rep_localstack
```
```
sudo -i pip install --upgrade pip && python3 -m pip install localstack && export S3_SKIP_SIGNATURE_VALIDATION=0
```
```
localstack start -d
```
**vérification des services disponibles**  
```
localstack status services
```
**Réccupération de l'API AWS Localstack** 
Votre environnement AWS (LocalStack) est prêt. Pour obtenir votre AWS_ENDPOINT cliquez sur l'onglet **[PORTS]** dans votre Codespace et rendez public votre port **4566** (Visibilité du port).
Réccupérer l'URL de ce port dans votre navigateur qui sera votre ENDPOINT AWS (c'est à dire votre environnement AWS).
Conservez bien cette URL car vous en aurez besoin par la suite.  

Pour information : IL n'y a rien dans votre navigateur et c'est normal car il s'agit d'une API AWS (Pas un développement Web type UX).

---------------------------------------------------
Séquence 3 : Exercice
---------------------------------------------------
Objectif : Piloter une instance EC2 via API Gateway
Difficulté : Moyen/Difficile (~2h)
---------------------------------------------------  
Votre mission (si vous l'acceptez) : Concevoir une architecture **API-driven** dans laquelle une requête HTTP déclenche, via **API Gateway** et une **fonction Lambda**, lancera ou stopera une **instance EC2** déposée dans **environnement AWS simulé avec LocalStack** et qui sera exécuté dans **GitHub Codespaces**. [Option] Remplacez l'instance EC2 par l'arrêt ou le lancement d'un Docker.  

**Architecture cible :** Ci-dessous, l'architecture cible souhaitée.   
  
![Screenshot Actions](API_Driven.png)   
  
---------------------------------------------------  
## Processus de travail (résumé)

1. Installation de l'environnement Localstack (Séquence 2)
2. Création de l'instance EC2
3. Création des API (+ fonction Lambda)
4. Ouverture des ports et vérification du fonctionnement

---------------------------------------------------
Séquence 4 : Documentation  
Difficulté : Facile (~30 minutes)
---------------------------------------------------
Compte Rendu Technique : Orchestration Cloud avec LocalStack

Objectif : Créer une interface API permettant de piloter (allumer/éteindre) un serveur virtuel EC2 via une fonction Lambda, le tout simulé localement.

1. Préparation de l'Environnement

La première étape a consisté à isoler notre projet pour éviter les conflits de versions et simuler un environnement AWS réel.

Création d'une "bulle virtuelle" (venv) : Utilisation de python3 -m venv pour isoler les bibliothèques.

Installation des outils : Installation de awscli (pour commander le cloud), localstack (le simulateur) et boto3 (la bibliothèque Python pour AWS).

Configuration de l'identité : Paramétrage de clés d'accès fictives et d'une région par défaut (us-east-1) pour que l'outil AWS CLI accepte les commandes.

Code bash : 
# Création et activation de l'environnement virtuel
python3 -m venv ./rep_localstack
source ./rep_localstack/bin/activate

# Installation des dépendances
pip install awscli localstack boto3

# Configuration des identifiants fictifs pour AWS CLI
aws configure set region us-east-1
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test

# Lancement du moteur LocalStack
export LOCALSTACK_AUTH_TOKEN="TON_TOKEN"
localstack start -d 

2. Déploiement de l'Infrastructure (EC2)

Avant d'automatiser, nous avons dû créer la ressource à piloter.

Sélection de l'image (AMI) : Recherche dans le catalogue LocalStack pour trouver un identifiant d'image valide.

Lancement de l'instance : Exécution de la commande run-instances pour créer un serveur de type t2.micro.

Identification : Récupération de l'Instance ID (ex: i-d159f4d44bc8c2f4a), qui sert de "plaque d'immatriculation" unique pour nos futures commandes.

Code bash : 
# Lister les images disponibles pour choisir une AMI
aws --endpoint-url=http://127.0.0.1:4566 ec2 describe-images --query "Images[*].{Name:Name,ID:ImageId}" --output table

# Lancer l'instance EC2 (en utilisant l'AMI choisie)
aws --endpoint-url=http://127.0.0.1:4566 ec2 run-instances --image-id ami-d159f4d4 --count 1 --instance-type t2.micro

# Récupérer l'ID de l'instance pour le script Python
aws --endpoint-url=http://127.0.0.1:4566 ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text

3. Développement et Déploiement de la Lambda

La fonction Lambda agit comme le cerveau du projet. Nous avons rédigé un script Python nommé gestion_ec2.py.

Code Python : Utilisation de la bibliothèque boto3 pour envoyer des ordres start_instances et stop_instances.

Correction réseau : Pour que la Lambda puisse parler à LocalStack depuis son conteneur, nous avons utilisé l'URL spécifique http://localhost.localstack.cloud:4566.

Déploiement : Compression du script en fonction.zip et création de la fonction sur LocalStack.

Code bash :
# Compression du code source
zip fonction.zip gestion_ec2.py

# Création de la fonction Lambda
aws --endpoint-url=http://127.0.0.1:4566 lambda create-function \
    --function-name PiloteEC2 \
    --zip-file fileb://fonction.zip \
    --handler gestion_ec2.lambda_handler \
    --runtime python3.9 \
    --role arn:aws:iam::000000000000:role/lambda-role

# Optimisation du timeout (pour éviter les erreurs 500)
aws --endpoint-url=http://127.0.0.1:4566 lambda update-function-configuration \
    --function-name PiloteEC2 \
    --timeout 10

4. Configuration de l'API Gateway

Pour rendre la Lambda accessible par une simple URL, nous avons configuré une passerelle API.

Étapes //

Création : Génération d'une API REST nommée "MonAPI-Pilote".
Ressource : Identification de la racine (/) de l'API.
Méthode : Configuration d'une méthode ANY pour accepter les requêtes
Intégration : Branchement de l'API sur la Lambda (Proxy).
Déploiement : Publication de l'API sur un environnement nommé test.

Code bash :
# 1. Créer l'API et noter l'ID généré (ex: rz2n11qhty)
aws --endpoint-url=http://127.0.0.1:4566 apigateway create-rest-api --name 'MonAPI-Pilote'

# 2. Récupérer l'ID de la ressource racine (/)
aws --endpoint-url=http://127.0.0.1:4566 apigateway get-resources --rest-api-id rz2n11qhty

# 3. Créer la méthode ANY
aws --endpoint-url=http://127.0.0.1:4566 apigateway put-method \
    --rest-api-id rz2n11qhty --resource-id <ID_ROOT> --http-method ANY --authorization-type "NONE"

# 4. Intégrer la Lambda à l'API (Type Proxy)
aws --endpoint-url=http://127.0.0.1:4566 apigateway put-integration \
    --rest-api-id rz2n11qhty --resource-id <ID_ROOT> --http-method ANY --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:PiloteEC2/invocations

# 5. Déployer l'API sur le stage 'test'
aws --endpoint-url=http://127.0.0.1:4566 apigateway create-deployment --rest-api-id rz2n11qhty --stage-name test

5. Tests de Validation Final

Le pilotage se fait désormais via des requêtes HTTP simples (utilisant curl ou un navigateur).

Les commandes finales :
Démarrage : .../?action=start

Arrêt : .../?action=stop

Résultat final : L'envoi d'une requête URL retourne un message de succès JSON, et la vérification via describe-instances confirme que l'état de la machine passe de running à stopped en quelques secondes.

Code bash :
# Commande pour ARRETER l'instance
curl "http://127.0.0.1:4566/restapis/rz2n11qhty/test/_user_request_/?action=stop"

# Commande pour DEMARRER l'instance
curl "http://127.0.0.1:4566/restapis/rz2n11qhty/test/_user_request_/?action=start"

# Commande de vérification de l'état EC2
aws --endpoint-url=http://127.0.0.1:4566 ec2 describe-instances --query "Reservations[*].Instances[*].State.Name" --output text

CONCLUSION : 
Ce projet démontre la puissance du Serverless. En combinant une API et une fonction Lambda, nous avons créé un outil d'administration capable de gérer des ressources d'infrastructure sans jamais avoir à se connecter manuellement à une console de gestion. C'est la base de l'automatisation moderne du Cloud (DevOps).
   
---------------------------------------------------
Evaluation
---------------------------------------------------
Cet atelier, **noté sur 20 points**, est évalué sur la base du barème suivant :  
- Repository exécutable sans erreur majeure (4 points)
- Fonctionnement conforme au scénario annoncé (4 points)
- Degré d'automatisation du projet (utilisation de Makefile ? script ? ...) (4 points)
- Qualité du Readme (lisibilité, erreur, ...) (4 points)
- Processus travail (quantité de commits, cohérence globale, interventions externes, ...) (4 points)
