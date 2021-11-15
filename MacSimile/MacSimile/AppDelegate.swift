//
//  AppDelegate.swift
//  MacSimile
//
//  Created by tychon on 25/10/2021.
//

import Cocoa
@main
class AppDelegate: NSObject, NSApplicationDelegate
{
    // Menu de la barre des statuts
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var synchroBout: NSMenuItem!
    @IBOutlet weak var changDestinBout: NSMenuItem!
    @IBOutlet weak var journalBout: NSMenuItem!
    @IBOutlet weak var quitterBout: NSMenuItem!
    
    let maison = FileManager.default.homeDirectoryForCurrentUser
    
    let statusItem = NSStatusBar.system.statusItem(withLength: -1)
    let iconeApp = NSImage(named: NSImage.Name("AppIcon"))
    let iconeBarre = NSImage(named: NSImage.Name("IconeBarre"))
    
    var repDeSauv = UserDefaults.standard.string(forKey: "repdesauv") ?? "vide"

    let newWindow = NSWindow(contentRect: .init(origin: .zero,size: .init(width: NSScreen.main!.frame.midX,height: NSScreen.main!.frame.midY)),styleMask: [.closable],backing: .buffered,defer: false)
    let newWindow2 = NSWindow(contentRect: .init(origin: .zero,size: .init(width: NSScreen.main!.frame.midX,height: NSScreen.main!.frame.midY)),styleMask: [.closable, .titled],backing: .buffered,defer: false)
    let Didot15 = NSFont(name: "Didot", size: 15)
    let Didot13 = NSFont(name: "Didot", size: 13)
    let vue : NSView = NSView()
    let textField = NSTextField()
    let bouton = NSButton()
    let vue2 : NSView = NSView(frame: NSRect())
    let textField2 = NSTextField()
    let textField3 = NSTextField()
    let textField4 = NSTextField()
    let bouton2 = NSButton()
    let bouton3 = NSButton()
    
    let imagePres1 = NSImage(named: NSImage.Name("MacSimilePres1-600"))
    let imagePres2 = NSImage(named: NSImage.Name("MacSimilePres2-600"))
    let imagePres3 = NSImage(named: NSImage.Name("MacSimilePres3-600"))
    let imagePres4 = NSImage(named: NSImage.Name("MacSimilePres4-600"))
    let imagePres5 = NSImage(named: NSImage.Name("MacSimilePres5-600"))
    let imagePres6 = NSImage(named: NSImage.Name("MacSimilePres6-600"))
    var repsTagCopie = [URL]()
    var repsTagTransfert = [URL]()
    var repsTagCopieCorrig = [URL]()
    var repsTagTransfertCorrig = [URL]()
    var fichiersRepTagTotal = [URL]()
    var FRTagCorrigTotal = [URL]()
    var FRTagVerifPres = [URL]()
    var resultagCorrig = [String]()
    var resourceValue: AnyObject?
    var journal : Array<String> = Array<String>()
    let nomnotif:NSNotification.Name = NSNotification.Name(rawValue: "MaNotification")
    var tailleLibreInt = Int()
    var tailledelaSauv = Array<Int>()

    
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        // UserDefaults.standard.removeObject(forKey: "repdesauv")
        statusItem.button?.image = iconeBarre
        statusItem.menu = statusMenu
        statusItem.button?.isEnabled = true
        NotificationCenter.default.post(name: nomnotif, object: nil)
    
        //SI LE RÉPERTOIRE DE SAUVEGARDE N'EST PAS CONNU
        if repDeSauv.contains("vide")
        {
            synchroBout.isHidden = true
            changDestinBout.isHidden = true
            journalBout.isHidden = true
            statusItem.button!.isEnabled = true
            presentation1()
        }
        else
        {
            print("Répertoire de destination: ",repDeSauv)
            Notifier(titre:"Votre répertoire de destination est: ", message:repDeSauv)
            
            //MISE EN PLACE DU RÉPERTOIRE DES JOURNAUX SI INEXISTANT
            var isDir : ObjCBool = true
            if FileManager.default.fileExists(atPath: maison.relativePath+"/Documents/MacSimile/Journal/", isDirectory:&isDir)
            {
                if isDir.boolValue
                {
                    let reponse = String("Volume de sauvegarde: \(repDeSauv).")
                    NSLog (reponse)
                }else
                {
                    let reponse = String("Erreur de vérification du répertoire de sauvegarde")
                    NSLog (reponse)
                    return
                }
            }else
            {
                do
                {
                    try FileManager.default.createDirectory(atPath: maison.relativePath+"/Documents/MacSimile/Journal/", withIntermediateDirectories: true, attributes: nil)
                }
                catch{NSLog(error.localizedDescription);journal.append(error.localizedDescription)}
            }
        }
    }
    
    @IBAction func Synchro(_ sender: Any)
    {
        Notifier(titre:"Analyse des fichiers à copier ou transférer", message: "Veuillez ne pas déconnecter le volume de destination avant la fin de l'opération.")
        repsTagCopie = []
        repsTagTransfert = []
        repsTagCopieCorrig = []
        repsTagTransfertCorrig = []
        FRTagCorrigTotal = []
        fichiersRepTagTotal = []
        FRTagVerifPres = []
        
        resultagCorrig = []
        journal = []
        tailleLibreInt = 0
        tailledelaSauv = []
    
        statusItem.button!.isEnabled = false
        let format = DateFormatter()
        format.timeZone = TimeZone(identifier:"systemTimeZone")
        format.dateFormat = "d MMM yyyy HHmmss Z"
        let moment = format.string(from: Date())
        let formattageNb = NumberFormatter()
        formattageNb.usesGroupingSeparator = true
        formattageNb.groupingSeparator = "."
        formattageNb.numberStyle = .decimal
        formattageNb.decimalSeparator = ","
        formattageNb.locale = Locale(identifier: "fr_FR")
        journal.append("MacSimile - sauvegarde du "+moment+"\n")

        var x = 0
        var y = 0
        
        // VERIFICATION DES VOLUMES MONTÉS ET CALCUL DE L'ESPACE LIBRE DU VOLUME DE SAUVEGARDE + COLLECTE DES AUTRES VOLUMES HORMIS LE VOLUMES SYSTÈME
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [.volumeNameKey, .volumeAvailableCapacityKey, .volumeTotalCapacityKey, .volumeUUIDStringKey, .volumeIsInternalKey], options: [.skipHiddenVolumes])
        print(volumes!)
        var autresVolumes : [String] = [String]()
        let voldeSauv = repDeSauv.components(separatedBy: "/")
        
        for item in volumes!
        {
            if item.path.contains(voldeSauv[2])
            {
                do
                {
                    let tailleLibrVStmp = try item.resourceValues(forKeys: [.volumeAvailableCapacityKey])
                    tailleLibreInt = tailleLibrVStmp.volumeAvailableCapacity ?? 0
                    let nbFormate = formattageNb.string(from: NSNumber(value:tailleLibreInt))
                    let reponse = String("L'espace libre du volume \(item.path) est de \(nbFormate!) octets.")
                    journal.append("L'espace libre du volume \(item.path) est de \(nbFormate!) octets.\n")
                    NSLog(reponse)
                }
                catch
                { NSLog(error.localizedDescription); journal.append(error.localizedDescription)}
                
            }else if !item.path.contains(voldeSauv[2])
            {
                if item.path.contains("/Volumes/")
                {autresVolumes.append(item.path)}
            }
        }
        print("listeDesVolumesAutres : ",autresVolumes)
        
        //  VERIFICATION DE LA PRÉSENCE DU RÉPERTOIRE DE SAUVEGARDE
        var isDir : ObjCBool = true
        if FileManager.default.fileExists(atPath: repDeSauv, isDirectory:&isDir)
        {
            if isDir.boolValue {print ("répertoire de sauvegarde présent: ",repDeSauv)}
            else
            {
                //print ("Erreur, fichier trouvé à la place du répertoire attendu.")
                statusItem.button!.isEnabled = true
                return
            }
        }else
        {
            print ("répertoire de sauvegarde indisponible: ",repDeSauv)
            alerte(titre: "Destination indisponible:\n\(repDeSauv)", texte: "Le répertoire de sauvegarde n'est pas accessible. Assurez-vous qu'il l'est avant de lancer la sauvegarde.")
            statusItem.button!.isEnabled = true
            return
        }
    
        // COLLECTE DES RÉPERTOIRES TAGUÉS DE L'UTILISATEUR - L'OPTION skipsHiddenFiles EVITE DE SCANNER LE RÉPERTOIRE ".Trash".
        let enumerator = FileManager.default.enumerator(at: maison, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles], errorHandler: nil)
        while let nsurl = enumerator?.nextObject() as? NSURL
        {
            do
            {
                try nsurl.getResourceValue(&resourceValue, forKey: URLResourceKey.isDirectoryKey)
                
                if let isDirectory = resourceValue as? Bool, isDirectory == true
                {
                    // RECHERCHE DE LA PASTILLE "MacSml Copie" et "MacSml Transfert" DANS LES METADATAS DES RÉPERTOIRES TAGUÉS DE L'UTILISATEUR  - SUPRESSION DES TAGS MACSIMILE DES SOUS-RÉPERTOIRES
                    do
                    {
                        let srcURL : URL = try URL(resolvingAliasFileAt: nsurl as URL)
                        let pastilleRep = try srcURL.resourceValues(forKeys: [.tagNamesKey])
                        let resultTag = pastilleRep.tagNames ?? []

                        while y < resultTag.count
                        {
                            metadata(pastille: resultTag, source: srcURL)
                            y += 1
                        }
                        
                        y = 0
                        while y < resultTag.count
                        {
                            metadata(pastille: resultTag, source: srcURL)
                            y += 1
                        }
                        y = 0

                        if resultTag.contains("MacSml Copie")
                        {
                            repsTagCopie.append(srcURL)
                        }
                        else if resultTag.contains("MacSml Transfert")
                        {
                            repsTagTransfert.append(srcURL)
                        }
                                            
                    }catch{continue}//print("rien à collecter:", error.localizedDescription)}
                }
            }catch let error as NSError
            {
                //print("ErreurNSURL : ", error.localizedDescription)
                journal.append(" \(nsurl.relativePath!): \(error.localizedDescription)")
                print (journal.description)
            }
        }
        //print (repsTagCopie, repsTagTransfert)
        
        // COLLECTE DES RÉPERTOIRES TAGUÉS DES AUTRES VOLUMES
        while x < autresVolumes.count
        {
            let volumeAutre = URL (fileURLWithPath: autresVolumes[x])
            
            // COLLECTE DES RÉPERTOIRES TAGUÉS  - L'OPTION skipsHiddenFiles EVITE DE SCANNER LE RÉPERTOIRE ".Trash".
            let enumerator = FileManager.default.enumerator(at: volumeAutre, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles,.skipsPackageDescendants], errorHandler: nil)
            while let nsurl = enumerator?.nextObject() as? NSURL
            {
                do
                {
                    try nsurl.getResourceValue(&resourceValue, forKey: URLResourceKey.isDirectoryKey)
           
                    if let isDirectory = resourceValue as? Bool, isDirectory == true
                    {
                        // RECHERCHE DE LA PASTILLE "MacSml Copie" et "MacSml Transfert" DANS LES METADATAS DES RÉPERTOIRES TAGUÉS DES AUTRES VOLUMES - SUPRESSION DES TAGS MACSIMILE DES SOUS-RÉPERTOIRES
                        do
                        {
                            let srcURL : URL = try URL(resolvingAliasFileAt: nsurl as URL)
                            let pastilleRep = try srcURL.resourceValues(forKeys: [.tagNamesKey])
                            let resultTag = pastilleRep.tagNames ?? []

                            while y < resultTag.count
                            {
                                metadata(pastille: resultTag, source: srcURL)
                                y += 1
                            }
                            y = 0
                            
                            while y < resultTag.count
                            {
                                metadata(pastille: resultTag, source: srcURL)
                                y += 1
                            }
                            y = 0

                            if resultTag.contains("MacSml Copie")
                            {
                                repsTagCopie.append(srcURL)
                            }
                            else if resultTag.contains("MacSml Transfert")
                            {
                                repsTagTransfert.append(srcURL)
                            }
                                                
                        }catch{continue}//print("rien à collecter:", error.localizedDescription)}
                    }
                }catch
                {NSLog(error.localizedDescription);journal.append(error.localizedDescription)}
            }
            x += 1
        }
        x = 0
        
        print ("Répertoires tagués pour la copie: ", repsTagCopie, repsTagCopie.count)
        print ("Répertoires tagués pour le transfert: ", repsTagTransfert, repsTagTransfert.count)
        
        // COLLECTE DE LA LISTE DES FICHIERS À COPIER OU A TRANSFERER
        // Collecte des fichiers à copier
        while x < repsTagCopie.count
        {
            let baseurl: URL = repsTagCopie[x]
            FileManager.default.enumerator(atPath: baseurl.relativePath )?.forEach(
            {
                (e) in guard let s = e as? String else { return }
                let relativeURL = URL(fileURLWithPath: s, relativeTo: baseurl)
                let srcURL = relativeURL.absoluteURL
                do
                {
                    let resourceValues = try srcURL.resourceValues(forKeys: [.isAliasFileKey])
                    let nomResource = resourceValues.isAliasFile
                    if srcURL.hasDirectoryPath == false && nomResource! == false
                    {
                        if !relativeURL.relativePath.contains(".DS_Store") && !relativeURL.relativePath.contains(".app")
                        {
                            fichiersRepTagTotal.append(srcURL)
                        }
                    }
                }catch
                {
                    NSLog(error.localizedDescription)
                    journal.append("Erreur de vérification de l'alias: \(srcURL) \(error.localizedDescription)")
                }
                
                do
                {
                    let pastilleFichier = try srcURL.resourceValues(forKeys: [.tagNamesKey])
                    let resultTag = pastilleFichier.tagNames ?? []
                    
                    if resultTag.contains("MacSml Copie") && resultTag.contains("MacSml Transfert")
                    {
                        let tagfinal =  resultTag.filter { $0 != "MacSml Transfert" }
                        let tagfinal2 =  resultTag.filter { $0 != "MacSml Copie" }
                        try NSURL(fileURLWithPath: srcURL.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                        try NSURL(fileURLWithPath: srcURL.relativePath).setResourceValues([.tagNamesKey: tagfinal2])
                    }
                    
                    if resultTag.contains(String("MacSml Copie"))
                    {
                        let tagfinal = resultTag.filter { $0 != "MacSml Copie" }
                        try NSURL(fileURLWithPath: srcURL.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                    }
                    
                    else if resultTag.contains(String("MacSml Transfert"))
                    {
                        let tagfinal = resultTag.filter { $0 != "MacSml Transfert" }
                        try NSURL(fileURLWithPath: srcURL.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                    }
                }catch
                {NSLog(error.localizedDescription);journal.append(error.localizedDescription)}
            })
            x += 1
        }
        x = 0
        
        // Collecte des fichiers à tranférer
        while x < repsTagTransfert.count
        {
            let baseurl: URL = repsTagTransfert[x]
            FileManager.default.enumerator(atPath: baseurl.relativePath )?.forEach(
            {
                (e) in
                guard let s = e as? String else { return }
                let relativeURL = URL(fileURLWithPath: s, relativeTo: baseurl)
                let srcURL = relativeURL.absoluteURL
                
                if relativeURL.hasDirectoryPath == false
                {
                    if !relativeURL.relativePath.contains(".DS_Store") && !relativeURL.relativePath.contains(".app")
                    {
                        fichiersRepTagTotal.append(srcURL)
                    }
                }
                // Effacement des tags de MacSimile posés par erreur sur des fichiers
                do
                {
                    let pastilleFichier = try srcURL.resourceValues(forKeys: [.tagNamesKey])
                    let resultTag = pastilleFichier.tagNames ?? []
                    
                    if resultTag.contains("MacSml Copie") && resultTag.contains("MacSml Transfert")
                    {
                        let tagfinal =  resultTag.filter { $0 != "MacSml Transfert" }
                        let tagfinal2 =  resultTag.filter { $0 != "MacSml Copie" }
                        try NSURL(fileURLWithPath: srcURL.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                        try NSURL(fileURLWithPath: srcURL.relativePath).setResourceValues([.tagNamesKey: tagfinal2])
                    }
                    
                    if resultTag.contains(String("MacSml Copie"))
                    {
                        let tagfinal = resultTag.filter { $0 != "MacSml Copie" }
                        try NSURL(fileURLWithPath: srcURL.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                    }
                    
                    else if resultTag.contains(String("MacSml Transfert"))
                    {
                        let tagfinal = resultTag.filter { $0 != "MacSml Transfert" }
                        try NSURL(fileURLWithPath: srcURL.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                    }
                }catch
                {NSLog(error.localizedDescription);journal.append(error.localizedDescription)}
            })
            x += 1
        }
        x = 0
     
        var FRTagCorrigTotal = fichiersRepTagTotal.uniqued() // ENLÈVE LES DOUBLONS ÉVENTUELS
        //print("FICHIERS, corrigé: ", FRTagCorrigTotal.count, FRTagCorrigTotal)
        
        // VERIFICATION DE LA DESTINATION // REJET DES FICHIERS PRÉSENTS ET PAS PLUS RÉCENTS SUR LA DESTINATION
        var nbelemFich = FRTagCorrigTotal.count
        var destURL : URL = URL(fileURLWithPath: repDeSauv)
        while x < nbelemFich
        {
            let srcURL = FRTagCorrigTotal[x] as URL
            let srcUrlSepar = srcURL.relativePath.split(separator: "/")
            //print ("util",srcUrlSepar)
            if srcUrlSepar[0].contains("Volumes")
            {
                var comparse = srcURL.pathComponents
                comparse.remove(at: 1)
                comparse.remove(at: 1)
                comparse.remove(at: 0)
                destURL = URL(fileURLWithPath: repDeSauv+"/"+comparse.joined(separator: "/"))
           
                if (FileManager.default.fileExists(atPath: destURL.relativePath))
                {
                    let dateModSource = dateModif(atURL: srcURL)
                    let dateModDest = dateModif(atURL: destURL)
                    let delta = Int(dateModSource!.timeIntervalSince(dateModDest!))
                    //print ("différence de temps Autre:",delta)
                    if delta <= 1
                    {
                        // print ("Fichier existant et à jour Autre: ",srcURL.relativePath)
                        FRTagCorrigTotal.remove(at: x)
                        nbelemFich -= 1
                    }
                    else if delta > 1
                    {
                        // print ("Fichier à mettre à jour Autre: ",srcURL.relativePath)
                        x += 1
                    }
                }
                else if !(FileManager.default.fileExists(atPath: destURL.relativePath))
                {
                    // print ("Nouveau fichier à sauvegarder Autre: ",srcURL.relativePath)
                    x += 1
                }
            }
            else if !srcUrlSepar[0].contains("Volumes")
            {
                var comparse = srcURL.pathComponents
                comparse.remove(at: 1)
                comparse.remove(at: 1)
                comparse.remove(at: 0)
                destURL = URL(fileURLWithPath: repDeSauv+maison.relativePath+"/"+comparse.joined(separator: "/"))
                // print (destURL)
                if (FileManager.default.fileExists(atPath: destURL.relativePath))
                {
                    let dateModSource = dateModif(atURL: srcURL)
                    let dateModDest = dateModif(atURL: destURL)
                    let delta = Int(dateModSource!.timeIntervalSince(dateModDest!))
                    //print ("différence de temps Util:",delta)
                    if delta <= 1
                    {
                       //print ("Fichier existant et à jour Util: ",FRTagCorrigTotal[x],"\n")
                        FRTagCorrigTotal.remove(at: x)
                        nbelemFich -= 1
                    }
                    else if delta > 1
                    {
                        // print ("Nouveau fichier à sauvegarder Util: ",srcURL.relativePath)
                        x += 1
                    }
                }
                else if !(FileManager.default.fileExists(atPath: destURL.relativePath))
                {
                    //print ("Nouveau fichier à sauvegarder Util: ",srcURL.relativePath)
                    x += 1
                }
            }
        }
        nbelemFich = 0
        x = 0
        print ("Liste des fichiers à sauvergarder: ", FRTagCorrigTotal, FRTagCorrigTotal.count)
        
        // CALCUL DE LA TAILLE DES FICHIERS ET RÉPERTOIRES À COPIER - COMPARAISON AVEC L'ESPACE LIBRE
        if FRTagCorrigTotal.count == 0
        {
            alerte(titre: "Aucun fichier à copier sur la destination", texte: "Ils sont tous présents et à jour. ")
            Notifier(titre:"Aucun fichier à copier sur la destination", message: "Ils sont tous présents et à jour.")
            statusItem.button!.isEnabled = true
            return
        }
        else if FRTagCorrigTotal.count > 0
        {
            while x < FRTagCorrigTotal.count
            {
                do
                {
                    let srcURL = try URL(resolvingAliasFileAt: FRTagCorrigTotal[x] as URL)
                    // let srcString = FRTagCorrigTotal[x].relativePath
                    do {
                            let values = try srcURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                            if let capacity = values.totalFileAllocatedSize
                            {
                                //print("Taille du fichier: \(capacity)", srcString)
                                tailledelaSauv.append(capacity)
                            } else
                            {
                                journal.append("Taille Absente: \(srcURL.relativePath)\n")
                                FRTagCorrigTotal.remove(at: x)
                                // print("Taille absente: ", srcString)
                                //alerte(titre: "Volumes inaccessible", texte: "Impossible de récupérer la taille du fichier: \(srcString).")
                            }
                        } catch
                        {
                            NSLog(error.localizedDescription)
                            journal.append("Taille Absente: \(srcURL.relativePath)\n")
                            FRTagCorrigTotal.remove(at: x)
                        }
                }catch
                {
                    NSLog(error.localizedDescription);journal.append(error.localizedDescription)
                }
                x += 1
            }
            x = 0
            
            print("copie totale: ",FRTagCorrigTotal.count)
            
            // formattageNb.locale = Locale.current
            
            let sommeSauv = Int(tailledelaSauv.reduce(0, +)) // somme des différentes tailles en octet
            let tailleManquante = Int(sommeSauv) - Int(tailleLibreInt) // calcul de la différence entre espace libre et taille totale de la sauvegarde.
            var changeEchelle = Int(tailleManquante) / Int(1024) // taille en Koctet
            if changeEchelle == 0{changeEchelle += 1}
            var changeEchelleSrc = Int(sommeSauv) / Int(1024)
  
            if changeEchelleSrc == 0{changeEchelleSrc += 1}
            
            let nbFormate = formattageNb.string(from: NSNumber(value:changeEchelle))
            let nbFormate2 = formattageNb.string(from: NSNumber(value:changeEchelleSrc))
            
            var changeEchelleDest = Int(tailleLibreInt) / Int(1024)
            if changeEchelleDest == 0{changeEchelleDest += 1}
            
            tailleLibreInt = Int(tailleLibreInt) / Int(100) * Int(95)

            // SI PAS ASSEZ D'ESPACE SUR LA DESTINATION
            if tailleLibreInt <= sommeSauv
            {
                // print("La taille de la sauvegarde excède l'espace disponible sur le disque de sauvegarde.")
                alerte(titre: "Espace manquant sur le volume de sauvegarde.", texte: "il manque \(nbFormate!) Koctet(s).")
                return
            }
            // print ("Taille totale à sauver: ", sommeSauv,"octet(s)")
            // print ("Taille totale à sauver: ", nbFormate2!,"Koctet(s)")
            // print ("Espace disponible: ", tailleLibreInt,"octet(s)")
 
            // COPIE DES FICHIERS
            Notifier(titre:"UNE SAUVEGARDE EST EN COURS!", message: "Veuillez ne pas déconnecter le volume de destination avant la fin de l'opération.")
            Notifier(titre:"Il y a \(FRTagCorrigTotal.count) fichier(s) à sauver", message: "Taille totale: \(nbFormate2!) Koctet(s).")
            journal.append("Sauvegarde de \(FRTagCorrigTotal.count) fichier(s). Taille totale de la sauvegarde: \(nbFormate2!) Koctet(s)\n")
            var elementsInt = FRTagCorrigTotal.count
            
            while x < FRTagCorrigTotal.count
            {
                var destURL : URL = URL(fileURLWithPath: "repDeSauv")
                let srcURL : URL = FRTagCorrigTotal[x]
                let srcurlEstVolume = srcURL.pathComponents.split(separator: "/")
                
                if elementsInt == 100
                {
                    Notifier(titre:"La sauvegarde bat son plein", message: "Il ne reste plus que \(elementsInt) fichier(s) à sauver")
                }
                if elementsInt == 10
                {
                    Notifier(titre:"La sauvegarde arrive à son terme", message: "Il ne reste plus que \(elementsInt) fichier(s) à sauver")
                }
                if srcurlEstVolume[0].contains("Volumes")
                {
                    var comparse = srcURL.pathComponents
                    comparse.remove(at: 1)
                    comparse.remove(at: 1)
                    comparse.remove(at: 0)
                    destURL = URL(fileURLWithPath: repDeSauv+"/"+comparse.joined(separator: "/"))
                }
                else if !srcurlEstVolume[0].contains("Volumes")
                {
                    var comparse = srcURL.pathComponents
                    comparse.remove(at: 1)
                    comparse.remove(at: 1)
                    comparse.remove(at: 0)
                    destURL = URL(fileURLWithPath: repDeSauv+maison.relativePath+"/"+comparse.joined(separator: "/"))
                }
                
                if FileManager.default.fileExists(atPath: destURL.relativePath)
                {
                    do{
                        try FileManager.default.removeItem(at: destURL)
                        try FileManager.default.copyItem(at: srcURL, to: destURL)
                        // print ("copie d'un fichier PLUS RÉCENT effectuée: ", srcURL,destURL, x)
                        let source = String(srcURL.relativePath)
                        let destination = String(destURL.relativePath)
                        journal.append("copie d'un fichier PLUS RÉCENT")
                        journal.append("------------------------------")
                        journal.append("chemin de la source: \(source)")
                        journal.append("chemin de la destination: \(destination)\n")
                    }
                    catch
                    {NSLog(error.localizedDescription);journal.append(error.localizedDescription)}
                }

                else if !FileManager.default.fileExists(atPath: destURL.relativePath)
                {
                    let repCompo = destURL.deletingLastPathComponent()
                    do{
                        try FileManager.default.createDirectory(atPath: repCompo.relativePath, withIntermediateDirectories: true, attributes: nil)
                        try FileManager.default.copyItem(at: srcURL, to: destURL)
                        // print ("copie d'un nouveau fichier effectuée: ", srcURL, destURL, x)
                        let source = String(srcURL.relativePath)
                        let destination = String(destURL.relativePath)
                        journal.append("copie d'un NOUVEAU fichier")
                        journal.append("--------------------------")
                        journal.append("chemin de la source: \(source)")
                        journal.append("chemin de la destination: \(destination)\n")
                    }
                    catch
                    {NSLog(error.localizedDescription);journal.append(error.localizedDescription)}
                }
            x += 1
            elementsInt -= 1
            }
            x = 0

            // EFFACEMENT DU CONTENU DES RÉPERTOIRES À TRANSFERER
            //print ("Reps à effacer (contenu): ",repsTagTransfert)
            if repsTagTransfert.count > 0
            {
               let result = alerte2(titre: "Suppression du contenu des répertoires à transférer!", texte: "Pour annuler cette opération, cliquez sur 'Annuler'.")
                if (result == NSApplication.ModalResponse.alertFirstButtonReturn.rawValue)
                {
                    while x < repsTagTransfert.count
                    {
                        let enumerator5 = FileManager.default.enumerator(at: repsTagTransfert[x] as URL, includingPropertiesForKeys: [URLResourceKey.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants], errorHandler: nil)
                        while let nsurl5 = enumerator5?.nextObject() as? URL
                        {
                            do
                            {
                                // print("Effacé: ",nsurl5)
                                try FileManager.default.removeItem(at: nsurl5)
                            }
                            catch{NSLog(error.localizedDescription);journal.append(error.localizedDescription)}
                        }
                        x += 1
                    }
                    x = 0
                }else if ( result == NSApplication.ModalResponse.alertSecondButtonReturn.rawValue)
                {
                }
            }
    
            // JOURNAL
            journal.append("\n"+"--------------------FIN DE LA SAUVEGARDE--------------------")
            let joinedStrings = journal.joined(separator: "\n")
            let format2 = DateFormatter()
            format2.timeZone = TimeZone(identifier:"systemTimeZone")
            format2.dateFormat = "d MMM yyyy HHmmss Z"
            let moment2 = format2.string(from: Date())
            do
            {
               try joinedStrings.write(toFile: maison.relativePath+"/Documents/MacSimile/Journal/Journal-MacSimile-"+moment2+".txt", atomically: true, encoding: .utf8)
            }
            catch let error {NSLog(error.localizedDescription);journal.append(error.localizedDescription)}
            statusItem.button!.isEnabled = true
            alerte(titre: "Youppie!", texte: "Les copies et transferts ont été effectués avec succès. Un nouveau journal est disponible.")
            Notifier(titre:"Opération terminée:", message: "Les copies et transferts ont été effectués avec succès.")
        }
    }

    
    // _______________________________________________________________________FIN DE LA SYNCHRO___________________________________________________________________________
    
    
    @objc func Retour()
    {
        bouton2.removeFromSuperview()
        bouton3.removeFromSuperview()
        textField2.removeFromSuperview()
        textField3.removeFromSuperview()
        textField4.removeFromSuperview()
        vue2.removeFromSuperview()
        vue2.wantsLayer = false
        newWindow2.orderOut(self)
        newWindow2.styleMask.remove(NSWindow.StyleMask.fullSizeContentView)
        //newWindow2.contentView!.removeFromSuperview()
        //newWindow2.close()
        statusItem.button!.isEnabled = true
        return()
    }
    
    @IBAction func Journal(_ sender: Any)
    {
        let chemin =  maison.relativePath+"/Documents/MacSimile/Journal/"
        let dialogue = NSOpenPanel()
        dialogue.message = "Choisissez le fichier de destination..."
        dialogue.prompt = "Choisir"
        dialogue.canChooseFiles = true
        dialogue.showsResizeIndicator = true
        dialogue.showsHiddenFiles = false
        dialogue.canChooseDirectories = false
        dialogue.canCreateDirectories = true
        dialogue.allowsMultipleSelection = false
        dialogue.directoryURL? = URL(fileURLWithPath: chemin)
        
        if (dialogue.runModal() == NSApplication.ModalResponse.OK)
        {
            let result = dialogue.url// chemin du répertoire à traiter
            // print (result!)
            dialogue.setIsMiniaturized(true)
            dialogue.setIsVisible(false)
            dialogue.close()
            NSWorkspace.shared.open(result!)
        }
    }
    
    @IBAction func Quitter(_ sender: Any)
    {
        exit(0)
    }
    
    @IBAction func ChangeDestin(_ sender: Any)
    {
        let dialogue = NSOpenPanel()
        dialogue.message                 = "Choisissez le répertoire de destination..."
        dialogue.prompt                  = "Choisir"
        dialogue.canChooseFiles          = false
        dialogue.showsResizeIndicator    = true
        dialogue.showsHiddenFiles        = false
        dialogue.canChooseDirectories    = true
        dialogue.canCreateDirectories    = true
        dialogue.allowsMultipleSelection = false
        let chemin =  "/Volumes/"
        dialogue.directoryURL? = URL(fileURLWithPath: chemin)
        
        if (dialogue.runModal() == NSApplication.ModalResponse.OK)
        {
            let result = dialogue.url?.relativePath// chemin du répertoire à traiter
            // print (result!)
            let resultString = result?.split(separator: "/")
            
            dialogue.setIsMiniaturized(true)
            dialogue.setIsVisible(false)
            dialogue.close()
            
            if (resultString![0].contains("Volumes"))
            {
                // print (resultString![0])
                UserDefaults.standard.setValue(result!, forKey: "repdesauv")
                repDeSauv = UserDefaults.standard.string(forKey: "repdesauv")!
                Notifier(titre:"Le changement de répertoire a été effectué:", message: repDeSauv)
            }
            else
            {
                alerte(titre: "Erreur", texte: "Il n'est pas possible de choisir le disque système comme disque de sauvegarde, veuillez en choisir un autre...")
            }
        }else
        {
            Notifier(titre:"Le répertoire de sauvegarde demeure le même: ", message: repDeSauv)
        }
    }

    @objc func presentation1()
    {
        self.vue.wantsLayer = true
        textField.isBezeled = false
        textField.font = Didot15
        textField.alignment = .center
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.stringValue = ""
        textField.textColor = NSColor(cgColor: .white)
        textField.frame = NSRect(x: 620, y: 300, width: 260, height: 100)
        self.newWindow.contentView!.addSubview(textField)
        bouton.title = "Continuer"
        bouton.isBordered = false
        bouton.bezelStyle = .texturedSquare
        bouton.wantsLayer = true
        bouton.layer?.backgroundColor = NSColor.systemBlue.cgColor
        bouton.target = self
        bouton.action = #selector(presentation2)
        bouton.frame = NSRect(x: 720, y: 280, width: 80, height: 20)
        vue.setFrameSize(NSSize(width: 600, height: 600))
        vue.setFrameOrigin(NSPoint(x: 0, y: 0))
        vue.layer!.contents = imagePres1
        self.newWindow.contentView!.addSubview(vue)
        self.newWindow.contentView!.addSubview(bouton)
        newWindow.title = "MacSimile"
        newWindow.isOpaque = false
        newWindow.setFrame(NSRect(x: 0, y: 0, width: 900, height: 600), display: false)
        newWindow.center()
        newWindow.isMovableByWindowBackground = true
        newWindow.backgroundColor = NSColor(calibratedHue: 0, saturation: 1.0, brightness: 0, alpha: 1.0)
        newWindow.accessibilityCloseButton()
        newWindow.styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
        // newWindow.titleVisibility = .visible
        // newWindow.titlebarAppearsTransparent = false
        newWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc func presentation2()
    {
        textField.stringValue = "Veuillez sélectionner le répertoire (ou le disque) de sauvegarde..."
        bouton.title = "Choisir"
        bouton.action = #selector(presentation3)
        vue.layer!.contents = imagePres2
        self.newWindow.contentView!.addSubview(vue)
        self.newWindow.contentView!.addSubview(bouton)
        newWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc func presentation3()
    {
        let dialogue = NSOpenPanel()
        dialogue.message                 = "Choisissez le répertoire de destination..."
        dialogue.prompt                  = "Choisir"
        dialogue.canChooseFiles          = false
        dialogue.showsResizeIndicator    = true
        dialogue.showsHiddenFiles        = false
        dialogue.canChooseDirectories    = true
        dialogue.canCreateDirectories    = true
        dialogue.allowsMultipleSelection = false
        
        if (dialogue.runModal() == NSApplication.ModalResponse.OK)
        {
            let result = dialogue.url?.relativePath// chemin du répertoire à traiter
            // print ("Répertoire de sauvegarde choisi: ",result!)
            let resultString = result?.split(separator: "/")
            dialogue.setIsMiniaturized(true)
            dialogue.setIsVisible(false)
            dialogue.close()
            
            if (resultString![0].contains("Volumes"))
            {
                UserDefaults.standard.setValue(result!, forKey: "repdesauv")
                repDeSauv = UserDefaults.standard.string(forKey: "repdesauv")!
                textField.stringValue = "Répertoire de sauvegarde actuel:\n "+repDeSauv
                bouton.title = "Continuer"
                bouton.action = #selector(presentation4)
                vue.layer!.contents = imagePres3
                self.newWindow.contentView!.addSubview(vue)
                self.newWindow.contentView!.addSubview(bouton)
                newWindow.makeKeyAndOrderFront(nil)
            }
            else
            {
                alerte(titre: "Erreur", texte: "Il n'est pas possible de choisir le disque système comme disque de sauvegarde, veuillez en choisir un autre...")
            }
        }
    }
    
    @objc func presentation4()
    {
        textField.stringValue = ""
        bouton.title = "Continuer"
        bouton.action = #selector(presentation5)
        vue.layer!.contents = imagePres4
        self.newWindow.contentView!.addSubview(vue)
        self.newWindow.contentView!.addSubview(bouton)
        newWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc func presentation5()
    {
        textField.stringValue = ""
        bouton.title = "Continuer"
        bouton.action = #selector(presentation6)
        vue.layer!.contents = imagePres5
        self.newWindow.contentView!.addSubview(vue)
        self.newWindow.contentView!.addSubview(bouton)
        newWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc func presentation6()
    {
        textField.stringValue = "Pour plus d'information:\n"
        bouton.title = "Terminer"
        bouton.action = #selector(presentationFIN)
        vue.layer!.contents = imagePres6
        self.newWindow.contentView!.addSubview(vue)
        self.newWindow.contentView!.addSubview(bouton)
        newWindow.makeKeyAndOrderFront(nil)
    }

    @objc func presentationFIN()
    {
        statusItem.button!.isEnabled = true
        synchroBout.isHidden = false
        changDestinBout.isHidden = false
        journalBout.isHidden = false
        newWindow.close()
    }
    
    func alerte(titre: String, texte: String)
    {
        let alert = NSAlert()
        let icon1 = NSImage(named: NSImage.Name("AppIcon"))
        alert.icon = icon1
        alert.messageText = titre
        alert.informativeText = texte
       // alert.alertStyle = .informational
        alert.addButton(withTitle: "Fermer")
        alert.window.title = "MacSimile"
        alert.runModal()
    }
    func alerte2(titre: String, texte: String) -> NSInteger
    {
        let alert2 = NSAlert()
        let icon1 = NSImage(named: NSImage.Name("AppIcon"))
        alert2.icon = icon1
        alert2.addButton(withTitle: "Continuer")
        alert2.addButton(withTitle: "Annuler")
        alert2.messageText = titre
        alert2.informativeText = texte
       // alert2.alertStyle = .informational
        alert2.window.title = "MacSimile"
        let result : NSInteger = alert2.runModal().rawValue
        return result
    }
    
    func Notifier(titre: String, message: String) -> Void
    {
        let notification = NSUserNotification()
        notification.title = titre
        notification.informativeText = message
        //notification.responsePlaceholder = "Placeholder"
        notification.deliveryDate = Date()
        NSUserNotificationCenter.default.deliver(notification)
        //notification.hasActionButton = true
        //notification.actionButtonTitle = "Agree"
        //notification.hasReplyButton = true
        //notification.contentImage = NSImage(named:"AppIcon")
        //notification.soundName = NSUserNotificationDefaultSoundName
    }
    func applicationWillTerminate(_ aNotification: Notification)
    {
        // Insert code here to tear down your application
    }
}

public extension Array where Element: Hashable
{
    func uniqued() -> [Element]
    {
        var seen = Set<Element>()
        return filter{ seen.insert($0).inserted}
    }
}

func dateModif(atURL url: URL) -> Date?
{
    if let attr = try? url.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey])
    {
        return attr.contentModificationDate
    }
    return nil
}

func metadata(pastille String: [String], source URL2: URL)
{
    do
    {
        if String.contains("MacSml Copie") && String.contains("MacSml Transfert")
        {
            let tagfinal =  String.filter { $0 != "MacSml Transfert" }
            try NSURL(fileURLWithPath: URL2.relativePath).setResourceValues([.tagNamesKey: tagfinal])
            
            let enumerator2 = FileManager.default.enumerator(at: URL2, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles], errorHandler: nil)
            while let nsurl2 = enumerator2?.nextObject() as? NSURL
            {
                let srcURL2 : URL = try URL(resolvingAliasFileAt: nsurl2 as URL)
                let pastilleRep2 = try URL(resolvingAliasFileAt: nsurl2 as URL).resourceValues(forKeys: [.tagNamesKey])
                let resultTag2 = pastilleRep2.tagNames ?? []
                if resultTag2.contains("MacSml Copie") && resultTag2.contains("MacSml Transfert")
                {
                    let tagfinal =  resultTag2.filter { $0 != "MacSml Transfert" }
                    let tagfinal2 = tagfinal.filter {$0 != "MacSml Copie"}
                    try NSURL(fileURLWithPath: srcURL2.relativePath).setResourceValues([.tagNamesKey: tagfinal2])
                }
                    
                if resultTag2.contains("MacSml Copie")
                {
                    let tagfinal =  resultTag2.filter { $0 != "MacSml Copie" }
                    try NSURL(fileURLWithPath: srcURL2.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                }
                
                if resultTag2.contains("MacSml Transfert")
                {
                    let tagfinal =  resultTag2.filter { $0 != "MacSml Transfert" }
                    try NSURL(fileURLWithPath: srcURL2.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                }
            }
        }
            
        if String.contains("MacSml Copie") || String.contains("MacSml Transfert")
        {
            let enumerator2 = FileManager.default.enumerator(at: URL2, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles], errorHandler: nil)
            while let nsurl2 = enumerator2?.nextObject() as? NSURL
            {
                let srcURL2 : URL = try URL(resolvingAliasFileAt: nsurl2 as URL)
                let pastilleRep2 = try URL(resolvingAliasFileAt: nsurl2 as URL).resourceValues(forKeys: [.tagNamesKey])
                let resultTag2 = pastilleRep2.tagNames ?? []
                
                if resultTag2.contains("MacSml Copie") && resultTag2.contains("MacSml Transfert")
                {
                    let tagfinal =  resultTag2.filter { $0 != "MacSml Transfert" }
                    try NSURL(fileURLWithPath: srcURL2.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                }
                
                if resultTag2.contains("MacSml Copie")
                {
                    let tagfinal =  resultTag2.filter { $0 != "MacSml Copie" }
                    try NSURL(fileURLWithPath: srcURL2.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                }
                
                if resultTag2.contains("MacSml Transfert")
                {
                    let tagfinal =  resultTag2.filter { $0 != "MacSml Transfert" }
                    try NSURL(fileURLWithPath: srcURL2.relativePath).setResourceValues([.tagNamesKey: tagfinal])
                }
            }
        }
    }catch{NSLog(error.localizedDescription)}
}



