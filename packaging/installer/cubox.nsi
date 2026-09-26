; ============================================================================
;  Installeur Windows de Cubox — compilé sous Linux avec makensis.
;
;      makensis -DVERSION=1.3 packaging/installer/cubox.nsi
;
;  L'installeur NE CONTIENT PAS les fichiers du programme : il les COPIE depuis
;  son propre dossier. C'est un choix, pas un oubli.
;
;    - embarquer le JRE doublerait la taille du .zip (installeur ~60 Mo +
;      payload ~60 Mo) pour livrer deux fois les mêmes octets ;
;    - la compression NSIS d'un JRE déjà compressé n'apporte presque rien ;
;    - et cela garde la symétrie avec le paquet Linux, où install.sh copie lui
;      aussi les fichiers voisins.
;
;  Contrepartie assumée : l'utilisateur doit extraire TOUT le .zip avant de
;  lancer Installer.exe. Le double-clic depuis l'explorateur d'archives de
;  Windows échouerait — d'où le contrôle explicite en début de section, qui
;  affiche un message clair au lieu d'installer quelque chose de cassé.
;
;  Installation PAR UTILISATEUR (%LOCALAPPDATA%), donc aucune élévation UAC :
;  Cubox n'a besoin d'aucun privilège, et une install système imposerait une
;  demande d'administrateur à chaque mise à jour.
; ============================================================================

!ifndef VERSION
  !define VERSION "0.0"
!endif

!define NOM        "Cubox"
!define EDITEUR    "Cloudox"
!define SITE       "https://cubox.yabox.wasabout.net"
!define CLE_DESINST "Software\Microsoft\Windows\CurrentVersion\Uninstall\Cubox"

Unicode true
SetCompressor /SOLID lzma

Name          "${NOM} ${VERSION}"
OutFile       "Installer.exe"
InstallDir    "$LOCALAPPDATA\Programs\Cubox"
InstallDirRegKey HKCU "Software\Cubox" "InstallDir"
; user : pas de demande d'élévation. Écrire dans %LOCALAPPDATA% et HKCU ne
; nécessite aucun droit particulier.
RequestExecutionLevel user
ShowInstDetails show
ShowUninstDetails show

VIProductVersion "1.0.0.0"
VIAddVersionKey  "ProductName"     "${NOM}"
VIAddVersionKey  "CompanyName"     "${EDITEUR}"
VIAddVersionKey  "FileDescription" "Installeur de ${NOM}"
VIAddVersionKey  "FileVersion"     "${VERSION}"
VIAddVersionKey  "LegalCopyright"  "GPLv3"

!include "MUI2.nsh"
; ${GetSize} vient de FileFunc.nsh — sans cet include, makensis échoue sur un
; « command GetSize not found », message peu parlant.
!include "FileFunc.nsh"
!define MUI_ABORTWARNING
!define MUI_ICON   "cubox.ico"
!define MUI_UNICON "cubox.ico"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
  !define MUI_FINISHPAGE_RUN "$INSTDIR\Cubox.exe"
  !define MUI_FINISHPAGE_RUN_TEXT "Lancer Cubox maintenant"
  !define MUI_FINISHPAGE_LINK "Site de Cubox"
  !define MUI_FINISHPAGE_LINK_LOCATION "${SITE}"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "English"

; ----------------------------------------------------------------------------
Section "Cubox" SEC_PRINCIPAL
  SectionIn RO

  ; Sans ce contrôle, un lancement depuis l'explorateur d'archives installerait
  ; un dossier vide et l'utilisateur ne s'en rendrait compte qu'au premier
  ; démarrage, avec un message Windows incompréhensible.
  IfFileExists "$EXEDIR\Cubox.exe" fichiers_ok 0
    MessageBox MB_ICONSTOP \
      "Fichiers introuvables.$\r$\n$\r$\nExtrais d'abord l'archive ZIP EN ENTIER \
dans un dossier, puis lance Installer.exe depuis ce dossier.$\r$\n$\r$\n\
(Lancer l'installeur directement depuis l'archive ne peut pas fonctionner.)"
    Abort "archive non extraite"
  fichiers_ok:

  IfFileExists "$EXEDIR\jre-x64\bin\java.exe" jre_ok 0
    MessageBox MB_ICONSTOP \
      "Le dossier jre-x64 est absent ou incomplet.$\r$\n$\r$\n\
Réextrais l'archive ZIP en entier et relance Installer.exe."
    Abort "jre-x64 manquant"
  jre_ok:

  ; Une mise à jour par-dessus une ancienne version laisserait des
  ; bibliothèques orphelines du JRE précédent, que Java peut charger à la
  ; place des bonnes. On repart d'un dossier propre — les données de jeu sont
  ; ailleurs (%APPDATA%), elles ne sont pas concernées.
  DetailPrint "Nettoyage de l'installation précédente…"
  RMDir /r "$INSTDIR\jre-x64"
  Delete   "$INSTDIR\Cubox.exe"

  SetOutPath "$INSTDIR"
  DetailPrint "Copie des fichiers (cela peut prendre une minute)…"
  CopyFiles /SILENT "$EXEDIR\Cubox.exe" "$INSTDIR\Cubox.exe"
  CreateDirectory "$INSTDIR\jre-x64"
  CopyFiles /SILENT "$EXEDIR\jre-x64\*.*" "$INSTDIR\jre-x64"

  IfFileExists "$INSTDIR\jre-x64\bin\java.exe" copie_ok 0
    MessageBox MB_ICONSTOP "La copie du JRE a échoué. Vérifie l'espace disque disponible."
    Abort "copie incomplète"
  copie_ok:

  ; Raccourcis
  CreateDirectory "$SMPROGRAMS\Cubox"
  CreateShortCut  "$SMPROGRAMS\Cubox\Cubox.lnk"          "$INSTDIR\Cubox.exe" "" "$INSTDIR\Cubox.exe" 0
  CreateShortCut  "$SMPROGRAMS\Cubox\Désinstaller.lnk"   "$INSTDIR\Uninstall.exe"
  CreateShortCut  "$DESKTOP\Cubox.lnk"                   "$INSTDIR\Cubox.exe" "" "$INSTDIR\Cubox.exe" 0

  ; Entrée « Applications et fonctionnalités ». HKCU et non HKLM : l'install
  ; est par utilisateur, l'écrire dans HKLM demanderait des droits admin et
  ; afficherait l'entrée pour des comptes où Cubox n'existe pas.
  WriteRegStr HKCU "Software\Cubox" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "${CLE_DESINST}" "DisplayName"     "${NOM}"
  WriteRegStr HKCU "${CLE_DESINST}" "DisplayVersion"  "${VERSION}"
  WriteRegStr HKCU "${CLE_DESINST}" "Publisher"       "${EDITEUR}"
  WriteRegStr HKCU "${CLE_DESINST}" "URLInfoAbout"    "${SITE}"
  WriteRegStr HKCU "${CLE_DESINST}" "DisplayIcon"     "$INSTDIR\Cubox.exe"
  WriteRegStr HKCU "${CLE_DESINST}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${CLE_DESINST}" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegDWORD HKCU "${CLE_DESINST}" "NoModify" 1
  WriteRegDWORD HKCU "${CLE_DESINST}" "NoRepair" 1

  ; Taille réelle affichée dans « Applications et fonctionnalités ».
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "${CLE_DESINST}" "EstimatedSize" "$0"

  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

; ----------------------------------------------------------------------------
Section "Uninstall"
  ; On ne touche PAS à %APPDATA%\.minecraft ni aux données de jeu : une
  ; désinstallation qui efface les mondes sans prévenir est une perte de
  ; données, pas un nettoyage.
  RMDir /r "$INSTDIR\jre-x64"
  Delete   "$INSTDIR\Cubox.exe"
  Delete   "$INSTDIR\Uninstall.exe"
  RMDir    "$INSTDIR"

  Delete   "$SMPROGRAMS\Cubox\Cubox.lnk"
  Delete   "$SMPROGRAMS\Cubox\Désinstaller.lnk"
  RMDir    "$SMPROGRAMS\Cubox"
  Delete   "$DESKTOP\Cubox.lnk"

  DeleteRegKey HKCU "${CLE_DESINST}"
  DeleteRegKey HKCU "Software\Cubox"

  MessageBox MB_ICONINFORMATION \
    "Cubox a été désinstallé.$\r$\n$\r$\nTes mondes et ta configuration sont \
conservés dans %APPDATA% et dans le dossier de jeu."
SectionEnd
