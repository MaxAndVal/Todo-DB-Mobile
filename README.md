# Todo-DB-Mobile

## Fonctionnalités :

1. Login/Logout :

Prise en charge d'un `Login` et d'un `Logout` par adresse `Email` par l'utilisation de FireBase.

2. CoreData :

En `local` deux tables sont sauvegardées : `Cats` et `TodoItems`

3. FireBase :

Utilisation de `realTime DataBase` et de `FireStorage`

4. SearchBar :

Placée en haut de l'application, elle permet de rechercher les TodoItems par leur nom. Elle n'est pas sensible à la case ni aux accents.

5. Tri :

Par `catégorie`, `date` et ordre `alphabétique`

6. Edition d'un TodoItem :

Accès lors d'un clic sur le detailDisclosure à droite de chaque item.
Modifications possibles : `titre`, `description`, `date`, `image` et `catégorie`

7. Checkmark :

Possibilité de marquer la tâche en cliquant dessus dans la liste : indique qu'elle est accomplie

8. Suprression d'un TodoItem :

Possibilité de supprimmer un TodoItem en slidant vers la gauche sur celui-ci dans la liste

## Problème rencontrés :

1. Mise en place de FireBase :

La partie la plus difficile a été d'inclure `FireBase` et `CoreData` en même temps et d'arriver à `synchroniser` l'un et l'autre : pas de différence entre les deux. Une fonctionnalités la moins évidente fut de refaire un chargement des items une fois les images télécharchées sur FireBase. Un `delegate` fut la solution la plus facile à mettre en place afin de permettre une `synchronisation en temps réel`.

2. Mise en place de CoreData :

La mise en place de CoreData a été laborieuse au début, notamment lorsque le choix d'intégrer une classe DataManager n'avit pas était fait. Mais globalement une fois le concept de context compris les difficultés ont été résolues. 

3. Parsing des images de png en Data : 

Cette partie a été assez rude car il a fallut rendre compatibles les data récupérées sur `FireBase` (lien vers une `URL` pointant vers le fichier en `.png`) et lors mise au format CoreData (`NSData 64 bits`).

4. Table et Section :

La possibilité de découper la liste en plusieurs sections ne fut pas un problème et assez simple à mettre en place, cependant, le fait de cliquer/supprimer un item dans une section fut assez compliqué à mettre en place, car la place de l'item dans la section était diffèrent de la place de se même item dans la liste global.

## Architecture :

1. DataManager :

Gère la sauvegarde en `local` et sur `Firebase`

2. Delegates et protocoles :

Utilisés lors du `retour de la vue d'édition` et aussi lors de la récupération asynchrone des `TodoItems sur Firebase` (pour charger en continu les éléments dans la tableView)
