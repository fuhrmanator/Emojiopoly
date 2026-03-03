"============================================================"
"Script Pharo - Export des métriques de qualité en CSV"
"============================================================"
| modelFile model classes stream writer |

"--- 1. Localiser le fichier model.json ---"
"On cherche d'abord dans le répertoire courant,"
"puis dans le workspace GitHub Actions si non trouvé."
"Le modèle doit être au même endroit où il a été généré par ts2famix."
"Sinon, les SourceAnchors ne seront pas corrects et les métriques"
" concernant le code source, ex. numberOfLinesOfCode"
" ne seront pas correctes."
modelFile := './model.json' asFileReference.

modelFile exists ifFalse: [
    modelFile := (Smalltalk os environment at: 'GITHUB_WORKSPACE' ifAbsent: [ '.' ]), '/model.json'.
    modelFile := modelFile asFileReference.
].

Transcript show: 'CI Export Script - Start'; cr.
Transcript show: 'Model file path: ', modelFile fullName; cr.
Transcript show: 'File exists: ', modelFile exists printString; cr.

modelFile exists ifFalse: [
    Transcript show: 'model.json not found'; cr.
    self error: 'model.json not found'.
].

"--- 2. Charger le modèle JSON dans Moose ---"
"FamixTypeScriptModel est la classe du métamodèle chargée à l'étape"
"précédente par Metacello (via moose-config.ston)."
"importFromJSONStream: lit le JSON et crée les entités Famix en mémoire."
Transcript show: 'Loading model into Moose...'; cr.
modelFile readStreamDo: [ :readStream |
    model := FamixTypeScriptModel new importFromJSONStream: readStream.
    model install.
].
Transcript show: 'Model loaded.'; cr.

"--- 3. Extraire les métriques ---"
"allModelClasses retourne toutes les entités de type FamixTypeScriptClass."
classes := model allModelClasses.
Transcript show: 'Classes found: ', classes size printString; cr.

"Ouverture du fichier .md en écriture."
stream := './export_metrics.md' asFileReference writeStream.

"Pour chaque classe, on calcule le nombre de lignes de code (LOC)."
"La stratégie de calcul du LOC :"
"  - Priorité : lire le fichier source via le sourceAnchor de la classe"
"    (positions startPos à endPos) et compter les lignes."
"  - Fallback : si le fichier source n'est pas trouvé, sommer les LOC"
"    de toutes les méthodes de la classe."
stream nextPutAll: 'There are '; nextPutAll: classes size asString; nextPutAll: ' classes'; cr.

classes do: [ :each |
    | loc anchor srcFile content snippet |
    loc := 0.

    "Tentative de calcul via le sourceAnchor (méthode principale)"
    anchor := each sourceAnchor.
    (anchor notNil and: [ anchor isKindOf: FamixTypeScriptIndexedFileAnchor ]) ifTrue: [
        srcFile := anchor fileName asFileReference.
        srcFile exists ifTrue: [
            content := srcFile contents.
            snippet := content copyFrom: anchor startPos to: (anchor endPos min: content size).
            loc := snippet lineCount.
        ].
    ].

    "Fallback : somme des LOC des méthodes"
    loc = 0 ifTrue: [
        loc := each methods inject: 0 into: [ :sum :m | sum + (m numberOfLinesOfCode ifNil: [ 0 ]) ].
    ].

    Transcript show: '  ', each name, ' loc:', loc printString; cr.
    writer nextPut: {
        each name.
        each numberOfMethods.
        each numberOfAttributes.
        loc.
    }.
].

stream close.

Transcript show: 'Export complete - export_metrics.csv'; cr.
