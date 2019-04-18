# Todo-DB-Mobile

## Fonctionnalités :

### 1. Login/Logout :
  Prise en charge d'un `Login` et d'un `Logout` par adresse `Email` par l'utilisation de FireBase.
### 2. CoreData :
  En `local` deux tables sont sauvegardées : `Cats` et `TodoItems`
### 3. FireBase :
  Utilisation de `realTime DataBase` et de `FireStorage`
### 4. SearchBar :

### 5. Tri :
  Par `catégorie`, `date` et ordre `alphabétique`
### 6. Edition d'un TodoItem :
Accès lors d'un clic sur le detailDisclosure à droite de chaque item.

Modifications possibles : `titre`, `description`, `date`, `image` et `catégorie`
### 7. Checkmark :
  Possibilité de marquer la tâche en cliquant dessus dans la liste : indique qu'elle est accomplie
### 8. Suprression d'un TodoItem : 
  Possibilité de supprimmer un TodoItem en slidant vers la gauche sur celui-ci dans la liste

## Problème rencontrés :

### 1. Mise en place 

## Architecture :

### 1. DataManager :
  Gère la sauvegarde en `local` et sur `Firebase`
### 2. Delegates et protocoles : 
Utilisés lors du `retour de la vue d'édition` et aussi lors de la récupération asynchrone des `TodoItems sur Firebase` (pour charger en continu les éléments dans la tableView)
