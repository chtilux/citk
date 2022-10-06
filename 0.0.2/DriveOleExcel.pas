{---------------------------------------------------------------------------

Auteur : Lampert           bernard.lampert@libertysurf.fr

J'ai fait cette unité en m'inspirant de l'exemple fourni par Firejocker http://firejocker.free.fr
pour Word et des exemples fournis sur le site Delphi Michel.
bien entendu, cette unité est loin d'être complete mais elle vous permettra surement de faire
le minimum sur Excel,

Regardez comment tout cela fonctionne, c'est pas dur, completez la de votre contribution !
                   ENCORE MERCI A TOUS LES PARTICIPANTS DU SITE DELPHI MICHEL
--------------------                     A Vous !                      --------------  }

{Mise à jour 10 11 2003

Un grand merci à Christian Chopard

Cette mise à jour est essentiellement due à l'amabilité de Christian Chopard qui a écrit
la plupart des nouvelles procédures et m'a fortement inspiré pour les quelques autres que
j'ai rajoutées

Les nouvelles fonctions ( essentiellement pour l'impression ) sont :

Procedure AjusterLargeurTableImp          Ajuste le tableau imprimé à la page
Procedure AutoAjusterToutelaPage          Ajuste le tableau entier aux données
Procedure CentrerHorizontalImp            Centre le tableau imprimé dans la page
Procedure CentrerVerticalImp              Centre le tableau imprimé dans la page
Procedure CouleurImp                      Gère l'impression couleur ou gamme de gris
Procedure GrilleVisibleImp                Provoque l'impression de toutes les bordures
Procedure HauteurLignes                   Règle la hauteur de ligne
Procedure Impression                      Lance l'impression du tableau
Procedure InsereSautDePage                Insère un saut de page au dessus d'une ligne
Procedure LargeurColonnes                 Règle la largeur de colonnes
Procedure MargeImp                        Règle les marges d'impression
Procedure NumeroPageImp                   Définit le numéro de paage départ à l'impression
Procedure OrientationdeLaCopieImp         Définit l'orientation de l'impression
Procedure RepeteLigneColonneImp           Définit les lignes et colonnes à répéter
Procedure SelectionnerZoneDImpression     Définit la zone d'impression
Procedure SelectionToutelaPage            Sélectionne toute la feuille
Procedure TaillePapierImp                 Définit la taille du papier de l'imprimante
Procedure TetiereBasDePageImp             Définit les impression de têtière et bas de page
Procedure ZoomPourCentImp                 Définit le taux de grossissement de l'impression
 }

{Mise à jour 14 02 2004

Nouvelles fonctions ou définitions qui m'ont servi pour un petit développement pour un ami
                                                                                  
Const TraitPointille 	                * Epaisseur des traits d'encadrement
Const TraitMedium                       * Epaisseur des traits d'encadrement
Const TraitEpais                        * Epaisseur des traits d'encadrement
Const TraitFin                          * Epaisseur des traits d'encadrement

type TBordure		                  Rajout des lignes intérieures et des diagonales

Type TTypeBordures                        Rajout des différents types de pointillés et double trait

Type TStylePolice                       * Reprend les définitions de format cellule Style

Type TSoulignementPolice                * Reprend les définitions de format cellule Soulignement

Type TAttributPolice                    * Reprend les définitions de format cellule Attributs 

Procedure PoliceCellule                   Rajout d'une deuxième syntaxe pour soulignements divers et attributs

Procedure PoliceTexteCellule            * Rajout d'une procédure qui permet de moduler la police au 
		                          sein même du texte dans une cellule
		          
Procedure Bordures                        Rajout d'une deuxième syntaxe pour modiier la couleur des traits

Procedure Impression                      Rajout d'une deuxième syntaxe pour passer le nom de l'imprimante

Function LibelleCellule                 * Renvoie le numéro alphanumérique d'une cellule en fonction
                                          de valeurs numériques de ligne et colonne, pratiaue dans
                                          des boucles.

Function LigneVide                      * Détecte si une ligne de tableau est vide ou non

Function DerniereLigne                  * Détermine par recherche dichotomique la derniere ligne
                                          non vide d'un tableau
                                          
Function DerniereCellule                *  Renvoie le libellé de la dernière cellule (Ctrl Fin) et la sélectionne}

{Mise à jour 10 05 2004

Nouvelles fonctions ou définitions touchant essentiellement le formatage des cellules

TalignementCellule                        Rajout de retrait, justification etc

TalignementVertCellule                  * Positionnement vertical du texte

TFormatStandard                         * Définition pour les données de type standard et texte

TFormatNumerique                        * Définition pour les données de type nombre

TFormatMonnaie                          * Définition pour les données de type monnaie

TFormatComptable                        * Définition pour les monnaies en comptabilité

TFormatDateEtDivers                     * Définition pour les données de type Date heure et divers

TFormatScientifique                     * Définition pour les données de type % et scientifique

TTypeNegatif                            * Définition pour les représentations des chiffres négatifs

TTypeMonnaie                            * Définition pour les types de monnaies (pas toutes)

Variables de formatage date et heure    * Différents format préenregistrés pour la date et l'heure

Variables de formatage fractions        * Différents format préenregistrés pour les fractions

Variables de formatage spécial          * Différents format préenregistrés pour les données type
                                          code postal, téléphone etc

Procedure FormatCellule                 * 6 variantes de la même procédure pour traiter texte, nombre
                                          pourcentage, heure, etc (équivalent à Format Cellule sous excel)

Function FormatCellule                  * Fonction qui renvoie le format appliqué à une cellule

Procedure AlignementTexte               * Procédure pour gérer le positionnement dans le cellule

Procedure ControleTexte                 * Procédure pour controler l'ajustement, retour à la ligne etc

Procedure OrientationTexte              * Procédure pour gérer l'orientation du texte degré par degré

Procedure SelectionColonnes             * Procédure pour sélectionner une ou plusieurs colonnes

Procedure SelectionLignes               * Procédure pour sélectionner une ou plusieurs lignes

Procedure FiltreAuto                    * Procédure pour passer la sélection en filtrage automatique

Procedure LigneColonne                  * Procédure pour calculer numéros de ligne en fonction du libellé
                                          de la cellule (fonction réciproque de LibelleCellule) 

Procédure HauteurAuto                   * Procédure pour ajuster automatiquement la hauteur d'une
                                          ou plusieurs lignes      

Procédure SelecteClasseur               * Procédure pour sélectionner et activer un classeur
}


unit DriveOleExcel;

interface

Uses Classes,Graphics,Dialogs;

Const
   TraitPointille = 1;
   TraitMedium = -4138;
   TraitEpais = 4;
   TraitFin = 2;
   OrVertical = -4166;

type
         TCouleur = (Auto,Noir,Bleu,Turquoise,VertClair,Rose,
                     Rouge,Jaune,Blanc,BleuFonce,Cyan,
                     Vert,Violet, RougeFonce,JauneFonce,
                     GrisFonce, GrisClair);

         TEtendue = (CelluleActive,Selection);

         TTypeLecture = (Formule,Valeur);

         TalignementCellule = (TelQuel,General,Gauche,Centre,Droite,Recopie,Justifie,CentreSurSelection);

         TalignementVertCellule = (VTelQuel,VHaut,VCentre,VBas,VJustifie);

         TBordure = (BdGauche,BdHaute,BdDroite,BdBasse,BdInterieureVert,BdInterieureHor,
                     BdDiagonaleDescendante,BdDiagonaleMontante);

         TBordures = Set of TBordure;

         TTypeBordures = (Continu,Discontinu,Tiret,TiretPoint,TiretPointPoint,Point,BordDouble,Sans,TiretPointIncline);

         TTypeDonnees = (AlphaNum,Numerique,Entier,DateHeure,DateSeule,HeureSeule);

         TPrinterOrientation = (Portrait,Paysage);

         TTypePapier = (Format10x14,Format11x17,FormatA3,FormatA4,FormatA4Small,
                     FormatA5,FormatB4,FormatB5,FormatCsheet,FormatDsheet,
                     FormatEnvelope10,FormatEnvelope11,FormatEnvelope12,
                     FormatEnvelope14,FormatEnvelope9,FormatEnvelopeB4,
                     FormatEnvelopeB5,FormatEnvelopeB6,FormatEnvelopeC3,
                     FormatEnvelopeC4,FormatEnvelopeC5,FormatEnvelopeC6,
                     FormatEnvelopeC65,FormatEnvelopeDL,FormatEnvelopeItaly,
                     FormatEnvelopeMonarch,FormatEnvelopePersonal,FormatEsheet,
                     FormatExecutive,FormatFanfoldLegalGerman,FormatFanfoldStdGerman,
                     FormatFanfoldUS,FormatFolio,FormatLedger,FormatLegal,
                     FormatLetter,FormatLetterSmall,FormatNote,FormatQuarto,
                     FormatStatement,FormatTabloid,FormatUser);

         TStylePolice = (Normal,Gras,Italique,GrasItalique);

         TSoulignementPolice = (Aucun,TraitSimple,TraitDouble,ComptabiliteSimple,ComptabiliteDouble);

         TAttributPolice = (Barre,Exposant,Indice);

         TAttributsPolice = set of TAttributPolice;

         ValeurDonnee = Record
            Case TypeDonnees: TTypeDonnees of
               AlphaNum : (Chaine: ShortString);
               Numerique : (Nombre: Real);
               Entier : (Entier: Integer);
               DateHeure : (LaDateComplete: TDateTime);
               DateSeule : (LaDate: TDateTime);
               HeureSeule : (LHeure: TDateTime);
            End;


         TFormatStandard = (StandardAuto,Texte);

         TFormatNumerique = (Nombre);

         TFormatMonnaie = (Monnaie);

         TFormatComptable = (EnEuro,EnDollarAnglaisEtasUnis,
                         EnPesetasEspagnol,EnLivreAnglais,
                         EnDMAllemand,EnFrancFrancaisStandard);

         TFormatDateEtDivers = (DateEtHeure,Fraction,Special);

         TFormatScientifique = (PourCent,Scientifique);

         TTypeNegatif = (NegMoins,NegRouge,NegMoinsRetrait,NegMoinsRouge);

         TTypeMonnaie = (Aucune,Euro,DollarAnglaisEtasUnis,
                         PesetasEspagnol,LivreAnglais,
                         EuroEnTete,EuroEnQueue,DMAllemand,FrancFrancaisStandard);


    // Cette procedure permet de creer une Instance de Excel
//         procedure CreerInstanceDeExcel(Var Instance : Variant; Visible : Boolean);
    // fonction qui ouvre ou crée une instance de excel. Retourne True si création.
         function CreerInstanceDeExcel(Var Instance : Variant; Visible : Boolean): boolean;
    // cette procedure permet de creer un nouveau Classeur à partir de l'instance de Excel
         //procedure CreerNouveauClasseur(Var NouveauClasseur : Variant; Var InstanceDeExcel : variant );
         procedure CreerNouveauClasseur(Var NouveauClasseur : Variant; var InstanceDeExcel : variant;
                                        s_modele: string = '' );
    // Cette procédure active l'affichage des messages de Excel
         procedure ActiveAffichageMessages(Var InstanceDeExcel : variant; b_value: boolean);
    // cette procedure permet de d'ouvrir un Classeur Excel existant
         procedure OuvrirUnClasseur(Var InstanceDeExcel : variant; Var ClasseurOuvert : variant;Fichier : string);
     // cette procedure permet de sauvegarder le Classeur sous le nom souhaité
         procedure SauvegarderClasseurSous(Var InstanceDeExcel : Variant; NomDuFichier : string);
     // cette procédure permet de sélectionner et activer un classeur
         procedure SelectionneClasseur(Var Classeur: variant); overload;
     // cette procédure permet de sélectionner et activer un classeur
         procedure SelectionneClasseur(Var Classeur, InstanceDeExcel: variant; s_nomcls: string); overload;
     // cette procedure permet de sauvegarder le Classeur
         procedure Sauvegarder(Var InstanceDeExcel : Variant);
     // cette procedure permet de fermer le classeur
         procedure FermerClasseur(Var InstanceDeExcel : Variant);
     // cette procedure permet de fermer Excel et libere le variant
         procedure FermerExcel(Var InstanceDeExcel : Variant);
     // Rendre Excel Visible ou Invisible
         Procedure VoirExcel(Var InstanceDeExcel: Variant; Show: Boolean);
     // Sélectionner Une ou plusieurs Cellule du classeur actif
         Procedure SelectionCellules(Var InstanceDeExcel: Variant;Cellules: string);
     // Sélectionner Une ou plusieurs Colonnes du classeur actif
         Procedure SelectionColonnes(Var InstanceDeExcel: Variant;Colonnes: string);
     // Sélectionner Une ou plusieurs lignes du classeur actif
         Procedure SelectionLignes(Var InstanceDeExcel: Variant;Lignes: string);
     // Rentre une formule dans la cellule active ou la sélection
         Procedure InsererUneFormule(Var InstanceDeExcel: Variant;Formule: String;Etendue: TEtendue);
     // Rentre une formule dans la cellule.
         Procedure InsererFormuleCellule(Var InstanceDeExcel: Variant;Formule: ValeurDonnee;Cellule: String);
     // Récupère les coordonnées de la cellule active
         Function LireNumeroCellule(Var InstanceDeExcel: Variant): String;
     // Selectionne un onglet par son nom
         Procedure SelecteFeuillet(Var Classeur: Variant; NomOnglet: String); overload;
     // Selectionne un onglet par son index
         Procedure SelecteFeuillet(Var Classeur: Variant; index: integer); overload;
     // Récupère la liste des noms de feuillets dans une liste de chaines
         Procedure RecupereNomsFeuillets(Var InstanceDeExcel: Variant; Var ListeFeuillets: TstringList);
     // Creer une nouvelle feuille et la nommer
         Procedure NouveauFeuillet(Var InstanceDeExcel,Classeur: Variant; NomFeuillet: String);
     // Creer une nouvelle feuille en la copiant d'une feuille existante et la nommer
         function  NouveauFeuilletCopie(Var InstanceDeExcel,Classeur: Variant; s_source, s_dest: String): string;
     // Renomme un feuillet
         Procedure RenommerFeuillet(Var Classeur: variant;AncienNom,NouveauNom: string);
     // Récupère la valeur ou la formule dans une cellule
         Function RecupereValeurFormule(var InstanceDeExcel: variant; TypeLecture: TTypeLecture;NumeroCellule: String): String;
     // Insère une image au niveau du feuillet actif
         Procedure InsereImage(var InstanceDeExcel: Variant; NomFichierImage: String);
     // Effectue la fusion de cellules sélectionnées
         Procedure FusionnerSelection(var InstanceDeExcel: variant; Selection: String);
     // Précise Nom de la police, Couleur, Taille, Style
         Procedure PoliceCellule(Var InstanceDeExcel: variant; NomPolice: string; Taille: Integer;
                            Couleur: TColor; Style: TFontStyles); overload;
     // Précise Nom de la police, Couleur, Taille, Style, Soulignement, attributs
         Procedure PoliceCellule(Var InstanceDeExcel: variant; NomPolice: string; Taille: Integer;
                            Couleur: TColor; StylePolice: TStylePolice;
                            Soulignement: TSoulignementPolice; Attribut: TAttributsPolice); overload;
     // Précise Nom de la police, Couleur, Taille, Style, Soulignement, attributs
         Procedure PoliceTexteCellule(Var InstanceDeExcel: variant; DebutTexte,LongTexte: Integer;
                            NomPolice: string; Taille: Integer;
                            Couleur: TColor; StylePolice: TStylePolice;
                            Soulignement: TSoulignementPolice; Attribut: TAttributsPolice);
     // Change la couleur du fond de sélection
         Procedure CouleurFondSelection(Var InstanceDeExcel: variant; Couleur: TColor);
     // Règle l'alignement de la sélection
         Procedure AligneSelection(Var InstanceDeExcel: variant; Alignement: TalignementCellule);
     // Définit les traits autour et dans une sélection
         Procedure Bordures(Var InstanceDeExcel: variant; Bords: TBordures; TypeBordure: TTypeBordures;
                            Epaisseur: Integer; Couleur: TColor); Overload;
     // Définit les traits autour et dans une sélection
         Procedure Bordures(Var InstanceDeExcel: variant; Bords: TBordures; TypeBordure: TTypeBordures;
                            Epaisseur: Integer); Overload;
     // Provoque l'autodimensionnement d'une colonne aux valeurs
         Procedure LargeurAuto(Var InstanceDeExcel: variant; Colonne: String);
     // Provoque l'autodimensionnement d'une Ligne aux valeurs
         Procedure HauteurAuto(Var InstanceDeExcel: variant; Ligne: String);
      //===Format Hauteur de ligne
      //==============================================================================
      Procedure HauteurLignes(Var InstanceDeExcel: variant; Hauteur: double);
      //===Format Largeur de colonne
      Procedure LargeurColonnes(Var InstanceDeExcel: variant; Largeur: double);
      // Sélectionner de toute la page
      Procedure SelectionToutelaPage(Var InstanceDeExcel: Variant);
      // Ajuster lignes et colonnes de toute la page
      Procedure AutoAjusterToutelaPage(Var InstanceDeExcel: Variant);

      // Procédures pour l'impression

      // Impression avec Nombre de copies
      //==============================================================================
      Procedure Impression(var InstanceDeExcel: variant; NbCopie: Integer);Overload;
      // Impression avec Nombre de copies
      //==============================================================================
      Procedure Impression(var InstanceDeExcel: variant; NbCopie: Integer;
                           NomImprimante: String);Overload;
      // Orientations de la de copies
      //==============================================================================
      Procedure OrientationdeLaCopieImp(var InstanceDeExcel: variant; Orientation:
      TPrinterOrientation);
      //Grille visible de la copie
      //==============================================================================
      Procedure GrilleVisibleImp(var InstanceDeExcel: variant; Visible : Boolean);
      //centre la copie horizontallement
      //==============================================================================
      Procedure CentrerHorizontalImp(var InstanceDeExcel: variant; Centrer :
      Boolean);
      //centre la copie verticallement
      //==============================================================================
      Procedure CentrerVerticalImp(var InstanceDeExcel: variant; Centrer :
      Boolean);
      //Pour zoomer  la copie
      //==============================================================================
      Procedure ZoomPourCentImp(var InstanceDeExcel: variant; n : Integer);
      // Pour faire tenir la largeur du tableau dans une page
      //==============================================================================
      Procedure AjusterLargeurTableImp(var InstanceDeExcel: variant; SurNbdePages: Integer);
      //Pour sélectionner la zone d'impression
      //==============================================================================
      Procedure SelectionnerZoneDImpression(var InstanceDeExcel: variant;Zone: String);
      //Pour Insérer un saut de page audessus de la ligne donnée
      //==============================================================================
      Procedure InsereSautDePage(var InstanceDeExcel: variant; Ligne: String);
      //Pour imprimer en couleur ou non
      //==============================================================================
      Procedure CouleurImp(var InstanceDeExcel: variant; Couleur: Boolean);
      //Pour fixer les marges d'impression
      //==============================================================================
      Procedure MargeImp(var InstanceDeExcel: variant;
      Left,Right,Top,Bottom,Header,Footer : Double);
      //Pour définir les lignes et colonnes à répéter en haut et à gauche
      //==============================================================================
      Procedure RepeteLigneColonneImp(var InstanceDeExcel: variant;Lignes,Colonnes:
                                      String);
      //Pour définir têtière et bas de page
      //==============================================================================
      Procedure TetiereBasDePageImp(var InstanceDeExcel: variant; TeteGauche,TeteCentre,
                                    TeteDroite,BasGauche,BasCentre,BasDroite: string);
      //Pour Donner la taille du papier dans l'imprimante
      //==============================================================================
      Procedure TaillePapierImp(var InstanceDeExcel: variant;TypePapier: TTypePapier);
      // Pour donner le numéro de départ de pagination de la première page
      //==============================================================================
      Procedure NumeroPageImp(var InstanceDeExcel: variant; NoPremierePage: Integer);
      // Renvoie le libellé d'une cellule en fonction du n° de ligne et de colonne
      //==============================================================================
      Function LibelleCellule(Colonne,Ligne: Integer): String;
      // Renseigne Numéro de ligne et de colonne en fonction du libelle cellule
      //==============================================================================
      Procedure LigneColonne(Cellule: String; Var Lig,Col: Integer);
      // Renvoie vrai si les colonnes 1 à n de la ligne l sont toutes vides
      //==============================================================================
      Function LigneVide(Var InstanceDeExcel: variant;NumLigne,NbColonne: integer): Boolean;
      // Renvoie vrai si les colonnes 1 à n de la ligne l sont toutes vides
      //==============================================================================
      Function DerniereLigne(Var InstanceDeExcel: variant;NbColonne: integer): Integer;
      // Renvoie le libellé de la dernière callule et la sélectionne (vaut Ctrl Fin)
      //==============================================================================
      Function DerniereCellule(Var InstanceDeExcel: variant): string;

      // FONCTIONS DE FORMATAGE DES CELLULES

      // Applique à la cellule le formatage pour les formats standard et texte
      //==============================================================================
      Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatStandard); Overload;
      // Applique à la cellule le formatage pour les formats nombre
      //==============================================================================
      Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatNumerique;Decimale: Integer;
                             SeparateurDeMilliers: Boolean; LeNegatif: TTypeNegatif); Overload;
      // Applique à la cellule le formatage pour les formats monnaie
      //==============================================================================
      Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatMonnaie;Decimale: Integer;
                             LeNegatif: TTypeNegatif;LaMonnaie: TTypeMonnaie); Overload;
      // Applique à la cellule le formatage pour les formats comptabilité
      //==============================================================================
      Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatComptable;
                             Decimale: Integer); Overload;
      // Applique à la cellule le formatage pour les formats Date Heure, Fraction et Special
      //==============================================================================
      Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatDateEtDivers;
                             LeFormat: String); Overload;
      // Applique à la cellule le formatage pour les formats pourcentage et scientifique
      //==============================================================================
      Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatScientifique;
                             Decimale: Integer); Overload;
      // Renvoie le format lu dans la cellule
      //==============================================================================
      Function FormatCellule(Var InstanceDeExcel: variant;Cellule: String): String; Overload;

      {Fonctions de mise en forme du texte}

      // Aligne le texte horizontalement et verticalement
      //==============================================================================
      Procedure AlignementTexte(Var InstanceDeExcel: variant;AlignHor: TAlignementCellule;
                                Retrait: Integer;AlignVert: TalignementVertCellule);
      // Controle le comportement du texte Retour à la ligne, fusion cellule, adaptation
      //==============================================================================
      Procedure ControleTexte(Var InstanceDeExcel: variant;RenvoiALaLigne,Adapter,FusionCellules: Boolean);
      // Controle l'orientation du texte
      //==============================================================================
      Procedure OrientationTexte(Var InstanceDeExcel: variant;Inclinaison: Integer);
      // Passe la sélection en filtre automatique (bascule)
      //==============================================================================
      Procedure FiltreAuto(Var InstanceDeExcel: variant; Cellules: string);

function colLetter(col: byte): string;

Var
   {Variables Date et Heure}
   jmS,                             // 2/9
   jmaaS,                          // 2/9/04
   jjmmaaS,                        // 02/09/04
   jmmmT,                           // 2-sept
   jmmmaaT,                        // 2-sept-04
   jjmmmaaT,                       // 02-sept-04
   mmmaaT,                          // sept-04
   mmmmaaT,                         // septembre-04
   jmmmmaaaa_,                     // 2 septembre 2004
   jmaaS_hmm_AMPM,                // 2/9/04 1:27 PM
   jmaaS_hmm,                     // 2/9/04 13:27
   mmmmm,                           // s
   mmmmmaaT,                        // s-04
   mjaaaaS,                        // 9/2/2004
   jmmmaaaaT,                      // 2-sept-2004
   jjjj_le_j_mmmm_aaaa,        // jeudi, le 2 septembre 2004
   aaaajjmmmmS,                    // 2004/02/septembre
   jjmmaaaaS_hhmmss,             // 02/09/2004 13:37:43
   hhmm,                           // 01:27
   h_heures_mm_minutes_ss_secondes, // 1 heures 27 minutes 43 secondes
   hh_heures_mm_minutes,            // 01 heures 27 minutes
   hhmmss: String;                // 01:27:43
   {Variables Fraction}
   UnSurUn,
   DeuxSurDeux,
   TroisSurTrois,
   UnSur2,
   UnSur4,
   UnSur8,
   UnSur16,
   UnSur10,
   UnSur100: String;
   {Variables Special}
   CodePostal,
   NumeroSecu,
   NumeroTel,
   NumeroTelTiret: String;

implementation

    uses ComObj, Variants, SysUtils, UITypes;


    //********************************************************************************************//
    //                               Fonctions Creation Classeur Excel                            //
    //********************************************************************************************//


    // Cette procedure permet de creer une Instance de Excel
//    procedure CreerInstanceDeExcel(Var Instance : Variant; Visible : Boolean);
    function CreerInstanceDeExcel(Var Instance : Variant; Visible : Boolean): boolean;
    begin
      try        Instance := GetActiveOleObject('EXCEL.Application');
        Result := not VarIsNull(Instance);
      except
        on EOleSysError do
        begin
          Instance := CreateOleObject('EXCEL.Application');
          Result := not VarIsNull(Instance);
          if not Result then
            raise Exception.Create('Objet MsExcel indisponible !');
        end;
      end;
      if Result then
        Instance.visible := Visible; // pour rendre Excel visible
    end;


    // Cette procédure active l'affichage des messages de Excel
    procedure ActiveAffichageMessages(Var InstanceDeExcel : variant; b_value: boolean);
    begin
      InstanceDeExcel.DisplayAlerts := b_value;
    end;

    // cette procedure permet de creer un nouveau Classeur à partir de l'instance de Excel
    //procedure CreerNouveauClasseur(Var NouveauClasseur : Variant; var InstanceDeExcel : variant );
    procedure CreerNouveauClasseur(Var NouveauClasseur : Variant; var InstanceDeExcel : variant;
                                   s_modele: string = '' );
    begin
      if Length(s_modele) = 0 then
        NouveauClasseur := InstanceDeExcel.Workbooks.Add
      else
        NouveauClasseur := InstanceDeExcel.Workbooks.Add(s_modele);
    end;


    // cette procedure permet de d'ouvrir un Classeur Excel existant
    procedure OuvrirUnClasseur(Var InstanceDeExcel : variant; Var ClasseurOuvert : variant;Fichier : string);
    begin
         ClasseurOuvert := InstanceDeExcel.WorkBooks.Open(Fichier);
    end;
    // cette procédure permet de sélectionner et activer un classeur
    procedure SelectionneClasseur(Var Classeur: variant);
    begin
       Classeur.Activate;
    end;

    // cette procédure permet de sélectionner et activer un classeur
    procedure SelectionneClasseur(Var Classeur, InstanceDeExcel: variant; s_nomcls: string);
    begin
      InstanceDeExcel.WorkBooks[s_nomcls].Activate;
      Classeur := InstanceDeExcel.ActiveWorkBooks;
    end;

    // cette procedure permet de sauvegarder le Classeur sous le nom souhaité
    procedure SauvegarderClasseurSous(Var InstanceDeExcel : Variant; NomDuFichier : string);
    begin
      InstanceDeExcel.ActiveWorkBook.SaveAs(NomDuFichier);
    end;

    // cette procedure permet de sauvegarder le Classeur
    procedure Sauvegarder(Var InstanceDeExcel : Variant);
    begin
      InstanceDeExcel.ActiveWorkBook.Save;
    end;

    // cette procedure permet de fermer le classeur
    procedure FermerClasseur(Var InstanceDeExcel : Variant);
    begin
      InstanceDeExcel.Workbooks.Close;
    end;

    // cette procedure permet de fermer Excel et libere le variant
    procedure FermerExcel(Var InstanceDeExcel : Variant);
    begin
       Try
         InstanceDeExcel.quit;
       Except
       End;
       InstanceDeExcel:=Unassigned;//La constante Unassigned est utilisée pour indiquer qu'une variable Variant n'a pas encore été affectée d'une valeur.
    end;

    // Rendre Excel Visible ou Invisible
    Procedure VoirExcel(Var InstanceDeExcel: Variant; Show: Boolean);
    Begin
       InstanceDeExcel.Visible := Show;
    End;

    //********************************************************************************************//
    //                               Fonctions Du Classeur                                        //
    //********************************************************************************************//

    // Sélectionner Une ou plusieurs Cellule du classeur actif
    Procedure SelectionCellules(Var InstanceDeExcel: Variant;Cellules: string);
    Begin
       InstanceDeExcel.Range[Cellules].Select;
    End;

    // Rentre une formule dans la cellule active ou la sélection
    Procedure InsererUneFormule(Var InstanceDeExcel: Variant;Formule: String;Etendue: TEtendue);
    Begin
       Case Etendue of
          Selection : InstanceDeEXcel.Selection.Formula := Formule;
          CelluleActive: InstanceDeEXcel.ActiveCell.Formula := Formule;
       End;
    End;

     // Rentre une formule dans la cellule.
    Procedure InsererFormuleCellule(Var InstanceDeExcel: Variant;Formule: ValeurDonnee;Cellule: String);
    Begin
       Case Formule.TypeDonnees of
          AlphaNum: InstanceDeExcel.Range[Cellule].Formula:=Formule.Chaine;
          Numerique : InstanceDeExcel.Range[Cellule].Formula:=Formule.Nombre;
          Entier : InstanceDeExcel.Range[Cellule].Formula:=Formule.Entier;
          DateHeure : InstanceDeExcel.Range[Cellule].Formula:=Formule.LaDateComplete;
          DateSeule : InstanceDeExcel.Range[Cellule].Formula:=Formule.LaDate;
          HeureSeule : InstanceDeExcel.Range[Cellule].Formula:=Formule.LHeure;
       End;
    End;

    // Récupère les coordonnées de la cellule active
    Function LireNumeroCellule(Var InstanceDeExcel: Variant): String;
    var
       Colonne,
       Ligne: integer;
    begin
       Colonne := InstanceDeExcel.ActiveCell.Column;
       Ligne := InstanceDeExcel.ActiveCell.Row;
       Result := Char(Colonne+64)+IntToStr(Ligne);
    end;

    // Selectionne un onglet par son nom
    Procedure SelecteFeuillet(Var Classeur: Variant; NomOnglet: String);
    Begin
       Classeur.Worksheets.item[NomOnglet].Activate;
    End;

    Procedure SelecteFeuillet(Var Classeur: Variant; index: integer);
    Begin
       Classeur.Worksheets.item[index].Activate;
    End;

    // Récupère la liste des noms de feuillets dans une liste de chaines
    Procedure RecupereNomsFeuillets(Var InstanceDeExcel: Variant; Var ListeFeuillets: TstringList);
    var
       i: integer;
    Begin
       ListeFeuillets.Clear;
       For i := 1 to InstanceDeExcel.WorkSheets.Count do
          begin
             ListeFeuillets.add(InstanceDeExcel.Worksheets.item[i].Name);
          End;
    End;

    // Creer une nouvelle feuille et la nommer
    Procedure NouveauFeuillet(Var InstanceDeExcel,Classeur: Variant; NomFeuillet: String);
    var
       NumFeuil: integer;
       NomFeuil: string;
       ListeAncienne,
       ListeNouvelle: TstringList;
    begin
       If NomFeuillet <> '' then
          Begin
             ListeAncienne := TStringList.Create;
             ListeAncienne.Sorted := true;
             ListeNouvelle := TstringList.Create;
             RecupereNomsFeuillets(InstanceDeExcel,ListeAncienne);
          End;
       Classeur.Worksheets.Add;
       If NomFeuillet <> '' then
          Begin
             RecupereNomsFeuillets(InstanceDeExcel,ListeNouvelle);
             For NumFeuil := 1 to Classeur.Worksheets.Count do
                Begin
                   If ListeAncienne.IndexOf(Classeur.Worksheets.item[NumFeuil].Name) < 0 then
                      Begin
                         NomFeuil := Classeur.Worksheets.item[NumFeuil].Name;
                         Break;
                      End;
                End;
             Classeur.Worksheets.item[NomFeuil].Name := NomFeuillet;
             ListeAncienne.Free;
             ListeNouvelle.Free;
          End;
    end;

     // Creer une nouvelle feuille en la copiant d'une feuille existante et la nommer
     // renvoie le nom effectif
     function NouveauFeuilletCopie(Var InstanceDeExcel,Classeur: Variant; s_source, s_dest: String): string;
     var
        s_temp,
        s_name  : string;
        i_index,
        i_name  : integer;
        b_true  : Boolean;
     begin
        Classeur.Worksheets[s_source].Activate;
        i_index := Classeur.WorkSheets[s_source].Index;
        if i_index = 0 then i_index := 1;
        Classeur.WorkSheets[s_source].Copy(Classeur.WorkSheets[s_source]);
        Classeur.WorkSheets[i_index].Activate;

        s_temp := Classeur.WorkSheets[i_index].Name;

        s_name := s_dest;
        b_true := False;
        i_name := 0;
        while not b_true do
        begin
          try
            Classeur.WorkSheets[i_index].Name := s_name;
            b_true := True;
          except
            Inc(i_name);
            s_name := Format('%s (%d)', [s_dest, i_name]);
          end;
        end;

        Result := s_name;
     end;

     // Renomme un feuillet
     Procedure RenommerFeuillet(Var Classeur: variant;AncienNom,NouveauNom: string);
        Begin
           Classeur.Worksheets.item[AncienNom].Name := NouveauNom;
        End;

    // Récupère la valeur ou la formule dans une cellule
    Function RecupereValeurFormule(var InstanceDeExcel: variant; TypeLecture: TTypeLecture;NumeroCellule: String): String;
    Begin
       Case TypeLecture of
          Valeur: Result := InstanceDeExcel.Range[NumeroCellule].value;
          Formule: Result := InstanceDeExcel.Range[NumeroCellule].Formula;
       End;
    End;


    // Insère une image au niveau du feuillet actif
    Procedure InsereImage(var InstanceDeExcel: Variant; NomFichierImage: String);
    Begin
       InstanceDeExcel.ActiveWorkBook.ActiveSheet.Pictures.Insert(NomFichierImage).Select;
    End;

    // Effectue la fusion de cellules sélectionnées
    Procedure FusionnerSelection(var InstanceDeExcel: variant; Selection: String);
    Begin
       If Selection <> '' then
          InstanceDeExcel.Range[Selection].Select;
       InstanceDeExcel.Selection.Merge();
    End;

    // Précise Nom de la police, Couleur, Taille, Style
    Procedure PoliceCellule(Var InstanceDeExcel: variant; NomPolice: string; Taille: Integer;
                            Couleur: TColor; Style: TFontStyles); overload;
    Const
      xlUnderlineStyleSingle=2;
      xlUnderlineStyleNone=-4142;
    Begin
      If NomPolice <> '' then
         InstanceDeExcel.Selection.Font.Name:=NomPolice;
      If Couleur <> ClDefault then
         InstanceDeExcel.Selection.Font.Color:=Couleur;
      If Taille > 0 then
         InstanceDeExcel.Selection.Font.Size:=Taille;
      If FsBold in Style then
         InstanceDeExcel.Selection.Font.Bold := true
      else
         InstanceDeExcel.Selection.Font.Bold := false;
      If FsItalic in Style then
         InstanceDeExcel.Selection.Font.Italic := true
      else
         InstanceDeExcel.Selection.Font.Italic := false;
      If FsUnderline in Style then
         InstanceDeExcel.Selection.Font.UnderLine := xlUnderlineStyleSingle
      else
         InstanceDeExcel.Selection.Font.UnderLine := xlUnderlineStyleNone;
    End;

    // Précise Nom de la police, Couleur, Taille, Style, Soulignement, attributs
    Procedure PoliceCellule(Var InstanceDeExcel: variant; NomPolice: string; Taille: Integer;
                      Couleur: TColor; StylePolice: TStylePolice;
                      Soulignement: TSoulignementPolice; Attribut: TAttributsPolice); overload;
    begin
      If NomPolice <> '' then
         InstanceDeExcel.Selection.Font.Name:=NomPolice;
      If Couleur <> ClDefault then
         InstanceDeExcel.Selection.Font.Color:=Couleur;
      If Taille > 0 then
         InstanceDeExcel.Selection.Font.Size:=Taille;
      If StylePolice = Normal then
         Begin
            InstanceDeExcel.Selection.Font.Bold := false;
            InstanceDeExcel.Selection.Font.Italic := false;
         End;
      If StylePolice = Gras then
         InstanceDeExcel.Selection.Font.Bold := true;
      If StylePolice = Italique then
         InstanceDeExcel.Selection.Font.Italic := true;
      If StylePolice = GrasItalique then
         Begin
            InstanceDeExcel.Selection.Font.Bold := true;
            InstanceDeExcel.Selection.Font.Italic := true;
         End;
      If Soulignement = Aucun then
         InstanceDeExcel.Selection.Font.Underline := -4142;
      If Soulignement = Aucun then
         InstanceDeExcel.Selection.Font.Underline := -4142;
      If Soulignement = TraitSimple then
         InstanceDeExcel.Selection.Font.Underline := 2;
      If Soulignement = TraitDouble then
         InstanceDeExcel.Selection.Font.Underline := -4119;
      If Soulignement = ComptabiliteSimple then
         InstanceDeExcel.Selection.Font.Underline :=  4;
      If Soulignement = ComptabiliteDouble then
         InstanceDeExcel.Selection.Font.Underline := 5;
      If Barre in Attribut then
         InstanceDeExcel.Selection.Font.Strikethrough := true
      else
         InstanceDeExcel.Selection.Font.Strikethrough := false;
      If Exposant in Attribut then
         Begin
            InstanceDeExcel.Selection.Font.Superscript := true;
            InstanceDeExcel.Selection.Font.Subscript := false;
         End
      else
         Begin
            If Indice in Attribut then
               Begin
                  InstanceDeExcel.Selection.Font.Superscript := false;
                  InstanceDeExcel.Selection.Font.Subscript := true;
               End
            else
               Begin
                  InstanceDeExcel.Selection.Font.Superscript := false;
                  InstanceDeExcel.Selection.Font.Subscript := false;
               End;
         End;
   End;

    Procedure PoliceTexteCellule(Var InstanceDeExcel: variant; DebutTexte,LongTexte: Integer;
                      NomPolice: string; Taille: Integer;
                      Couleur: TColor; StylePolice: TStylePolice;
                      Soulignement: TSoulignementPolice; Attribut: TAttributsPolice);
    begin
      If NomPolice <> '' then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Name:=NomPolice;
      If Couleur <> ClDefault then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Color:=Couleur;
      If Taille > 0 then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Size:=Taille;
      If StylePolice = Normal then
         Begin
            InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Bold := false;
            InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Italic := false;
         End;
      If StylePolice = Gras then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Bold := true;
      If StylePolice = Italique then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Italic := true;
      If StylePolice = GrasItalique then
         Begin
            InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Bold := true;
            InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Italic := true;
         End;
      If Soulignement = Aucun then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Underline := -4142;
      If Soulignement = Aucun then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Underline := -4142;
      If Soulignement = TraitSimple then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Underline := 2;
      If Soulignement = TraitDouble then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Underline := -4119;
      If Soulignement = ComptabiliteSimple then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Underline :=  4;
      If Soulignement = ComptabiliteDouble then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Underline := 5;
      If Barre in Attribut then
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Strikethrough := true
      else
         InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Strikethrough := false;
      If Exposant in Attribut then
         Begin
            InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Superscript := true;
            InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Subscript := false;
         End
      else
         Begin
            If Indice in Attribut then
               Begin
                  InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Superscript := false;
                  InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Subscript := true;
               End
            else
               Begin
                  InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Superscript := false;
                  InstanceDeExcel.ActiveCell.Characters[DebutTexte,LongTexte].Font.Subscript := false;
               End;
         End;
   End;


    // Change la couleur du fond de sélection
    Procedure CouleurFondSelection(Var InstanceDeExcel: variant; Couleur: TColor);
    Begin
       InstanceDeExcel.Selection.Interior.Color := Couleur;
    End;

    // Règle l'alignement de la sélection

    Procedure AligneSelection(Var InstanceDeExcel: variant; Alignement: TalignementCellule);
    Const
       AlGeneral = 1;
       AlGauche = -4131;
       AlCentre = -4108;
       AlDroite = -4152;
       AlRecopie = 5;
       AlJustifie = -4130;
       AlCentreSurSelection = 7;
    Begin
       Case Alignement of
          General: InstanceDeExcel.Selection.horizontalalignment:=AlGeneral;
          Gauche: InstanceDeExcel.Selection.horizontalalignment:=AlGauche;
          Centre: InstanceDeExcel.Selection.horizontalalignment:=AlCentre;
          Droite: InstanceDeExcel.Selection.horizontalalignment:=AlDroite;
          Recopie: InstanceDeExcel.Selection.horizontalalignment:=AlRecopie;
          Justifie: InstanceDeExcel.Selection.horizontalalignment:=AlJustifie;
          CentreSurSelection: InstanceDeExcel.Selection.horizontalalignment:=AlCentreSurSelection;
       End;
    End;

    // Définit les traits autour d'une sélection
    Procedure Bordures(Var InstanceDeExcel: variant; Bords: TBordures; TypeBordure: TTypeBordures;
                       Epaisseur: Integer); Overload;
    Var
       TypeBord: Integer;
    Begin
       If TypeBordure = Continu then
          TypeBord := 1;
       If TypeBordure = Discontinu then
          TypeBord := 2;
       If TypeBordure = Tiret then
          TypeBord := -4115;
       If TypeBordure = TiretPoint then
          TypeBord := 4;
       If TypeBordure = TiretPointPoint then
          TypeBord := 5;
       If TypeBordure = Point then
          TypeBord := -4118;
       If TypeBordure = BordDouble then
          TypeBord := -4119;
       If TypeBordure = Sans then
          TypeBord := -4142;
       If TypeBordure = TiretPointIncline then
          TypeBord := 13;
       If BdGauche in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[7].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[7].Weight := Epaisseur;
          End;
       If BdHaute in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[8].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[8].Weight := Epaisseur;
          End;
       If BdBasse in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[9].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[9].Weight := Epaisseur;
          End;
       If BdDroite in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[10].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[10].Weight := Epaisseur;
          End;
       If BdInterieureVert in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[11].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[11].Weight := Epaisseur;
          End;
       If BdInterieureHor in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[12].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[12].Weight := Epaisseur;
          End;
       If BdDiagonaleDescendante in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[5].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[5].Weight := Epaisseur;
          End;
       If BdDiagonaleMontante in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[6].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[6].Weight := Epaisseur;
          End;
    End;

    // Définit les traits autour d'une sélection
    Procedure Bordures(Var InstanceDeExcel: variant; Bords: TBordures; TypeBordure: TTypeBordures;
                      Epaisseur: Integer; Couleur: TColor); Overload;
    Var
       TypeBord: Integer;
    Begin
       If TypeBordure = Continu then
          TypeBord := 1;
       If TypeBordure = Discontinu then
          TypeBord := 2;
       If TypeBordure = Tiret then
          TypeBord := -4115;
       If TypeBordure = TiretPoint then
          TypeBord := 4;
       If TypeBordure = TiretPointPoint then
          TypeBord := 5;
       If TypeBordure = Point then
          TypeBord := -4118;
       If TypeBordure = BordDouble then
          TypeBord := -4119;
       If TypeBordure = Sans then
          TypeBord := -4142;
       If TypeBordure = TiretPointIncline then
          TypeBord := 13;
       If BdGauche in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[7].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[7].Weight := Epaisseur;
             InstanceDeExcel.Selection.Borders[7].Color := Couleur;
          End;
       If BdHaute in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[8].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[8].Weight := Epaisseur;
             InstanceDeExcel.Selection.Borders[8].Color := Couleur;
          End;
       If BdBasse in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[9].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[9].Weight := Epaisseur;
             InstanceDeExcel.Selection.Borders[9].Color := Couleur;
          End;
       If BdDroite in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[10].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[10].Weight := Epaisseur;
             InstanceDeExcel.Selection.Borders[10].Color := Couleur;
          End;
       If BdInterieureVert in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[11].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[11].Weight := Epaisseur;
             InstanceDeExcel.Selection.Borders[11].Color := Couleur;
          End;
       If BdInterieureHor in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[12].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[12].Weight := Epaisseur;
             InstanceDeExcel.Selection.Borders[12].Color := Couleur;
          End;
       If BdDiagonaleDescendante in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[5].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[5].Weight := Epaisseur;
             InstanceDeExcel.Selection.Borders[5].Color := Couleur;
          End;
       If BdDiagonaleMontante in Bords then
          Begin
             InstanceDeExcel.Selection.Borders[6].LineStyle := TypeBord;
             InstanceDeExcel.Selection.Borders[6].Weight := Epaisseur;
             InstanceDeExcel.Selection.Borders[6].Color := Couleur;
          End;
    End;

    // Provoque l'autodimensionnement d'une colonne aux valeurs
    Procedure LargeurAuto(Var InstanceDeExcel: variant; Colonne: String);
    Begin
       InstanceDeExcel.Range[Colonne].select;
       InstanceDeExcel.selection.EntireColumn.AutoFit;
    End;

   // Provoque l'autodimensionnement d'une Ligne aux valeurs
   Procedure HauteurAuto(Var InstanceDeExcel: variant; Ligne: String);
   Begin
      InstanceDeExcel.Range[Ligne].select;
      InstanceDeExcel.selection.EntireRow.AutoFit;
   End;


// Procédures pour l'impression

 // Impression avec nombre de copies

//==============================================================================
Procedure Impression(var InstanceDeExcel: variant; NbCopie: Integer); Overload;
begin
  InstanceDeExcel.ActiveWindow.SelectedSheets.PrintOut(NbCopie);
//print directly
end;

 // Impression avec nombre de copies et nom imprimante

//==============================================================================
Procedure Impression(var InstanceDeExcel: variant; NbCopie: Integer; NomImprimante: String); Overload;
begin
  InstanceDeExcel.ActivePrinter := NomImprimante;
  InstanceDeExcel.ActiveWindow.SelectedSheets.PrintOut(NbCopie);
//print directly
end;


// Orientations de la de copies
//==============================================================================
Procedure OrientationDeLaCopieImp(var InstanceDeExcel: variant; Orientation:
TPrinterOrientation);
begin
  Case Orientation of
     Portrait: InstanceDeExcel.ActiveSheet.PageSetup.Orientation := 1;
     Paysage: InstanceDeExcel.ActiveSheet.PageSetup.Orientation := 2;
     //landscape=2 Portrait=1
   End;
end;

//Grille visible de la copie
//==============================================================================
Procedure GrilleVisibleImp(var InstanceDeExcel: variant; Visible : Boolean);
begin
  InstanceDeExcel.ActiveSheet.PageSetup.PrintGridlines := Visible;
end;

//centre la copie horizontallement
//==============================================================================
Procedure CentrerHorizontalImp(var InstanceDeExcel: variant; Centrer :
Boolean);
begin
  InstanceDeExcel.ActiveSheet.PageSetup.CenterHorizontally := Centrer;
end;

//centre la copie verticallement
//==============================================================================
Procedure CentrerVerticalImp(var InstanceDeExcel: variant; Centrer :
Boolean);
begin
  InstanceDeExcel.ActiveSheet.PageSetup.CenterVertically := Centrer;
end;

//Pour zoomer  la copie
//==============================================================================
Procedure ZoomPourCentImp(var InstanceDeExcel: variant; n : Integer);
begin
  InstanceDeExcel.ActiveSheet.PageSetup.Zoom := n;
end;

//Pour fixer les marge
//==============================================================================
Procedure MargeImp(var InstanceDeExcel: variant;
Left,Right,Top,Bottom,Header,Footer : Double);
begin
  InstanceDeExcel.ActiveSheet.PageSetup.LeftMargin  :=
InstanceDeExcel.CentimetersToPoints(Left);
  InstanceDeExcel.ActiveSheet.PageSetup.RightMargin :=
InstanceDeExcel.CentimetersToPoints(Right);
  InstanceDeExcel.ActiveSheet.PageSetup.TopMargin   :=
InstanceDeExcel.CentimetersToPoints(Top);
  InstanceDeExcel.ActiveSheet.PageSetup.BottomMargin:=
InstanceDeExcel.CentimetersToPoints(Bottom);
  InstanceDeExcel.ActiveSheet.PageSetup.HeaderMargin:=
InstanceDeExcel.CentimetersToPoints(Header);
  InstanceDeExcel.ActiveSheet.PageSetup.FooterMargin:=
InstanceDeExcel.CentimetersToPoints(Footer);
end;

// Pour faire tenir la largeur du tableau dans une page
//==============================================================================
Procedure AjusterLargeurTableImp(var InstanceDeExcel: variant; SurNbdePages: Integer);
Begin
   InstanceDeExcel.ActiveSheet.PageSetup.Zoom := false;
   InstanceDeExcel.ActiveSheet.PageSetup.FitToPagesWide := SurNbDePages;
   InstanceDeExcel.ActiveSheet.PageSetup.FitToPagesTall := false;
End;

//Pour sélectionner la zone d'impression
//==============================================================================
Procedure SelectionnerZoneDImpression(var InstanceDeExcel: variant;Zone: String);
Begin
   InstanceDeExcel.ActiveSheet.PageSetup.PrintArea := Zone;
End;

//Pour Insérer un saut de page audessus de la ligne donnée
//==============================================================================
Procedure InsereSautDePage(var InstanceDeExcel: variant; Ligne: String);
Var
   SelectionActuelle: String;
Begin
   SelectionActuelle := LireNumeroCellule(InstanceDeExcel);
   SelectionCellules(InstanceDeExcel,'A'+Ligne);
   InstanceDeExcel.ActiveWindow.SelectedSheets.HPageBreaks.Add(InstanceDeExcel.ActiveCell);
   SelectionCellules(InstanceDeExcel,SelectionActuelle);
   {InstanceDeExcel.ActiveCell.Row(StrToInt(Ligne)).PageBreak:=-4105;}
End;

//Pour imprimer en couleur ou non
//==============================================================================
Procedure CouleurImp(var InstanceDeExcel: variant; Couleur: Boolean);
Begin
   InstanceDeExcel.ActiveSheet.PageSetup.BlackAndWhite := Not Couleur;
End;

//Pour définir les lignes et colonnes à répéter en haut et à gauche
//==============================================================================
Procedure RepeteLigneColonneImp(var InstanceDeExcel: variant;Lignes,Colonnes:
                                String);
Begin
   InstanceDeExcel.ActiveSheet.PageSetup.PrintTitleRows := Lignes;
   InstanceDeExcel.ActiveSheet.PageSetup.PrintTitleColumns := Colonnes;
End;

//Pour définir têtière et bas de page
//==============================================================================
Procedure TetiereBasDePageImp(var InstanceDeExcel: variant; TeteGauche,TeteCentre,
                              TeteDroite,BasGauche,BasCentre,BasDroite: string);
Begin
   InstanceDeExcel.ActiveSheet.PageSetup.LeftHeader := TeteGauche;
   InstanceDeExcel.ActiveSheet.PageSetup.CenterHeader := TeteCentre;
   InstanceDeExcel.ActiveSheet.PageSetup.RightHeader := TeteDroite;
   InstanceDeExcel.ActiveSheet.PageSetup.LeftFooter := BasGauche;
   InstanceDeExcel.ActiveSheet.PageSetup.CenterFooter := BasCentre;
   InstanceDeExcel.ActiveSheet.PageSetup.RightFooter := BasDroite;
End;

//Pour Donner la taille du papier dans l'imprimante
//==============================================================================
Procedure TaillePapierImp(var InstanceDeExcel: variant;TypePapier: TTypePapier);
var
   TypeExcel: Integer;
Begin
   Case TypePapier of
      Format10x14: TypeExcel := 16;
      Format11x17: TypeExcel := 17;
      FormatA3: TypeExcel := 8;
      FormatA4: TypeExcel := 9;
      FormatA4Small: TypeExcel := 10;
      FormatA5: TypeExcel := 11;
      FormatB4: TypeExcel := 12;
      FormatB5: TypeExcel := 13;
      FormatCsheet: TypeExcel := 24;
      FormatDsheet: TypeExcel := 25;
      FormatEnvelope10: TypeExcel := 20;
      FormatEnvelope11: TypeExcel := 21;
      FormatEnvelope12: TypeExcel := 22;
      FormatEnvelope14: TypeExcel := 23;
      FormatEnvelope9: TypeExcel :=  19;
      FormatEnvelopeB4: TypeExcel := 33;
      FormatEnvelopeB5: TypeExcel := 34;
      FormatEnvelopeB6: TypeExcel := 35;
      FormatEnvelopeC3: TypeExcel := 29;
      FormatEnvelopeC4: TypeExcel := 30;
      FormatEnvelopeC5: TypeExcel := 28;
      FormatEnvelopeC6: TypeExcel := 31;
      FormatEnvelopeC65: TypeExcel := 32;
      FormatEnvelopeDL: TypeExcel := 27;
      FormatEnvelopeItaly: TypeExcel := 36;
      FormatEnvelopeMonarch: TypeExcel := 37;
      FormatEnvelopePersonal: TypeExcel := 38;
      FormatEsheet: TypeExcel := 26;
      FormatExecutive: TypeExcel := 7;
      FormatFanfoldLegalGerman: TypeExcel := 41;
      FormatFanfoldStdGerman: TypeExcel := 40;
      FormatFanfoldUS: TypeExcel := 39;
      FormatFolio: TypeExcel := 14;
      FormatLedger: TypeExcel := 4;
      FormatLegal: TypeExcel := 5;
      FormatLetter: TypeExcel := 1;
      FormatLetterSmall: TypeExcel := 2;
      FormatNote: TypeExcel := 18;
      FormatQuarto: TypeExcel := 15;
      FormatStatement: TypeExcel := 6;
      FormatTabloid: TypeExcel := 3;
      FormatUser: TypeExcel := 256;
   End;
   Try
      InstanceDeExcel.ActiveSheet.PageSetup.PaperSize := TypeExcel;
   Except
      Begin
         MessageDlg('Votre imprimante ne supporte pas ce format !'+chr(13)+
                    'Retour au format A4',MtError,[MbOK],0);
         InstanceDeExcel.ActiveSheet.PageSetup.PaperSize := 9;
      End;
   End;   
End;

// Pour donner le numéro de départ de pagination de la première page
//==============================================================================
Procedure NumeroPageImp(var InstanceDeExcel: variant; NoPremierePage: Integer);
Begin
   InstanceDeExcel.ActiveSheet.PageSetup.FirstPageNumber := NoPremierePage;
End;

//===Format Hauteur de ligne
//==============================================================================
Procedure HauteurLignes(Var InstanceDeExcel: variant; Hauteur: double);
begin
      InstanceDeExcel.Selection.RowHeight:=Hauteur; //Selection.RowHeight = 2
end;


//===Format Largeur de colonne
//==============================================================================
Procedure LargeurColonnes(Var InstanceDeExcel: variant; Largeur: double);
begin
      InstanceDeExcel.Selection.ColumnWidth:=Largeur; //Selection.ColumnWidth = 2
end;


// Sélectionner de toute la page
//==============================================================================
Procedure SelectionToutelaPage(Var InstanceDeExcel: Variant);
Begin
   InstanceDeExcel.Cells.Select;
End;

// Ajuster lignes et colonnes de toute la page
//==============================================================================
Procedure AutoAjusterToutelaPage(Var InstanceDeExcel: Variant);
Var
   SelectionActuelle: String;
Begin
   SelectionActuelle := LireNumeroCellule(InstanceDeExcel);
   InstanceDeExcel.Cells.Select;
   InstanceDeExcel.Cells.EntireColumn.AutoFit;
   InstanceDeExcel.Cells.EntireRow.AutoFit;
   SelectionCellules(InstanceDeExcel,SelectionActuelle);
End;

Function LibelleCellule(Colonne,Ligne: Integer): String;
Const
   Erreur = 'DEPASSEMENT';
Var
   Lettre1,
   Lettre2: Integer;
Begin
   If (Colonne < 1) or (Colonne > 256) Then
      Begin
         LibelleCellule := Erreur;
      End;
   If (Ligne < 1) or (Ligne > 65536) then
      Begin
         LibelleCellule := Erreur;
      End;
   If Result <> Erreur then
      Begin
         Lettre1 := (Colonne-1) mod 26;
         Lettre2 := (Colonne-1) Div 26;
         If Lettre2 > 0 then
            LibelleCellule := Chr(Lettre2 + 64)+Chr(Lettre1 + 65) + IntToStr(Ligne)
         else
            LibelleCellule := Chr(Lettre1 + 65) + IntToStr(Ligne);
      End;
End;

Procedure LigneColonne(Cellule: String; Var Lig,Col: Integer);
var
   Lettres: String;
   Lettre1,
   Lettre2: Char;
   Code: Integer;
Begin
   Cellule := Uppercase(Cellule);
   Lettres := '';
   Repeat
      Lettres := Lettres+Cellule[1];
      Delete(Cellule,1,1);
   Until Cellule[1] < 'A';
   Val(Cellule,Lig,Code);
   If Length(Lettres) = 2 then
      Begin
         Lettre2 := Lettres[2];
      End
   else
      Begin
         Lettre2 := '0';
      End;
   Lettre1 := Lettres[1];
   If Lettre2 <> '0' then
      Col := Ord(Lettre2)-64 + (Ord(Lettre1)-64)*26
   else
      Col := Ord(Lettre1)-64;
End;

Function LigneVide(Var InstanceDeExcel: variant;NumLigne,NbColonne: integer): Boolean;
var
   i: integer;
   Vide: Boolean;
   Cellule: String;
Begin
   Vide := true;
   For i := 1 to NbColonne do
      Begin
         Cellule := LibelleCellule(i,NumLigne);
         If RecupereValeurFormule(InstanceDeExcel,Valeur,Cellule) <> '' then
            Begin
               Vide := false;
               Break;
            End;
      End;
   LigneVide := Vide;
End;

Function DerniereLigne(Var InstanceDeExcel: variant;NbColonne: integer): Integer;
var
   NumLig,
   Pas: integer;
begin
   NumLig := 65536;
   Pas := NumLig;
   Repeat
      Pas := Pas div 2;
      If LigneVide(InstanceDeExcel,NumLig,NbColonne) then
         Begin
            NumLig := NumLig -Pas;
            If NumLig < 0 then
               Begin
                  NumLig := 1;
                  Pas := 0;
               End;
         End
      else
         Begin
            NumLig := NumLig + Pas;
            If NumLig > 65536 Then
               Begin
                  NumLig := 65536;
                  Pas := 0
               End;
         End;
   Until Pas = 0;
   While Not LigneVide(InstanceDeExcel,NumLig,NbColonne) do
      Begin
         Inc(NumLig);
         If Numlig > 65536 then
            Begin
               NumLig := 65536;
               Break;
            End;
      End;
   While LigneVide(InstanceDeExcel,NumLig,NbColonne) do
      Begin
         dec(NumLig);
         If NumLig < 1 then
            Begin
               NumLig := 1;
               Break;
            End;
      End;
   DerniereLigne := NumLig;
End;

// Renvoie le libellé de la dernière callule et la sélectionne (vaut Ctrl Fin)
//==============================================================================
Function DerniereCellule(Var InstanceDeExcel: variant): string;
Begin
   InstanceDeExcel.ActiveCell.SpecialCells(11).Select;
   DerniereCellule := LireNumeroCellule(InstanceDeExcel);
End;

// Applique à la cellule le formatage pour les formats standard et texte
//==============================================================================
Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatStandard); Overload;
Begin
   Case TypeDonnee of
      StandardAuto: Begin
                       InstanceDeExcel.Selection.NumberFormat := 'Standard';
                    End;
      Texte: Begin
                InstanceDeExcel.Selection.NumberFormat := string('@');
             End;
   End;
End;


// Applique à la cellule le formatage pour les formats nombre
//==============================================================================
Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatNumerique;Decimale: Integer;
                       SeparateurDeMilliers: Boolean; LeNegatif: TTypeNegatif); Overload;
Var
   SuffixeRetraitPlus,
   SuffixeRetraitMoins,
   SeparateurMilliers,
   Formatage: string;
   i: Integer;
Begin
   Case TypeDonnee of
      Nombre: Begin
                 SuffixeRetraitPlus := '_ ';
                 SuffixeRetraitMoins := '\ ';
                 If SeparateurDeMilliers then
                    SeparateurMilliers := '#'+FormatSettings.ThousandSeparator+'##0'
                 else
                    SeparateurMilliers := '0';
                 If Decimale > 0 then
                    Begin
                       SeparateurMilliers := SeparateurMilliers + FormatSettings.DecimalSeparator;
                       For i := 1 to Decimale do
                          Begin
                             SeparateurMilliers := SeparateurMilliers+'0';
                          End;
                    End;
                  Case LeNegatif of
                     NegMoins: Formatage := SeparateurMilliers;
                     NegRouge: Formatage := SeparateurMilliers + ';[Rouge]'
                                            + SeparateurMilliers;
                     NegMoinsRetrait: Formatage := SeparateurMilliers+ SuffixeRetraitPlus +
                                      ';-' + SeparateurMilliers + SuffixeRetraitMoins;
                     NegMoinsRouge: Formatage := SeparateurMilliers + SuffixeRetraitPlus +
                                    ';[Rouge]-' + SeparateurMilliers + SuffixeRetraitMoins;
                  End;
                  InstanceDeExcel.Selection.NumberFormat := Formatage;
               End;
   End;
End;

      // Applique à la cellule le formatage pour les formats monnaie
      //==============================================================================
Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatMonnaie;Decimale: Integer;
                       LeNegatif: TTypeNegatif;LaMonnaie: TTypeMonnaie); Overload;
Var
   PrefixeMonnaie,
   SuffixeMonnaie,
   SuffixeRetraitPlus,
   SuffixeRetraitMoins,
   SeparateurMilliers,
   Formatage: string;
   i: Integer;
Begin
   Case TypeDonnee of
      Monnaie: Begin
                  PrefixeMonnaie := '';
                  SuffixeMonnaie := '';
                  SuffixeRetraitPlus := '';
                  SuffixeRetraitMoins := '';
                  SeparateurMilliers := '#'+FormatSettings.ThousandSeparator+'##0';
                  If Decimale > 0 then
                     Begin
                        SeparateurMilliers := SeparateurMilliers + FormatSettings.DecimalSeparator;
                        For i := 1 to Decimale do
                           Begin
                              SeparateurMilliers := SeparateurMilliers+'0';
                           End;
                     End;
                  Case LaMonnaie of
                     Aucune: Begin
                                PrefixeMonnaie := '';
                                SuffixeMonnaie := '\ _€';
                                SuffixeRetraitPlus := '';
                                SuffixeRetraitMoins := '';
                             End;
                     Euro: Begin
                              PrefixeMonnaie := '';
                              SuffixeMonnaie := ' €';
                              SuffixeRetraitPlus := '_ ';
                              SuffixeRetraitMoins := '\ ';
                           End;
                     DollarAnglaisEtasUnis: Begin
                                               PrefixeMonnaie := '[$$-409] ';
                                               SuffixeMonnaie := '';
                                               SuffixeRetraitPlus := '_ ';
                                               SuffixeRetraitMoins := '\ ';
                                            End;
                     PesetasEspagnol: Begin
                                         PrefixeMonnaie := '[$Pts-140A] ';
                                         SuffixeMonnaie := '';
                                         SuffixeRetraitPlus := '_ ';
                                         SuffixeRetraitMoins := '\ ';
                                      End;
                     LivreAnglais: Begin
                                      PrefixeMonnaie := '[$£-809] ';
                                      SuffixeMonnaie := '';
                                      SuffixeRetraitPlus := '_ ';
                                      SuffixeRetraitMoins := '\ ';
                                   End;
                     EuroEnTete: Begin
                                    PrefixeMonnaie := '[$€-2] ';
                                    SuffixeMonnaie := '';
                                    SuffixeRetraitPlus := '_ ';
                                    SuffixeRetraitMoins := '\ ';
                                 End;
                     EuroEnQueue: Begin
                                     PrefixeMonnaie := '';
                                     SuffixeMonnaie := '\ [$€-1]';
                                     SuffixeRetraitPlus := '_ ';
                                     SuffixeRetraitMoins := '\ ';
                                  End;
                     DMAllemand: Begin
                                    PrefixeMonnaie := '';
                                    SuffixeMonnaie := '\ [$DM-407]';
                                    SuffixeRetraitPlus := '_ ';
                                    SuffixeRetraitMoins := '\ ';
                                 End;
                     FrancFrancaisStandard: Begin
                                               PrefixeMonnaie := '';
                                               SuffixeMonnaie := '\ [$F-40C]';
                                               SuffixeRetraitPlus := '_ ';
                                               SuffixeRetraitMoins := '\ ';
                                            End;
                  End;
                  Case LeNegatif of
                     NegMoins: Formatage := PrefixeMonnaie + SeparateurMilliers +
                                            SuffixeMonnaie;
                     NegRouge: Formatage := PrefixeMonnaie + SeparateurMilliers +
                               SuffixeMonnaie +
                               ';[Rouge]' + PrefixeMonnaie + SeparateurMilliers +
                               SuffixeMonnaie;
                     NegMoinsRetrait: Formatage := PrefixeMonnaie + SeparateurMilliers +
                                      SuffixeMonnaie + SuffixeRetraitPlus +
                                      ';'+PrefixeMonnaie + '-' + SeparateurMilliers +
                                      SuffixeMonnaie + SuffixeRetraitMoins;
                     NegMoinsRouge: Formatage := PrefixeMonnaie + SeparateurMilliers +
                                    SuffixeMonnaie + SuffixeRetraitPlus +
                                    ';[Rouge]'+PrefixeMonnaie + '-' + SeparateurMilliers +
                                    SuffixeMonnaie + SuffixeRetraitMoins;
                  End;
                  InstanceDeExcel.Selection.NumberFormat := Formatage;
               End;
   End;
End;

// Applique à la cellule le formatage pour les formats comptabilité
//==============================================================================
Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatComptable;
                       Decimale: Integer); Overload;
var
   SeparateurMilliers,
   NbJoker,
   Formatage: string;
   i: Integer;
Begin
   Formatage := '';
   SeparateurMilliers := '#'+FormatSettings.ThousandSeparator+'##0';
   NbJoker := '';
   If Decimale > 0 then
      Begin
         SeparateurMilliers := SeparateurMilliers + FormatSettings.DecimalSeparator;
         For i := 1 to Decimale do
            Begin
               SeparateurMilliers := SeparateurMilliers+'0';
               NbJoker := NbJoker + '?';
            End;
      End;
   Case TypeDonnee of
      EnEuro: Formatage := '_-* '+SeparateurMilliers+' €_-;-* '+SeparateurMilliers+' €_-;_-* "-"'+NbJoker+' €_-;_-@_- ';
      EnDollarAnglaisEtasUnis: Formatage := '_-[$$-409]* '+SeparateurMilliers+'_ ;_-[$$-409]* -'+SeparateurMilliers+'\ ;_-[$$-409]* "-"'+NbJoker+'_ ;_-@_ ';
      EnPesetasEspagnol: Formatage := '_-[$Pts-140A]* '+SeparateurMilliers+'_ ;_-[$Pts-140A]* -'+SeparateurMilliers+'\ ;_-[$Pts-140A]* "-"'+NbJoker+'_ ;_-@_ ';
      EnLivreAnglais: Formatage := '_-[$£-809]* '+SeparateurMilliers+'_-;-[$£-809]* '+SeparateurMilliers+'_-;_-[$£-809]* "-"'+NbJoker+'_-;_-@_- ';
      EnDMAllemand: Formatage := '_-* '+SeparateurMilliers+'\ [$DM-407]_-;-* '+SeparateurMilliers+'\ [$DM-407]_-;_-* "-"'+NbJoker+'\ [$DM-407]_-;_-@_- ';
      EnFrancFrancaisStandard: Formatage := '_-* '+SeparateurMilliers+'\ [$F-40C]_-;-* '+SeparateurMilliers+'\ [$F-40C]_-;_-* "-"'+NbJoker+'\ [$F-40C]_-;_-@_- ';
   End;
   If Formatage <> '' then
      Begin
         InstanceDeExcel.Selection.NumberFormat := Formatage;
      End;
End;

// Applique à la cellule le formatage pour les formats Date Heure, Fraction et Special
//==============================================================================
Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatDateEtDivers;
                       LeFormat: String); Overload;
Begin
   Case TypeDonnee of
        DateEtHeure,Fraction,Special: Begin
                                         If LeFormat <> '' then
                                            Begin
                                               InstanceDeExcel.Selection.NumberFormat := LeFormat;
                                            End;
                                      End;
   End;
End;

// Applique à la cellule le formatage pour les formats pourcentage et scientifique
//==============================================================================
Procedure FormatCellule(Var InstanceDeExcel: variant;TypeDonnee: TFormatScientifique;
                       Decimale: Integer); Overload;
Var
   SeparateurMilliers,
   Formatage: string;
   i: Integer;
Begin
   Formatage := '';
   Case TypeDonnee of
      PourCent: Begin
                   SeparateurMilliers := '0';
                   If Decimale > 0 then
                      Begin
                         SeparateurMilliers := SeparateurMilliers + FormatSettings.DecimalSeparator;
                            For i := 1 to Decimale do
                               Begin
                                  SeparateurMilliers := SeparateurMilliers+'0';
                               End;
                      End;
                   Formatage := SeparateurMilliers + '%';
                End;
      Scientifique: Begin
                       SeparateurMilliers := '0' + FormatSettings.DecimalSeparator;
                       If Decimale > 0 then
                          Begin
                             For i := 1 to Decimale do
                                Begin
                                   SeparateurMilliers := SeparateurMilliers+'0';
                                End;
                          End;
                       Formatage := SeparateurMilliers + 'E+00';
                    End;
   End;
   InstanceDeExcel.Selection.NumberFormat := Formatage;
End;

// Renvoie le format lu dans la cellule
//==============================================================================
Function FormatCellule(Var InstanceDeExcel: variant;Cellule: String): String; Overload;
Var
   SelectionActuelle: String;
Begin
   SelectionActuelle := LireNumeroCellule(InstanceDeExcel);
   SelectionCellules(InstanceDeExcel,Cellule);
   FormatCellule := InstanceDeExcel.Selection.NumberFormat;
   SelectionCellules(InstanceDeExcel,SelectionActuelle);
End;

// Aligne le texte horizontalement et verticalement
//==============================================================================
Procedure AlignementTexte(Var InstanceDeExcel: variant;AlignHor: TAlignementCellule;
                          Retrait: Integer;AlignVert: TalignementVertCellule);
Const
   AlGeneral = 1;
   AlGauche = -4131;
   AlCentre = -4108;
   AlDroite = -4152;
   AlRecopie = 5;
   AlJustifie = -4130;
   AlCentreSurSelection = 7;
   AlBas = -4107;
   AlHaut = -4160;
Begin
   If Retrait < 0 then
      Retrait := 0;
   If Retrait > 15 then
      Retrait := 15;
   If Retrait > 0 then
      AlignHor := Gauche;
   Case AlignHor of
      General: InstanceDeExcel.Selection.HorizontalAlignment := AlGeneral;
      Gauche: Begin
                 If Retrait > 0 then
                    Begin
                       InstanceDeExcel.Selection.IndentLevel := Retrait;
                    End
                 else
                    Begin
                       InstanceDeExcel.Selection.IndentLevel := 0;
                    End;
                 InstanceDeExcel.Selection.HorizontalAlignment := AlGauche;
              End;
      Centre: InstanceDeExcel.Selection.HorizontalAlignment := AlCentre;
      Droite: InstanceDeExcel.Selection.HorizontalAlignment := AlDroite;
      Recopie: InstanceDeExcel.Selection.HorizontalAlignment := AlRecopie;
      Justifie: InstanceDeExcel.Selection.HorizontalAlignment := AlJustifie;
      CentreSurSelection: InstanceDeExcel.Selection.HorizontalAlignment := AlCentreSurSelection;
   End;
   Case AlignVert of
      VHaut: InstanceDeExcel.Selection.VerticalAlignment := AlHaut;
      VCentre: InstanceDeExcel.Selection.VerticalAlignment := AlCentre;
      VBas: InstanceDeExcel.Selection.VerticalAlignment := AlBas;
      VJustifie: InstanceDeExcel.Selection.VerticalAlignment := AlJustifie;
   End;
End;

// Controle le comportement du texte Retour à la ligne, fusion cellule, adaptation
//==============================================================================
Procedure ControleTexte(Var InstanceDeExcel: variant;RenvoiALaLigne,Adapter,FusionCellules: Boolean);
Begin
   InstanceDeExcel.Selection.WrapText := RenvoiALaLigne;
   InstanceDeExcel.Selection.ShrinkToFit := Adapter and Not RenvoiALaLigne;
   InstanceDeExcel.Selection.MergeCells := FusionCellules;
End;

// Controle l'orientation du texte
//==============================================================================
Procedure OrientationTexte(Var InstanceDeExcel: variant;Inclinaison: Integer);
Begin
   If Inclinaison <> OrVertical then
      Begin
         If Inclinaison < -90 then
            Inclinaison := -90;
         If Inclinaison > 90 then
            Inclinaison := 90;
      End;
   InstanceDeExcel.Selection.Orientation := Inclinaison;
End;

// Passe la sélection en filtre automatique (bascule)
//==============================================================================
Procedure FiltreAuto(Var InstanceDeExcel: variant; Cellules: string);
Var
   SelectionActuelle: String;
Begin
   SelectionActuelle := LireNumeroCellule(InstanceDeExcel);
   SelectionCellules(InstanceDeExcel,Cellules);
   InstanceDeExcel.Selection.AutoFilter;
   SelectionCellules(InstanceDeExcel,SelectionActuelle);
End;

// Sélectionner Une ou plusieurs Colonnes du classeur actif
Procedure SelectionColonnes(Var InstanceDeExcel: Variant;Colonnes: string);
var
   ColDeb,
   ColFin: String;
   k: Integer;
Begin
   K := Pos(':',Colonnes);
   ColDeb := Copy(Colonnes,1,k-1);
   Delete(Colonnes,1,k);
   ColFin := Colonnes;
   ColDeb := ColDeb+'1';
   ColFin := ColFin+'65536';
   SelectionCellules(InstanceDeExcel,ColDeb+':'+ColFin);
End;



// Sélectionner Une ou plusieurs lignes du classeur actif
Procedure SelectionLignes(Var InstanceDeExcel: Variant;Lignes: string);
Var
   LigDeb,
   LigFin: String;
   k: Integer;
Begin
   K := Pos(':',Lignes);
   LigDeb := Copy(Lignes,1,k-1);
   Delete(Lignes,1,k);
   LigFin := Lignes;
   LigDeb := 'A'+LigDeb;
   LigFin := 'IV'+LigFin;
   SelectionCellules(InstanceDeExcel,LigDeb+':'+LigFin);
End;

function colonneLettre(col: byte): string;
var
  reste, quotient,A: integer;
begin
  Result := '';
  A := Pred(Ord('A'));
  quotient := col div 26;
  reste := col mod 26;
  if (quotient = 0) and (reste = 0) then Exit;

  if quotient = 0 then
  begin
    Result := Chr(A+reste);
  end
  else
  begin
    if reste = 0 then
    begin
      Dec(quotient);
      if quotient = 0 then
        Result := Chr(A+26)
      else
        Result := Chr(A+quotient) + Chr(A+26);
    end
    else
    begin
      Result := Chr(A+quotient)+Chr(A+reste);
    end;
  end;
end;

function colLetter(col: byte): string;
begin
//  Result := Chr(Ord('A')+col-1);
  Result := colonneLettre(col);
end;

initialization
   jmS := 'j/m';                                  // 2/9
   jmaaS := 'j/m/aa';                             // 2/9/04
   jjmmaaS := 'jj/mm/aa';                         // 02/09/04
   jmmmT := 'j-mmm';                              // 2-sept
   jmmmaaT := 'j-mmm-aa';                         // 2-sept-04
   jjmmmaaT := 'jj-mmm-aa';                       // 02-sept-04
   mmmaaT := 'mmm-aa';                            // sept-04
   mmmmaaT := 'mmmm-aa';                          // septembre-04
   jmmmmaaaa_ := 'j mmmm aaaa';                   // 2 septembre 2004
   jmaaS_hmm_AMPM := 'j/m/aa h:mm AM/PM';         // 2/9/04 1:27 PM
   jmaaS_hmm := 'j/m/aa h:mm';                    // 2/9/04 13:27
   mmmmm := 'mmmmm';                              // s
   mmmmmaaT := 'mmmmm-aa';                        // s-04
   mjaaaaS := 'm/j/aaaa';                         // 9/2/2004
   jmmmaaaaT := 'j-mmm-aaaa';                     // 2-sept-2004
   jjjj_le_j_mmmm_aaaa := 'jjjj, l\e j mmmm aaaa';// jeudi, le 2 septembre 2004
   aaaajjmmmmS := 'aaaa/jj/mmmm';                 // 2004/02/septembre
   jjmmaaaaS_hhmmss := 'jj/mm/aaaa hh:mm:ss';     // 02/09/2004 13:37:43
   hhmm := 'hh:mm';                               // 01:27
   h_heures_mm_minutes_ss_secondes :=
     'h \h\eur\e\s mm \minut\e\s ss \s\econd\e\s';// 1 heures 27 minutes 43 secondes
   hh_heures_mm_minutes	:=
     'hh \h\eur\e\s mm \minut\e\s';               // 01 heures 27 minutes
   hhmmss := 'hh:mm:ss';                          // 01:27:43
   {Variables Fraction}
   UnSurUn := '#" "?/?';
   DeuxSurDeux := '#" "??/??';
   TroisSurTrois := '#" "???/???';
   UnSur2 := '#" "?/2';
   UnSur4 := '#" "?/4';
   UnSur8 := '#" "?/8';
   UnSur16 := '#" "??/16';
   UnSur10 := '#" "?/10';
   UnSur100 := '#" "??/100';
   {Variables Special}
   CodePostal := '00000';
   NumeroSecu := '[>=3000000000000]#" "##" "##" "##" "###" "###" | "##;#" "##" "##" "##" "###" "###';
   NumeroTel := '0#" "##" "##" "##" "##';
   NumeroTelTiret := '0#"-"##"-"##"-"##"-"##';




end.

