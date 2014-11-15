
Juge automatique pour IA pour jeu générique...
==============================================

Les joueurs sont des programmes qui lisent des infos sur le jeu sur l'entrée
standard et jouent leur coups sur la sortie standard.


Organisation des fichiers
-------------------------

judge/                 le code du juge
  protocol.ml          encodeur et décodeur pour le protocole décrit plus bas
  core.ml              la partie principale
  main.ml              la synchro et l'UI
  morpionrec.ml        la partie spécifique à un jeu

morpionrec/            dossier pour un jeu
  joueur1/             dossier pour une IA
    player             le binaire/code du joueur
    ...                fichiers de données perso
                       (le binaire est lancé dans le dossier du joueur)
  joueur2/
    player
    ...
  201411202011.log     log de chaque séance
  201411202011.score   enregistrement des scores de chaque séance


Protocole d'entrée-sortie
-------------------------

Le juge et le joueur s'envoient des messages
terminés par un retour à la ligne.

J : Juge, P : joueur

1. Le juge et le joueur se disent bonjour:
  
      J    Hello morpion-rec
      P    Hello morpion-rec

   Le joueur doit charger ses données *avant* de répondre, car dès qu'il a
   répondu on peut lui demnander de jouer et décompter son temps.

2. Lorsque c'est au joueur de jouer:

      J    Your turn secondes_pour_jouer
      P    Play des_infos_sur_le_coup
      J    OK

3. Lorsque l'adversaire a joué:

      J    Play des_infos_sur_le_coup
 
   À partir de ce moment commence immédiatement le décompte du temps de
   réflexion du joueur.

4. Lorsque la partie se termine, un des cas suivants se présentent:

      J    You win
      J    You lose
      J    Tie
      J    Eliminated

   Le joueur répond alors:

      P    Fair enough

   Le joueur doit enregistrer toutes ses données (apprentissage, ...) avant
   d'envoyer ce message : en effet, le juge envoit un SIGTERM au joueur une fois
   qu'il l'a reçu.


Organisation du tournoi
-----------------------

Chaque paire ordonnée de joueurs distincts est considérée (pour chaque paire de
joueurs, il y a deux matchs, un où chaque joueur commence). Les matchs sont mis
en attente, et n matchs sont lancés en parallèle (typiquement n = #CPU/2).


Interface de visualisation du juge
----------------------------------

On a une GUI avec les vues suivantes :

- Tableau des scores (classé, évidemment)
- Liste des matchs en cours, liste de tous les matchs (en cours et finis)
- Visualisation d'un match (géré par le jeu)

Les commandes sont les suivantes :

- Dans tous les modes:
  - q : quitter (il y a un dialogue de confirmation)
- En mode tableau des scores:
  - tab : aller à la liste des parties
- En mode liste des parties:
  - tab : aller au tableau des scores
  - f : afficher uniquement les matchs en cours/tous les matchs
  - v : passe en mode 'partie en cours'
  - n : passe en mode 'navigation des parties'
  - r : lancer le tournoi ! (met tous les matchs du tournoi en attente)
- En mode 'partie en cours':
  - tab : aller à la liste des parties
- En mode 'navigation des parties':
  - n : partie suivante (next)
  - p : partie précédente (prev)
  - f : coup suivant (forward)
  - b : coup précédent (back)
  - a : début de partie
  - z : fin de partie


Le morpion récursif
-------------------

Tout le monde connait les règles ;-)


Comment lancer le juge
----------------------

Prérequis : OCaml 4.02 avec ocamlbuild, bibliothèque graphique, etc.  Ne compile
pas avec les versions précédentes (en particulier le code utilise un `match with
exception`, construction introduite dans cette version), mais à pas grand chose
près cela devrait devenir possible.

Instructions pour le cas du morpion récursif.

Pour compiler le juge :

  $ cd judge/
  $ ocamlbuild morpion_rec_judge.native

Pour compiler les IA d'exemple (Mayushii, FeirisuNyanNyan, AmaneSuzuha) :

  $ cd morpion_rec/Mayushii/
  $ make

Pour exécuter le juge :
  
  $ cd morpion_rec/
  $ ../judge/morpion_rec_judge.native .

Options supplémentaires pour la ligne de commande du juge : appeller le binaire
avec l'option `--help` pour en avoir la liste.


Les IA demo
-----------

Ci-présent quatre IA assez débiles à utiliser pour vos tests :

- Mayushii : joue le premier coup qu'elle trouve
- FeirisuNyanNyan : joue un coup au hasard
- Amane : joue un coup gagnant, ou joue un coup empêchant l'adversaire
  de gagner immédiatement au coup suivant
- NiAh : joue le premier coup trouvé, et fait parfois des fautes qui l'éliminent
  (merci à AP pour le code !)


