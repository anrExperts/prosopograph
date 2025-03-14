# Prosopograph

Prosopograph est une application web pour la production de données prosopographiques et biographiques fondée sur le format archivistique XML EAC-CPF.

L’application est développée avec [XForms](https://www.w3.org/TR/xforms11/) et fonctionne avec la base de données XML libre et open source [BaseX](https://basex.org).

Prosopograph is a web application for producing prosopographical and biographical data based on the archival XML format EAC-CPF.

The application is developed using XForms and runs on the free and open-source XML database BaseX.

## Documentation

### Licence
GNU GPL 3

### Dépendances
- BaseX > `11`
- XSLTForms > `1.7`

### Installation
- Cloner le répertoire et le placer dans le répertoire `webapp` de BaseX ;
- Lancer BaseX avec le script d’exécution `bin/basexhttp` ;
- Accéder à [http://localhost/bio/install](http://localhost/bio/install) pour installer la base de données BiographiX ;
- Puis, à [http://localhost/bio/biographies/view](http://localhost/bio/biographies/view) pour commencer à saisir des données.
