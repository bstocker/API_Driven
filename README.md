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
# Guide de Déploiement LocalStack et AWS Lambda

## Sommaire
1. [Séquence 1 : Préparation de l'environnement AWS](#séquence-1--préparation-de-lenvironnement-aws-localstack)
2. [Séquence 2 : Détails des commandes fondamentales](#séquence-2--détails-des-commandes-fondamentales)
3. [Séquence 3 : Guide d'utilisation du Makefile](#séquence-3--guide-dutilisation-du-makefile)

---

## Séquence 1 : Préparation de l'environnement AWS (LocalStack)
**Objectif :** Créer l'environnement AWS simulé avec LocalStack dans le terminal du Codespace.

### Création du dossier de travail
```bash
sudo -i mkdir rep_localstack
```

### Création de l'environnement virtuel Python
```bash
sudo -i python3 -m venv ./rep_localstack
```

### Installation des dépendances et de LocalStack
```bash
sudo -i pip install --upgrade pip && python3 -m pip install localstack && export S3_SKIP_SIGNATURE_VALIDATION=0
```

### Démarrage de l'émulateur en arrière-plan
```bash
localstack start -d
```

### Vérification de la santé des services
Cette commande confirme que les services EC2, Lambda et API Gateway sont opérationnels avant de commencer le déploiement.
```bash
curl http://localhost:4566/_localstack/health
```

---

## Séquence 2 : Détails des commandes fondamentales
Ces étapes permettent de configurer l'infrastructure manuellement pour comprendre le flux de travail et les dépendances.

### Gestion de l'URL dynamique Codespaces
Pour supprimer toute dépendance au localhost,  nous construisons une URL publique qui s'adapte automatiquement au nom de votre Codespace.
```bash
PUBLIC_ENDPOINT="https://${CODESPACE_NAME}-4566.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
```

### Préparation de la fonction Lambda
Le code Python est compressé au format ZIP, format requis par AWS Lambda.
```bash
zip function.zip lambda_function.py
```

### Nettoyage préventif
Nous supprimons systématiquement l'ancienne version de la fonction pour éviter les erreurs de conflit si elle existe déjà.
```bash
aws --endpoint-url=$PUBLIC_ENDPOINT lambda delete-function --function-name ControlEC2 2>/dev/null || true
```

### Déploiement de la fonction
Envoi de la fonction vers l'émulateur LocalStack avec les configurations d'exécution (runtime Python 3.9).
```bash
aws --endpoint-url=$PUBLIC_ENDPOINT lambda create-function --function-name ControlEC2 --runtime python3.9 --handler lambda_function.lambda_handler --role arn:aws:iam::000000000000:role/lambda-role --zip-file fileb://function.zip
```

### Supervision de l'instance EC2
Cette commande affiche un tableau récapitulatif pour vérifier le changement d'état (running ou stopped) de vos instances directement dans le terminal.
```bash
aws --endpoint-url=$PUBLIC_ENDPOINT ec2 describe-instances --query 'Reservations[*].Instances[*].{ID:InstanceId,State:State.Name}' --output table
```

---

## Séquence 3 : Guide d'utilisation du Makefile
Le Makefile automatise la gestion du projet pour répondre aux critères de notation sur l'automatisation.

### Déployer l'infrastructure
Cette commande lance le script complet qui crée l'instance, la Lambda et configure les accès API.
```bash
make deploy
```

### Générer les URLs de pilotage
Affiche les liens publics (start, stop, status) pour tester le pilotage directement dans votre navigateur.
```bash
make urls
```

### Vérifier le statut
Affiche l'état actuel des instances directement dans votre terminal.
```bash
make status
```

### Nettoyer le projet
Supprime les fichiers temporaires et les archives zip inutiles.
```bash
make clean 
   
---------------------------------------------------

